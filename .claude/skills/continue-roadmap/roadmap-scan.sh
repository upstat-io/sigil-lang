#!/usr/bin/env bash
# roadmap-scan.sh — Fast roadmap status scanner with blocker awareness
# Scans plans/roadmap/section-*.md files sequentially.
# Outputs: per-section status line + detail block for first incomplete section.
# Detects frontmatter/body mismatches at both section and subsection level.
# Tracks blocker dependencies via <!-- blocked-by:X --> tags.
set -euo pipefail

ROADMAP_DIR="${1:-plans/roadmap}"
first_incomplete=""

# ── Helper: find section file by section number ──
find_section_file() {
    local sid="$1"
    if [[ "$sid" =~ ^[0-9]+$ ]]; then
        local padded
        padded=$(printf "%02d" "$sid")
        for candidate in "$ROADMAP_DIR"/section-${padded}-*.md "$ROADMAP_DIR"/section-${padded}.md; do
            if [[ -f "$candidate" ]]; then
                echo "$candidate"
                return
            fi
        done
    fi
    for candidate in "$ROADMAP_DIR"/section-${sid}-*.md "$ROADMAP_DIR"/section-${sid}.md; do
        if [[ -f "$candidate" ]]; then
            echo "$candidate"
            return
        fi
    done
}

# ── Pre-parse dependency graph from overview ──
declare -A dep_of=()
if [[ -f "$ROADMAP_DIR/00-overview.md" ]]; then
    while read -r child parent; do
        [[ -z "$child" ]] && continue
        dep_of["$child"]="$parent"
    done < <(awk '
        BEGIN { last_sec = ""; in_graph = 0; in_code = 0 }
        /^## Dependency Graph/ { in_graph = 1; next }
        in_graph && /^## / { exit }
        !in_graph { next }
        /^```/ { in_code = !in_code; next }
        !in_code { next }
        /^$/ { next }
        {
            line = $0
            is_cont = (line ~ /^[[:space:]]/)
            prev = ""
            if (is_cont && last_sec != "") prev = last_sec
            while (match(line, /Section [0-9]+/)) {
                sec = substr(line, RSTART + 8, RLENGTH - 8)
                if (prev != "" && sec != prev) {
                    printf "%s %s\n", sec, prev
                }
                prev = sec
                line = substr(line, RSTART + RLENGTH)
            }
            if (prev != "") last_sec = prev
        }
    ' "$ROADMAP_DIR/00-overview.md")
fi

for f in "$ROADMAP_DIR"/section-*.md; do
    # Extract top-level frontmatter fields (between first and second --- lines)
    status=$(awk '/^---$/{n++; next} n==1 && /^status:/{sub(/^status: */,""); print; exit}' "$f")
    title=$(awk '/^---$/{n++; next} n==1 && /^title:/{sub(/^title: */,""); print; exit}' "$f")
    section=$(awk '/^---$/{n++; next} n==1 && /^section:/{sub(/^section: */,""); print; exit}' "$f")

    # Count checkboxes in file body (after frontmatter)
    checked=$(grep -c '\- \[x\]' "$f" 2>/dev/null || true)
    unchecked=$(grep -c '\- \[ \]' "$f" 2>/dev/null || true)
    checked=${checked:-0}
    unchecked=${unchecked:-0}
    total=$((checked + unchecked))

    # Section-level frontmatter/body mismatch detection (both directions)
    mismatch=""
    if [[ "$status" == "complete" && "$unchecked" -gt 0 ]]; then
        mismatch=" !! MISMATCH: frontmatter=complete but ${unchecked} unchecked"
    elif [[ "$status" == "not-started" && "$checked" -gt 0 ]]; then
        mismatch=" !! MISMATCH: frontmatter=not-started but ${checked} checked"
    fi

    if [[ "$unchecked" -eq 0 ]]; then
        echo "[done] Section ${section}: ${title} (${checked}/${total})${mismatch}"
    else
        pct=0
        if [[ "$total" -gt 0 ]]; then
            pct=$((checked * 100 / total))
        fi
        echo "[open] Section ${section}: ${title} (${checked}/${total}, ${pct}%)${mismatch}"

        # Detail block for first incomplete section only
        if [[ -z "$first_incomplete" ]]; then
            first_incomplete="$f"
            echo ""
            echo "=== FOCUS: Section ${section} — ${title} ==="
            echo "File: $(basename "$f")"
            echo "Progress: ${checked}/${total} (${pct}%)"

            # ── Blocker extraction ──
            # Parse all - [ ] lines: line number, indent, effective blockers, content
            # Parent inheritance: indent-0 items set parent blocker,
            # indent>0 items inherit if no own blocker. Reset at ## boundaries.
            blocker_data=$(awk '
                BEGIN { n = 0; parent_bl = "" }
                /^---$/ { n++; next }
                n < 2 { next }
                /^##/ { parent_bl = ""; next }
                /\- \[ \]/ {
                    line = $0
                    indent = 0
                    while (substr(line, indent+1, 1) == " ") indent++
                    own = ""
                    rest = line
                    while (match(rest, /blocked-by:[0-9A-Za-z.]+/)) {
                        tag = substr(rest, RSTART + 11, RLENGTH - 11)
                        if (own != "") own = own ","
                        own = own tag
                        rest = substr(rest, RSTART + RLENGTH)
                    }
                    if (indent == 0) parent_bl = own
                    eff = own
                    if (indent > 0 && eff == "" && parent_bl != "") eff = parent_bl
                    if (eff == "") eff = "-"
                    printf "%d\t%d\t%s\t%s\n", NR, indent, eff, line
                }
            ' "$f")

            # Count blocked vs unblocked, collect blocker section IDs
            total_blocked=0
            total_unblocked=0
            declare -A blocker_item_counts=()
            while IFS=$'\t' read -r lineno indent blockers content; do
                [[ -z "$lineno" ]] && continue
                if [[ "$blockers" != "-" ]]; then
                    total_blocked=$((total_blocked + 1))
                    IFS=',' read -ra bids <<< "$blockers"
                    for bid in "${bids[@]}"; do
                        bsec="${bid%%.*}"
                        blocker_item_counts["$bsec"]=$(( ${blocker_item_counts["$bsec"]:-0} + 1 ))
                    done
                else
                    total_unblocked=$((total_unblocked + 1))
                fi
            done <<< "$blocker_data"

            num_blocker_sections="${#blocker_item_counts[@]}"
            if [[ "$total_blocked" -gt 0 ]]; then
                echo "Actionable: ${total_unblocked} unblocked, ${total_blocked} blocked (by ${num_blocker_sections} sections)"
            fi
            echo ""

            # ── Subsection statuses with blocked counts ──
            # Pre-compute blocked count per subsection (## header)
            declare -A sub_blocked_counts=()
            while IFS=$'\t' read -r sid sbc; do
                [[ -z "$sid" ]] && continue
                sub_blocked_counts["$sid"]="$sbc"
            done < <(awk '
                BEGIN { fm = 0; in_body = 0; cur_id = ""; blocked = 0; parent_bl = "" }
                /^---$/ { fm++; next }
                fm >= 2 { in_body = 1 }
                in_body && /^## / {
                    if (cur_id != "") printf "%s\t%d\n", cur_id, blocked
                    header = $0
                    sub(/^## /, "", header)
                    split(header, parts, " ")
                    cur_id = parts[1]
                    gsub(/:$/, "", cur_id)
                    blocked = 0
                    parent_bl = ""
                    next
                }
                in_body && /^### / { parent_bl = "" }
                cur_id != "" && /\- \[ \]/ {
                    line = $0
                    indent = 0
                    while (substr(line, indent+1, 1) == " ") indent++
                    has_own = (line ~ /blocked-by:/)
                    if (indent == 0) parent_bl = (has_own ? "y" : "")
                    if (has_own || (indent > 0 && parent_bl == "y")) blocked++
                }
                END { if (cur_id != "") printf "%s\t%d\n", cur_id, blocked }
            ' "$f")

            echo "Subsections:"
            while IFS=$'\t' read -r sub_id sub_title sub_status; do
                body_counts=$(awk -v sid="$sub_id" '
                    BEGIN { in_body = 0; in_section = 0; cx = 0; co = 0 }
                    /^---$/ { n++; next }
                    n >= 2 { in_body = 1 }
                    in_body && /^## / {
                        header = $0
                        if (header ~ "^## " sid "[ :]" || header ~ "^## " sid "$") {
                            in_section = 1
                            next
                        } else if (in_section) {
                            exit
                        }
                    }
                    in_section && /\- \[x\]/ { cx++ }
                    in_section && /\- \[ \]/ { co++ }
                    END { printf "%d %d", cx, co }
                ' "$f")
                sub_cx=${body_counts%% *}
                sub_co=${body_counts##* }
                sub_total=$((sub_cx + sub_co))

                sub_mismatch=""
                if [[ "$sub_status" == "complete" && "$sub_co" -gt 0 ]]; then
                    sub_mismatch=" !! frontmatter=complete but ${sub_co} unchecked"
                elif [[ "$sub_status" == "not-started" && "$sub_cx" -gt 0 ]]; then
                    sub_mismatch=" !! frontmatter=not-started but ${sub_cx} checked"
                elif [[ "$sub_total" -eq 0 ]]; then
                    sub_mismatch=" (no checkboxes found under ## header)"
                fi

                blocked_suffix=""
                bc="${sub_blocked_counts["$sub_id"]:-0}"
                if [[ "$bc" -gt 0 ]]; then
                    blocked_suffix=" [${bc} blocked]"
                fi

                echo "  ${sub_id} ${sub_title} — ${sub_status} (${sub_cx}/${sub_total})${blocked_suffix}${sub_mismatch}"
            done < <(awk '
                /^---$/ { n++; next }
                n == 1 && /^  - id:/ { id = $NF; gsub(/"/, "", id) }
                n == 1 && /^    title:/ { sub(/^    title: */, ""); t = $0 }
                n == 1 && /^    status:/ { sub(/^    status: */, ""); printf "%s\t%s\t%s\n", id, t, $0 }
            ' "$f")
            echo ""

            # ── First unblocked items ──
            if [[ "$total_unblocked" -gt 0 ]]; then
                echo "First unblocked items:"
                unblocked_lines=$(echo "$blocker_data" | awk -F'\t' '$3 == "-"' | head -5 || true)
                while IFS=$'\t' read -r lineno indent _blockers content; do
                    [[ -z "$lineno" ]] && continue
                    content="${content#"${content%%[![:space:]]*}"}"
                    echo "  L${lineno}: ${content}"
                done <<< "$unblocked_lines"
                echo ""
            fi

            # ── Blocker summary and chain ──
            if [[ "${#blocker_item_counts[@]}" -gt 0 ]]; then
                echo "Blocker summary:"
                for bsec in $(echo "${!blocker_item_counts[@]}" | tr ' ' '\n' | sort -n); do
                    bf=$(find_section_file "$bsec")
                    if [[ -n "$bf" && -f "$bf" ]]; then
                        bstatus=$(awk '/^---$/{n++; next} n==1 && /^status:/{sub(/^status: */,""); print; exit}' "$bf")
                        btitle=$(awk '/^---$/{n++; next} n==1 && /^title:/{sub(/^title: */,""); print; exit}' "$bf")
                        bchecked=$(grep -c '\- \[x\]' "$bf" 2>/dev/null || true)
                        bunchecked=$(grep -c '\- \[ \]' "$bf" 2>/dev/null || true)
                        btotal=$((${bchecked:-0} + ${bunchecked:-0}))
                        bpct=0
                        if [[ "$btotal" -gt 0 ]]; then
                            bpct=$((${bchecked:-0} * 100 / btotal))
                        fi
                        count="${blocker_item_counts[$bsec]}"
                        item_word="items"
                        [[ "$count" -eq 1 ]] && item_word="item"
                        echo "  Section ${bsec}: ${btitle} (${bstatus}, ${bpct}%) — blocks ${count} ${item_word}"
                    fi
                done
                echo ""

                echo "Blocker chain:"
                for bsec in $(echo "${!blocker_item_counts[@]}" | tr ' ' '\n' | sort -n); do
                    chain="$bsec"
                    current="$bsec"
                    depth=0
                    while [[ "$depth" -lt 5 ]]; do
                        dep="${dep_of[$current]:-}"
                        [[ -z "$dep" ]] && break
                        df=$(find_section_file "$dep")
                        if [[ -z "$df" || ! -f "$df" ]]; then
                            break
                        fi
                        dstatus=$(awk '/^---$/{n++; next} n==1 && /^status:/{sub(/^status: */,""); print; exit}' "$df")
                        chain="$chain <- ${dep} [${dstatus}]"
                        [[ "$dstatus" == "complete" ]] && break
                        current="$dep"
                        depth=$((depth + 1))
                    done
                    echo "  $chain"
                done
                echo ""
            fi
        fi
    fi
done

if [[ -z "$first_incomplete" ]]; then
    echo ""
    echo "ALL SECTIONS COMPLETE"
fi
