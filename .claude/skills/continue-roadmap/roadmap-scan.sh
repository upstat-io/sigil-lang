#!/usr/bin/env bash
# roadmap-scan.sh — Fast roadmap status scanner
# Scans plans/roadmap/section-*.md files sequentially.
# Outputs: per-section status line + detail block for first incomplete section.
# Detects frontmatter/body mismatches at both section and subsection level.
set -euo pipefail

ROADMAP_DIR="${1:-plans/roadmap}"
first_incomplete=""

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
            echo ""

            # Subsection statuses from frontmatter + per-subsection mismatch check
            # Collect frontmatter subsection info: id, title, status
            echo "Subsections:"
            awk '
                /^---$/ { n++; next }
                n == 1 && /^  - id:/ { id = $NF; gsub(/"/, "", id) }
                n == 1 && /^    title:/ { sub(/^    title: */, ""); t = $0 }
                n == 1 && /^    status:/ { sub(/^    status: */, ""); printf "%s\t%s\t%s\n", id, t, $0 }
            ' "$f" | while IFS=$'\t' read -r sub_id sub_title sub_status; do
                # Find the matching ## header in the body and count checkboxes under it
                # Match headers like "## 0.2 Source Structure" or "## 3.5 Derive Traits"
                body_counts=$(awk -v sid="$sub_id" '
                    BEGIN { in_body = 0; in_section = 0; cx = 0; co = 0 }
                    /^---$/ { n++; next }
                    n >= 2 { in_body = 1 }
                    in_body && /^## / {
                        # Check if this header matches our subsection id
                        header = $0
                        # Match "## X.Y " where X.Y is the subsection id
                        if (header ~ "^## " sid "[ :]" || header ~ "^## " sid "$") {
                            in_section = 1
                            next
                        } else if (in_section) {
                            # Hit next ## header, stop
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

                # Detect subsection-level mismatches
                sub_mismatch=""
                if [[ "$sub_status" == "complete" && "$sub_co" -gt 0 ]]; then
                    sub_mismatch=" !! frontmatter=complete but ${sub_co} unchecked"
                elif [[ "$sub_status" == "not-started" && "$sub_cx" -gt 0 ]]; then
                    sub_mismatch=" !! frontmatter=not-started but ${sub_cx} checked"
                elif [[ "$sub_total" -eq 0 ]]; then
                    sub_mismatch=" (no checkboxes found under ## header)"
                fi

                echo "  ${sub_id} ${sub_title} — ${sub_status} (${sub_cx}/${sub_total})${sub_mismatch}"
            done
            echo ""

            # First 5 unchecked items with actual file line numbers
            echo "First unchecked items:"
            unchecked_lines=$(grep -n '\- \[ \]' "$f" | head -5 || true)
            while IFS=: read -r lineno content; do
                [[ -z "$lineno" ]] && continue
                content="${content#"${content%%[![:space:]]*}"}"
                echo "  L${lineno}: ${content}"
            done <<< "$unchecked_lines"
            echo ""
        fi
    fi
done

if [[ -z "$first_incomplete" ]]; then
    echo ""
    echo "ALL SECTIONS COMPLETE"
fi
