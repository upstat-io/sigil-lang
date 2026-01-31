# Continue Roadmap Command

Resume work on the Ori compiler roadmap, picking up where we left off.

## Usage

```
/continue-roadmap [phase]
```

- No args: Auto-detect highest priority incomplete work
- `phase-4`, `4`, or `modules`: Continue Phase 4 (Modules)
- `phase-8`, `8`, or `patterns`: Continue Phase 8 (Patterns)
- `phase-9`, `9`, or `match`: Continue Phase 9 (Match)
- `phase-7`, `7`, or `stdlib`: Continue Phase 7 (Stdlib)
- `phase-15`, `15`, or `syntax`: Continue Phase 15 (Syntax Proposals)

---

## Workflow

### Step 1: Load Current State

Read these files to understand current progress:

1. `plans/roadmap/priority-and-tracking.md` — Current status of all phases
2. `plans/roadmap/plan.md` — Overall roadmap structure and dependencies

### Step 2: Determine Focus

**If no argument provided**, identify the highest priority incomplete work from tracking file:

| Priority | Phase | What's Remaining |
|----------|-------|------------------|
| 1 | Phase 4 (Modules) | Type checker support for ModuleNamespace |
| 2 | Phase 8 (Patterns) | Cache TTL with Duration |
| 3 | Phase 9 (Match) | Guards, exhaustiveness checking |
| 4 | Phase 7 (Stdlib) | retry, validate functions |

**If argument provided**, use that phase.

### Step 3: Load Phase Details

Read the specific phase file to understand what tasks remain:

- Phase 4: `plans/roadmap/phase-04-modules.md`
- Phase 7: `plans/roadmap/phase-07-stdlib.md`
- Phase 8: `plans/roadmap/phase-08-patterns.md`
- Phase 9: `plans/roadmap/phase-09-match.md`
- Phase 15: `plans/roadmap/phase-15-syntax-proposals.md`

### Step 4: Present Summary

Present a summary to the user showing completed items, next up, and any blocked items.

### Step 5: Ask What to Do

Use AskUserQuestion with options:
1. **Start next task (Recommended)** — Begin implementing the next unchecked item
2. **Show task details** — See more context about the next task
3. **Pick different task** — Choose a specific task from the list
4. **Switch phases** — Work on a different phase

### Step 6: Execute Work

Based on user choice, either start implementation, show details, pick a different task, or switch phases.

---

## Implementation Guidelines

### Before Writing Code

1. **Read the spec** — Understand exactly what behavior is required
2. **Find existing tests** — Check `tests/spec/` for related test files
3. **Explore the codebase** — Use Explore agent to find where features should be implemented

### While Writing Code

1. **Follow existing patterns** — Match the style of surrounding code
2. **Add tests** — Create Ori spec tests in `tests/spec/category/`
3. **Add Rust tests** — Add unit tests for new Rust code
4. **Update tracking** — Check off items as completed

### After Writing Code

1. **Run tests** — `./test-all` to verify everything passes
2. **Check formatting impact** — If syntax was added or changed:
   - Does the formatter handle the new syntax? Check `compiler/ori_fmt/`
   - Are formatting tests needed? Check/update `tests/spec/formatting/`
   - Run `./fmt-all` to ensure formatter still works
3. **Update tracking file** — Mark items complete in `priority-and-tracking.md`
4. **Commit with clear message** — Reference the phase and task

---

## Phase-Specific Notes

### Phase 4: Modules

**Focus:** Type checker support for qualified access on ModuleNamespace

Key files:
- `compiler/oric/src/typeck/` — Type checking
- `compiler/oric/src/eval/` — Runtime (already works)
- `tests/spec/modules/` — Module tests

### Phase 7: Stdlib

**Focus:** `retry` and `validate` functions

Key files:
- `library/std/` — Standard library
- `tests/spec/patterns/` — Pattern tests

### Phase 8: Patterns

**Focus:** Cache TTL with Duration capability

Key files:
- `compiler/oric/src/patterns/` — Pattern evaluation
- `tests/spec/patterns/cache.ori` — Cache tests

### Phase 9: Match

**Focus:** Guards and exhaustiveness checking

Key files:
- `compiler/oric/src/patterns/` — Match pattern
- `compiler/oric/src/typeck/` — Exhaustiveness analysis
- `tests/spec/patterns/match.ori` — Match tests

### Phase 15: Syntax Proposals

**Focus:** Approved syntax changes from proposals

Key sections (check phase file for unchecked items):
- 15.1: Simplified attribute syntax
- 15.3: Remove dot prefix
- 15.5: Pre/post checks
- 15.6: String interpolation
- 15.7: `as` conversion syntax

---

## Checklist

When completing a roadmap item:

- [ ] Read spec section thoroughly
- [ ] Implement feature in compiler
- [ ] Add Ori spec tests
- [ ] Add Rust unit tests (if applicable)
- [ ] Run `./test-all` — all tests pass
- [ ] Check if formatting needs updates (if syntax changed):
  - [ ] Formatter handles new syntax (`compiler/ori_fmt/`)
  - [ ] Formatting tests cover new syntax (`tests/spec/formatting/`)
- [ ] Update phase file checkboxes
- [ ] Update `priority-and-tracking.md` if phase status changes
- [ ] Commit with phase reference in message
