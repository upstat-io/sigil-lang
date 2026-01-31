# Sync Website Pages

Update the website pages with the latest data from the source files.

## Part 1: Roadmap Sync

Update the website roadmap page (`website/src/pages/roadmap.astro`) with the latest data from the compiler roadmap plan.

### Source Files (Priority Order)

**Primary source of truth for status:** `plans/roadmap/priority-and-tracking.md`

1. `plans/roadmap/priority-and-tracking.md` - **AUTHORITATIVE** for phase status, notes, and test results
2. `plans/roadmap/00-overview.md` - Phase overview, tiers, milestones, dependency graph
3. `plans/roadmap/phase-XX-*.md` - Individual phase files with detailed task checklists

### Step 1: Extract Phase Status from Tracking File

Read `priority-and-tracking.md` and parse each tier's status table. Tables have this format:

```
| Phase | Name | Status | Notes |
|-------|------|--------|-------|
| 1 | Type System Foundation | 🔶 Partial | Core complete; ... pending |
```

**For each row, extract:**
- Phase number (may include letters like "7A", "21A")
- Phase name
- Status emoji at the START of the Status column
- Notes text

**Status emoji mapping (match the EMOJI, not the text):**
| Emoji | Website Status |
|-------|----------------|
| ✅ | `"complete"` |
| 🔶 | `"partial"` |
| ⏳ | `"not-started"` |

**IMPORTANT:** A phase is ONLY `"complete"` if it has the ✅ emoji. Phrases like "Core complete" or "X tests pass" in the Notes do NOT mean the phase is complete—check the Status column emoji.

### Step 2: Update Phase Status in roadmap.astro

In `website/src/pages/roadmap.astro`, find the `const tiers: Tier[]` array (around line 128).

For each phase in each tier:
1. Find the matching phase by number
2. Update `status:` to match the tracking file
3. Update `note:` with the Notes text from tracking

**Example change:**
```typescript
// Before (wrong - showing complete when tracking says partial)
{
  num: 1,
  name: "Type System Foundation",
  status: "complete",  // ❌ Wrong
  ...
}

// After (correct - matches tracking file)
{
  num: 1,
  name: "Type System Foundation",
  status: "partial",  // ✅ Matches 🔶 in tracking
  note: "Core complete; 1.1A Duration/Size traits, 1.1B Never semantics pending",
  ...
}
```

### Step 3: Update Hero Stats

The hero section has hardcoded stats that MUST be recalculated:

```astro
<div class="stats">
  <div class="stat">
    <span class="stat-value">6</span>  <!-- UPDATE THIS -->
    <span class="stat-label">Completed</span>
  </div>
  <div class="stat">
    <span class="stat-value">9</span>  <!-- UPDATE THIS -->
    <span class="stat-label">In Progress</span>
  </div>
  <div class="stat">
    <span class="stat-value">14</span>  <!-- UPDATE THIS -->
    <span class="stat-label">Planned</span>
  </div>
</div>
```

**Count from the updated tiers array:**
- Completed = phases with `status: "complete"`
- In Progress = phases with `status: "partial"`
- Planned = phases with `status: "not-started"`

### Step 4: Update Tier Status

After updating phases, recalculate each tier's status:

```typescript
// In the tier object
status: "complete" | "partial" | "in-progress" | "planned" | "future"
```

**Logic:**
- `"complete"` - ALL phases in tier have `status: "complete"`
- `"partial"` or `"in-progress"` - At least one phase is `"partial"`
- `"planned"` - All phases are `"not-started"` but dependencies met
- `"future"` - All phases are `"not-started"` and blocked by earlier tiers

### Step 5: Update Task Bullet Points (if needed)

Each phase has `sections` with `tasks`. Review individual phase files (`phase-XX-*.md`) for detailed status:

```typescript
sections: [
  { name: "Section Name", tasks: [
    { name: "Task description", done: true },  // [x] in phase file
    { name: "Another task", done: false },     // [ ] in phase file
  ]},
]
```

### Step 6: Update Test Results Section

Find the "Test Results" section and update with counts from `priority-and-tracking.md`:

```astro
<div class="result-card">
  <span class="result-value">1286</span>  <!-- Rust unit tests -->
  ...
</div>
```

Look for the "Current Test Results" section in the tracking file.

### Status Mapping Reference

| Tracking Symbol | Website Status | Tier Status |
|-----------------|----------------|-------------|
| ✅ Complete | `"complete"` | counts toward tier complete |
| 🔶 Partial | `"partial"` | tier becomes partial/in-progress |
| ⏳ Not started | `"not-started"` | tier is planned or future |

### Validation Checklist

Before finishing, verify:
- [ ] Every phase status matches the emoji in tracking file
- [ ] Hero stats sum equals total phase count (29 phases)
- [ ] Tier statuses are recalculated based on phase updates
- [ ] Test result numbers match tracking file
- [ ] Notes are copied from tracking file for phases with notes

---

## Part 2: Changelog Sync

Update the changelog JSON file (`website/public/changelog.json`) with new commits since the last sync.

### Data File

The changelog data is stored as a static JSON file at `website/public/changelog.json`, loaded client-side with pagination. This keeps the page load fast even with hundreds of entries.

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

### Page Features

The changelog page (`website/src/pages/changelog.astro`) provides:
- **Pagination**: 30 entries per page with prev/next navigation
- **Filtering**: Filter by type (All, Features, Fixes, Docs, Refactor)
- **Stats**: Total count, features count, fixes count
- **Grouping**: Entries grouped by date within each page

---

## Report

Report what changed with specific details:

### Roadmap Changes
- **Status changes**: List each phase that changed status (e.g., "Phase 1: complete → partial")
- **Stats update**: Old vs new hero stats (e.g., "Completed: 6 → 2")
- **Tier changes**: Any tier status changes
- **Test results**: Updated test counts if changed
- **Task updates**: New tasks added or task done status changed

### Changelog Changes
- Number of new entries added
- Date range of new commits

### Example Report Format
```
## Roadmap Sync Complete

### Phase Status Changes
- Phase 1: complete → partial (pending: Duration/Size traits, Never semantics)
- Phase 3: complete → partial (pending: 3.7-3.18, operator LLVM)
- Phase 4: complete → partial (pending: tooling, extension methods)
- Phase 5: complete → partial (pending: .inner, associated functions)

### Hero Stats Updated
- Completed: 6 → 2 (Phase 2, Phase 6)
- In Progress: 9 → 13
- Planned: 14 → 14

### Test Results
- Rust unit tests: 1286 (unchanged)
- Ori spec tests: 920 (unchanged)

### Changelog
- Added 5 new entries (2026-01-30 to 2026-01-31)
```
