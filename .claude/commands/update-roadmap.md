# Update Website Roadmap

Update the website roadmap page (`website/src/pages/roadmap.astro`) with the latest data from the compiler roadmap plan.

## Source Files

Read these files to get the current roadmap status:

1. `plans/sigil-compiler-roadmap/00-overview.md` - Phase overview, tiers, milestones, dependency graph
2. `plans/sigil-compiler-roadmap/priority-and-tracking.md` - Current status of each phase, test results, immediate priorities
3. `plans/sigil-compiler-roadmap/phase-XX-*.md` - Individual phase files with detailed task checklists (read as needed for task bullet point updates)

## Data to Extract

### From `00-overview.md`:
- Tier structure (8 tiers)
- Phase names and numbers (22 phases)
- Dependencies between phases
- Milestone definitions and exit criteria

### From `priority-and-tracking.md`:
- Current status of each phase (✅ Complete, 🔶 Partial, ⏳ Not started)
- Notes for each phase (what's done, what's pending)
- Current focus area
- Test results (Rust unit tests count, Ori spec tests count, skipped count)
- Milestone status

### From `phase-XX-*.md` files:
- Individual task checklists with `[x]` (done) or `[ ]` (pending) markers
- Task names and groupings by section
- Any new tasks added since last sync

## Update Process

1. Read both source files
2. Parse the status tables to extract:
   - Phase number, name, status, and notes
   - Test counts
   - Current focus phases
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
6. Update the "Current Focus" section based on "Immediate Priority" in tracking
7. Update the "Test Results" section with latest counts

## Status Mapping

| Tracking Symbol | Website Status |
|-----------------|----------------|
| ✅ Complete | `complete` |
| 🔶 Partial / ~X% complete | `partial` |
| ⏳ Not started | `not-started` |

## Tier Status Logic

- `complete` - All phases in tier are complete
- `partial` or `in-progress` - At least one phase started but not all complete
- `planned` - No phases started, but dependencies met
- `future` - Blocked by earlier tiers

## Output

After updating, verify the build succeeds:
```bash
cd website && bun run build
```

Report what changed:
- Which phases changed status
- Updated test counts
- Any new notes added
