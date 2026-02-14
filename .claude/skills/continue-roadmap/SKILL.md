---
name: continue-roadmap
description: Resume work on the Ori compiler roadmap, picking up where we left off
argument-hint: "[section]"
---

# Continue Roadmap

Resume work on the Ori compiler roadmap, picking up where we left off.

## Usage

```
/continue-roadmap [section]
```

- No args: Auto-detect first incomplete item sequentially (00 → 01 → ...)
- `section-4`, `4`, or `modules`: Continue Section 4 (Modules)
- Any section number or keyword: Use `plans/roadmap/index.md` to find sections by keyword

## Finding Sections by Topic

Use `plans/roadmap/index.md` to find sections by keyword. The index contains searchable keyword clusters for each section.

---

## Workflow

### Step 1: Run the Scanner

Run the roadmap scanner script to get current status:

```bash
.claude/skills/continue-roadmap/roadmap-scan.sh plans/roadmap
```

This outputs:
- One line per section: `[done]` or `[open]` with progress stats
- Detail block for the **first incomplete section**: subsection statuses, first 5 unchecked items with line numbers

### Step 2: Determine Focus Section

**If argument provided**, find the matching section file and skip to Step 3.

**If no argument provided**, use the scanner's `=== FOCUS ===` section — the first section with `[ ]` items, scanning sequentially from Section 00.

#### Dependency Skip Rule

Only skip a section if **all** of these are true:
1. The section has explicit dependencies listed in `plans/roadmap/00-overview.md` § Dependency Graph
2. One or more of those dependencies has `status: not-started` or `status: in-progress` (prerequisite isn't complete)
3. The incomplete work in the current section actually **requires** the blocker (not all items may be blocked)

If a section has some blocked items and some unblocked items, **work the unblocked items** rather than skipping.

### Step 3: Load Section Details

Read the focus section file at the line numbers reported by the scanner. Extract:

1. **Section title** from the `# Section N:` header
2. **Completion stats**: from scanner output
3. **First incomplete item**: The first `- [ ]` line and its context (subsection header, description)
4. **Recently completed items**: Last few `- [x]` items for context

### Step 4: Present Summary

Present to the user:

```
## Section N: [Name]

**Progress:** X/Y items complete (Z%)

### Recently Completed
- [last 2-3 completed items]

### Next Up
**Subsection X.Y: [Subsection Name]**
- [ ] [First incomplete item description]
  - [sub-items if any]

### Remaining in This Section
- [count of remaining incomplete items]
```

### Step 5: Ask What to Do

Use AskUserQuestion with options:
1. **Start next task (Recommended)** — Begin implementing the first incomplete item
2. **Show task details** — See more context about the task (read spec, find related code)
3. **Pick different task** — Choose a specific incomplete task from this section
4. **Switch sections** — Work on a different section

### Step 6: Execute Work

Based on user choice:
- **Start next task**: Begin implementing, following the Implementation Guidelines below
- **Show task details**: Read relevant spec sections, explore codebase for implementation location
- **Pick different task**: List all incomplete items in the section, let user choose
- **Switch sections**: Ask which section to switch to

---

## Implementation Guidelines

### Scope Rule: ALL Checkboxes in the Section Are In Scope

**Every `- [ ]` checkbox within the current section is part of that section's work — no exceptions.** This includes:

- **LLVM Support** checkboxes (codegen verification)
- **LLVM Rust Tests** checkboxes (AOT end-to-end tests)
- **Ori Tests** checkboxes
- **Rust Tests** checkboxes
- Any other sub-item checkboxes nested under a parent item

**Do NOT defer items to other sections.** If subsection 1.1A has `[ ] LLVM Rust Tests: No AOT tests for Duration`, that checkbox is part of 1.1A — not Section 21A. Section 21A tracks LLVM *infrastructure* (codegen architecture, optimization passes). Individual feature sections track their own LLVM *coverage* (does this feature work in AOT?).

**A subsection is only complete when ALL its checkboxes are checked**, including LLVM items. Do not mark a subsection as complete or move to the next subsection while LLVM checkboxes remain unchecked.

### Verification Rule: Empty Checkboxes Must Be Verified

**Never check off a `[ ]` item without verifying it.** Before marking any item `[x]`:

1. **Read the relevant code** — confirm the feature/test actually exists
2. **Run the test** — if it's a test item, run it and confirm it passes
3. **Check the spec** — if it's an implementation item, verify behavior matches the spec

Checking off items without verification defeats the purpose of the roadmap.

### Before Writing Code

1. **Read the spec** — Understand exactly what behavior is required
2. **Find existing tests** — Check `tests/spec/` for related test files
3. **Explore the codebase** — Use Explore agent to find where features should be implemented

### While Writing Code

1. **Follow existing patterns** — Match the style of surrounding code
2. **Add tests** — Create Ori spec tests in `tests/spec/category/`
3. **Add Rust tests** — Add unit tests for new Rust code
4. **Check off items** — Update section file checkboxes as you complete sub-items

### After Writing Code

1. **Run tests** — `./test-all.sh` to verify everything passes
2. **Check formatting impact** — If syntax was added or changed:
   - Does the formatter handle the new syntax? Check `compiler/ori_fmt/`
   - Are formatting tests needed? Check/update `tests/spec/formatting/`
   - Run `./fmt-all.sh` to ensure formatter still works
3. **Update section file** — Check off completed items with `[x]`
4. **Update YAML frontmatter** — See "Updating Section File Frontmatter" below
5. **Commit with clear message** — Reference the section and task

---

## Updating Section File Frontmatter

Section files use YAML frontmatter for machine-readable status tracking. **You must keep this in sync** when completing tasks.

### Frontmatter Structure

```yaml
---
section: "1"
title: Type System Foundation
status: in-progress          # Section-level status
tier: 1
goal: Fix type checking...
sections:
  - id: "1.1"
    title: Primitive Types
    status: complete         # Subsection-level status
  - id: "1.1B"
    title: Never Type Semantics
    status: in-progress
---
```

### Status Values

- `not-started` — No checkboxes completed in subsection/section
- `in-progress` — Some checkboxes completed, some pending
- `complete` — All checkboxes completed

### When to Update

**After completing task checkboxes**, update the frontmatter:

1. **Update subsection status** based on checkboxes under that `## X.Y` header:
   - All `[x]` → `status: complete`
   - Mix of `[x]` and `[ ]` → `status: in-progress`
   - All `[ ]` → `status: not-started`

2. **Update section status** based on subsection statuses:
   - All subsections complete → `status: complete`
   - Any subsection in-progress → `status: in-progress`
   - All subsections not-started → `status: not-started`

### Why This Matters

The website dynamically loads roadmap data from these YAML frontmatter blocks. Incorrect status values cause the roadmap page to show wrong progress information.

---

## Verification/Audit Workflow

When auditing roadmap accuracy (verifying status rather than implementing features), follow this workflow:

### Step 1: Compare Frontmatter to Body

Before testing anything, check if frontmatter matches checkbox state:

1. Read the YAML frontmatter subsection statuses
2. Scan the body for `[x]` and `[ ]` checkboxes under each `## X.Y` header
3. **If they don't match** — the roadmap is stale and needs updating

### Step 2: Test Claimed Status

Don't trust checkboxes blindly. Verify actual implementation:

1. **For `[x]` items**: Write quick test to confirm feature works
2. **For `[ ]` items**: Write quick test to confirm feature fails/is missing
3. **Document discrepancies**: Note items where claimed status doesn't match reality

### Step 3: Update Body Checkboxes

Fix checkboxes to match verified reality:

- Feature works → `[x]`
- Feature broken/missing → `[ ]`
- Add date stamps for verification: `(2026-02-04)`

### Step 4: Update Frontmatter Immediately

**Never leave frontmatter stale.** After updating body checkboxes:

1. Recalculate each subsection status from its checkboxes
2. Update subsection `status` values in frontmatter
3. Recalculate section status from subsection statuses
4. Update section `status` value in frontmatter

---

## Checklist

When completing a roadmap item:

- [ ] Read spec section thoroughly
- [ ] Implement feature in compiler
- [ ] Add Ori spec tests
- [ ] Add Rust unit tests (if applicable)
- [ ] Run `./test-all.sh` — all tests pass
- [ ] Check if formatting needs updates (if syntax changed):
  - [ ] Formatter handles new syntax (`compiler/ori_fmt/`)
  - [ ] Formatting tests cover new syntax (`tests/spec/formatting/`)
- [ ] Update section file:
  - [ ] Check off completed items with `[x]`
  - [ ] Update subsection `status` in YAML frontmatter if subsection is now complete
  - [ ] Update section `status` in YAML frontmatter if all subsections are now complete
- [ ] Commit with section reference in message

---

## Maintaining the Roadmap Index

**IMPORTANT:** When adding new items to the roadmap, update `plans/roadmap/index.md`:

1. **Adding items to existing section**: Add relevant keywords to that section's keyword cluster
2. **Creating a new section**: Add a new keyword cluster block and table entry
3. **Removing/renaming sections**: Update the corresponding entries

The index enables quick topic-based navigation. Keep keyword clusters concise (3-8 lines) and include both formal names and common aliases developers might search for.
