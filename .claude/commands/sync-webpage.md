# Sync Website Pages

**FULL VERIFICATION**: This command performs a complete audit of the website against source files. It does NOT just add new items—it verifies and corrects EVERYTHING.

## Part 1: Roadmap Sync

Perform a **full audit** of `website/src/pages/roadmap.astro` against the phase files.

### Source of Truth

The phase files in `plans/roadmap/phase-XX-*.md` are the **ONLY** source of truth. The website must match them exactly.

---

## Phase 1: Extract Data Using External Agents

**IMPORTANT**: Use the Task tool with `subagent_type: "general-purpose"` to read and extract data from phase files. This prevents context overflow.

### 1.1 Spawn Agents to Process Phase Files

Launch **multiple agents in parallel** (in batches of 5-6) to extract data from phase files. Each agent should:

1. Read the assigned phase file
2. Extract and return a JSON object with this structure:

```json
{
  "num": "1",
  "name": "Type System Foundation",
  "done": 48,
  "total": 48,
  "status": "complete",
  "sections": [
    {
      "name": "Primitive Types",
      "tasks": [
        { "name": "int type", "done": true },
        { "name": "float type", "done": true }
      ]
    }
  ]
}
```

### 1.2 Agent Prompt Template

Use this prompt for each agent (replace FILE_PATH and PHASE_NUM):

```
Read the file FILE_PATH and extract roadmap data.

Count checkboxes:
- done = count of "- [x]" lines
- total = count of "- [x]" + "- [ ]" lines

Derive status:
- done == total → "complete"
- done == 0 → "not-started"
- Otherwise → "partial"

Extract the phase name from the first line (after "# Phase X: ").

Parse sections (## X.Y Section Name headers) and their tasks:
- Top-level "- [x]" or "- [ ]" items are tasks
- Extract task name from the bold text after checkbox (e.g., "**Implement**: X" → "X")
- A task is done: true only if its checkbox AND all nested sub-checkboxes are [x]
- IGNORE "Phase Completion Checklist" sections

Return ONLY a JSON object (no markdown, no explanation):
{"num": "PHASE_NUM", "name": "...", "done": N, "total": N, "status": "...", "sections": [...]}
```

### 1.3 Phase File List

Process these files in parallel batches:

**Batch 1:**
- plans/roadmap/phase-01-type-system.md (num: "1")
- plans/roadmap/phase-02-type-inference.md (num: "2")
- plans/roadmap/phase-03-traits.md (num: "3")
- plans/roadmap/phase-04-modules.md (num: "4")
- plans/roadmap/phase-05-type-declarations.md (num: "5")
- plans/roadmap/phase-06-capabilities.md (num: "6")

**Batch 2:**
- plans/roadmap/phase-07A-core-builtins.md (num: "7A")
- plans/roadmap/phase-07B-option-result.md (num: "7B")
- plans/roadmap/phase-07C-collections.md (num: "7C")
- plans/roadmap/phase-07D-stdlib-modules.md (num: "7D")
- plans/roadmap/phase-08-patterns.md (num: "8")
- plans/roadmap/phase-09-match.md (num: "9")

**Batch 3:**
- plans/roadmap/phase-10-control-flow.md (num: "10")
- plans/roadmap/phase-11-ffi.md (num: "11")
- plans/roadmap/phase-12-variadic-functions.md (num: "12")
- plans/roadmap/phase-13-conditional-compilation.md (num: "13")
- plans/roadmap/phase-14-testing.md (num: "14")
- plans/roadmap/phase-15A-attributes-comments.md (num: "15A")

**Batch 4:**
- plans/roadmap/phase-15B-function-syntax.md (num: "15B")
- plans/roadmap/phase-15C-literals-operators.md (num: "15C")
- plans/roadmap/phase-15D-bindings-types.md (num: "15D")
- plans/roadmap/phase-16-async.md (num: "16")
- plans/roadmap/phase-17-concurrency.md (num: "17")
- plans/roadmap/phase-18-const-generics.md (num: "18")

**Batch 5:**
- plans/roadmap/phase-19-existential-types.md (num: "19")
- plans/roadmap/phase-20-reflection.md (num: "20")
- plans/roadmap/phase-21A-llvm.md (num: "21A")
- plans/roadmap/phase-21B-aot.md (num: "21B")
- plans/roadmap/phase-22-tooling.md (num: "22")

### 1.4 Aggregate Results

After all agents complete, collect their JSON outputs and build:
- `completedCount` = phases where `status == "complete"`
- `partialCount` = phases where `status == "partial"`
- `notStartedCount` = phases where `status == "not-started"`

Verify: `completedCount + partialCount + notStartedCount == 29`

---

## Phase 2: Audit and Correct the Website

Now read `website/src/pages/roadmap.astro` and **compare every field** against the extracted data.

### 2.1 Audit Each Phase

For EVERY phase in the website's `tiers` array:

| Field | Check | Fix if wrong |
|-------|-------|--------------|
| `num` | Matches phase number | Update |
| `name` | Matches phase title | Update |
| `status` | Matches derived status from checkboxes | **UPDATE** |
| `sections` | Contains ALL sections from phase file | **ADD missing, REMOVE extras** |
| `sections[].tasks` | Contains ALL tasks with correct `done` values | **ADD/REMOVE/UPDATE** |

**CRITICAL**: Don't just check if values exist—verify they are CORRECT. A phase showing `status: "partial"` when all checkboxes are done is WRONG and must be fixed to `"complete"`.

### 2.2 Audit Hero Stats

Find the hero stats section:
```astro
<span class="stat-value">X</span>
<span class="stat-label">Completed</span>
```

**Compare against your calculated counts. Fix if different.**

### 2.3 Audit Tier Status

For each tier, recalculate status based on its phases:
- ALL phases complete → tier `"complete"`
- ANY phase partial → tier `"partial"` or `"in-progress"`
- ALL phases not-started (blocked) → tier `"future"`
- ALL phases not-started (unblocked) → tier `"planned"`

### 2.4 Audit Sections and Tasks

For EACH phase, compare website sections against phase file:

**Check for:**
1. **Missing sections** - Section in phase file but not on website → ADD IT
2. **Extra sections** - Section on website but not in phase file → REMOVE IT
3. **Wrong section names** - Name doesn't match → FIX IT
4. **Missing tasks** - Task in phase file but not on website → ADD IT
5. **Extra tasks** - Task on website but not in phase file → REMOVE IT
6. **Wrong task status** - `done` value doesn't match checkbox → FIX IT

---

## Phase 3: Report All Discrepancies

List EVERY discrepancy found and fixed:

```
## Roadmap Audit Report

### Discrepancies Found and Fixed

**Phase 1: Type System Foundation**
- Status: partial → complete (was wrong, 48/48 checkboxes done)
- Added section: "Duration and Size Types" (was missing)
- Added section: "Never Type Semantics" (was missing)
- Task "Ordering type" done: false → true

**Phase 3: Traits**
- Status: complete → partial (was wrong, 87/92 checkboxes done)
- Removed task: "Old deprecated task" (not in phase file)

**Hero Stats**
- Completed: 6 → 8
- In Progress: 9 → 7
- Planned: 14 → 14

**Tier 1**
- Status: partial → complete (all phases now complete)
```

---

## Part 2: Changelog Sync

Update the changelog JSON file (`website/public/changelog.json`) with new commits since the last sync.

### Process

1. Read `website/public/changelog.json` to find the most recent commit hash
2. Run `git log --pretty=format:"%h|%ad|%s" --date=short <hash>..HEAD` to get only NEW commits since the last sync
   - If changelog is empty or hash not found, use `git log --pretty=format:"%h|%ad|%s" --date=short -50` to get the 50 most recent commits
3. Filter out:
   - Merge commits (starts with "Merge")
   - WIP commits
   - Fixup/squash commits
   - Empty or trivial messages
4. Parse conventional commit format when present (type(scope): message)
5. Clean messages:
   - Remove conventional commit prefix (feat:, fix:, etc.)
   - Remove issue references like (#123)
   - Capitalize first letter
   - Remove trailing periods for consistency
6. Prepend new entries to the existing changelog and write to `website/public/changelog.json`

### Commit Type Detection

**Conventional commits** (explicit prefix):
- `feat:` or `feat(scope):` → "feat"
- `fix:` or `fix(scope):` → "fix"
- `docs:` or `docs(scope):` → "docs"
- `refactor:` or `refactor(scope):` → "refactor"
- `chore:` or `chore(scope):` → "chore"

**Non-conventional** (infer from message):
- Contains "add", "implement", "support", "introduce", "create" → "feat"
- Contains "fix", "resolve", "correct", "repair" → "fix"
- Contains "refactor", "improve", "enhance", "update", "clean", "simplify" → "refactor"
- Contains "doc", "readme", "comment", "documentation" → "docs"
- Default → "chore"

### JSON Format

```json
[
  {"date": "2026-01-30", "type": "feat", "message": "Add feature X", "hash": "abc1234"},
  {"date": "2026-01-30", "type": "fix", "message": "Fix bug Y", "hash": "def5678"}
]
```

---

## Execution Order

1. **Spawn agents to extract phase data** - Process in parallel batches
2. **Aggregate agent results** - Collect all JSON outputs
3. **Read website file** - Get current state
4. **Compare field by field** - Find ALL discrepancies
5. **Fix ALL discrepancies** - Update website to match phase files exactly
6. **Report what changed** - List every fix made

**DO NOT** just spot-check a few phases. **DO NOT** assume the website is mostly correct. Verify EVERYTHING.
