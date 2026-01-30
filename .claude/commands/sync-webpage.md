# Sync Website Pages

Update the website pages with the latest data from the source files.

## Part 1: Roadmap Sync

Update the website roadmap page (`website/src/pages/roadmap.astro`) with the latest data from the compiler roadmap plan.

### Source Files

Read these files to get the current roadmap status:

1. `plans/roadmap/00-overview.md` - Phase overview, tiers, milestones, dependency graph
2. `plans/roadmap/priority-and-tracking.md` - Current status of each phase, test results, immediate priorities
3. `plans/roadmap/phase-XX-*.md` - Individual phase files with detailed task checklists (read as needed for task bullet point updates)

### Data to Extract

#### From `00-overview.md`:
- Tier structure (8 tiers)
- Phase names and numbers (22 phases)
- Dependencies between phases
- Milestone definitions and exit criteria

#### From `priority-and-tracking.md`:
- Current status of each phase (✅ Complete, 🔶 Partial, ⏳ Not started)
- Notes for each phase (what's done, what's pending)
- Test results (Rust unit tests count, Ori spec tests count, skipped count)
- Milestone status

#### From `phase-XX-*.md` files:
- Individual task checklists with `[x]` (done) or `[ ]` (pending) markers
- Task names and groupings by section
- Any new tasks added since last sync

### Website Structure

The roadmap page has these main sections:

1. **Hero stats** - Count of phases by status (complete, in progress, planned)
2. **Completed section** - Collapsible section showing all phases with `status: "complete"`
3. **Tier sections** - Each tier shows only non-complete phases (partial or not-started)
4. **Dependency graph** - Visual representation of phase dependencies
5. **Test results** - Current test counts

#### Completed Section Logic

Phases with `status: "complete"` are:
- Automatically extracted and shown in the collapsed "Completed" section at the top
- Filtered OUT of their original tier sections
- This keeps completed work visible while tiers show remaining work

### Update Process

1. Read the source files
2. Parse the status tables to extract:
   - Phase number, name, status, and notes
   - Test counts
3. Update the `tiers` array in `website/src/pages/roadmap.astro` with:
   - Correct status for each phase (`complete`, `partial`, `not-started`)
   - Current notes from tracking
   - Tier-level status based on phase completion
4. **Update the task bullet points within each phase's sections:**
   - Each phase has `sections` with `tasks` (e.g., `{ name: "int, float, bool, str types", done: true }`)
   - Review the individual phase files (`phase-XX-*.md`) for detailed task completion status
   - Mark tasks as `done: true` or `done: false` based on current implementation status
   - Add new tasks if the phase file lists items not yet in the website
   - Remove tasks that are no longer relevant
5. Update the stats in the hero section:
   - Count phases by status
6. Update the "Test Results" section with latest counts

### Status Mapping

| Tracking Symbol | Website Status |
|-----------------|----------------|
| ✅ Complete | `complete` |
| 🔶 Partial / ~X% complete | `partial` |
| ⏳ Not started | `not-started` |

### Tier Status Logic

- `complete` - All phases in tier are complete
- `partial` or `in-progress` - At least one phase started but not all complete
- `planned` - No phases started, but dependencies met
- `future` - Blocked by earlier tiers

---

## Part 2: Changelog Sync

Update the changelog JSON file (`website/public/changelog.json`) with all commits from git history.

### Data File

The changelog data is stored as a static JSON file at `website/public/changelog.json`, loaded client-side with pagination. This keeps the page load fast even with hundreds of entries.

### Process

1. Run `git log --pretty=format:"%h|%ad|%s" --date=short` to get ALL commits
2. Filter out:
   - Merge commits (starts with "Merge")
   - WIP commits
   - Fixup/squash commits
   - Empty or trivial messages
3. Parse conventional commit format when present (type(scope): message)
4. Clean messages:
   - Remove conventional commit prefix (feat:, fix:, etc.)
   - Remove issue references like (#123)
   - Capitalize first letter
   - Remove trailing periods for consistency
5. Write to `website/public/changelog.json`

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

## Verification

After updating, verify the build succeeds:

```bash
cd website && bun run build
```

Report what changed:
- Roadmap: Which phases changed status, updated test counts, any new tasks added
- Changelog: Number of new entries added, date range covered
