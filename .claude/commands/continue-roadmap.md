# Continue Roadmap Command

Resume work on the Ori compiler roadmap, picking up where we left off.

## Usage

```
/continue-roadmap [section]
```

- No args: Auto-detect first incomplete item by scanning all sections in tier order
- `section-4`, `4`, or `modules`: Continue Section 4 (Modules)
- `section-8`, `8`, or `patterns`: Continue Section 8 (Patterns)
- `section-9`, `9`, or `match`: Continue Section 9 (Match)
- `section-7`, `7`, or `stdlib`: Continue Section 7 (Stdlib)
- `section-15`, `15`, or `syntax`: Continue Section 15 (Syntax Proposals)
- `section-21A`, `21A`, or `llvm`: Continue Section 21A (LLVM Backend)
- `section-21B`, `21B`, or `aot`: Continue Section 21B (AOT Compilation)

## Finding Sections by Topic

Use `plans/roadmap/index.md` to find sections by keyword. The index contains searchable keyword clusters for each section, making it easy to locate where specific features are tracked.

**Example workflow:**
1. Search index.md for "iterator" → finds Section 07C (Collections & Iteration)
2. Run `/continue-roadmap 07C` or `/continue-roadmap collections`

---

## Workflow

### Step 1: Determine Focus Section

**If argument provided**, use that section and skip to Step 3.

**If no argument provided**, scan section files in tier order to find the first incomplete item:

#### Section Scanning Order (by tier)

Scan sections in this order (matching `plans/roadmap/00-overview.md` tier structure):

```
Tier 1 (Foundation):
  section-01-type-system.md
  section-02-type-inference.md
  section-03-traits.md
  section-04-modules.md
  section-05-type-declarations.md

Tier 2 (Capabilities & Stdlib):
  section-06-capabilities.md
  section-07A-core-builtins.md
  section-07B-option-result.md
  section-07C-collections.md
  section-07D-stdlib-modules.md

Tier 3 (Core Patterns):
  section-08-patterns.md
  section-09-match.md
  section-10-control-flow.md

Tier 4 (FFI & Interop):
  section-11-ffi.md
  section-12-variadic-functions.md

Tier 5 (Language Completion):
  section-13-conditional-compilation.md
  section-14-testing.md
  section-15A-attributes-comments.md
  section-15B-function-syntax.md
  section-15C-literals-operators.md
  section-15D-bindings-types.md

Tier 6 (Async & Concurrency):
  section-16-async.md
  section-17-concurrency.md

Tier 7 (Advanced Type System):
  section-18-const-generics.md
  section-19-existential-types.md

Tier 8 (Ecosystem):
  section-20-reflection.md
  section-21A-llvm.md
  section-21B-aot.md
  section-22-tooling.md
```

### Step 2: Scan for First Incomplete Item

For each section file in order:

1. Read the section file's YAML frontmatter
2. Check the section `status` field:
   - If `status: complete`, skip to next section
   - If `status: in-progress` or `status: not-started`, this section has work — use it
3. For the selected section, find the first `- [ ]` checkbox in the body

**Stop at the first section with incomplete work.** This is the focus section.

If ALL sections have `status: complete`, report "Roadmap complete!"

> **CRITICAL:** The YAML frontmatter `status` field must ALWAYS match the checkbox state in the body. If they're out of sync, trust the checkboxes and **immediately fix the frontmatter**. Never proceed with stale frontmatter — the website and progress tracking depend on accurate status values. See "Verification/Audit Workflow" below for the full sync process.

### Step 3: Load Section Details

Read the focus section file (`plans/roadmap/section-XX-*.md`) and extract:

1. **Section title** from the `# Section N:` header
2. **Completion stats**: Count `[x]` vs `[ ]` checkboxes
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

### Example Update

If you complete the last checkbox in subsection 1.1B:

```yaml
# Before
  - id: "1.1B"
    title: Never Type Semantics
    status: in-progress

# After
  - id: "1.1B"
    title: Never Type Semantics
    status: complete
```

Then check if ALL subsections are now complete. If so, update the section status:

```yaml
# Before
status: in-progress

# After (only if ALL subsections are complete)
status: complete
```

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
- Add date stamps for verification: `✅ (2026-02-04)`

### Step 4: Update Frontmatter Immediately

**Never leave frontmatter stale.** After updating body checkboxes:

1. Recalculate each subsection status from its checkboxes
2. Update subsection `status` values in frontmatter
3. Recalculate section status from subsection statuses
4. Update section `status` value in frontmatter

### Step 5: Update Status Summary

Update any status messages in the body (e.g., "~45 failures remain" → "Only 2 bugs remain").

### Audit Checklist

When verifying a section:

- [ ] Frontmatter subsection statuses match body checkboxes
- [ ] Tested sample of `[x]` items — they actually work
- [ ] Tested sample of `[ ]` items — they actually fail
- [ ] Updated checkboxes to match reality
- [ ] **Updated frontmatter to match checkboxes**
- [ ] Updated status summary text in body
- [ ] Added verification date to completion summary

### Common Audit Triggers

Run an audit when:
- Starting work on a section after a long gap
- User reports "this feature works but roadmap says broken"
- Major refactoring that might have fixed/broken multiple items
- Before presenting roadmap status to stakeholders

---

## Section-Specific Notes

### Tier 1: Foundation

**Section 1: Type System** — Primitive types, Duration/Size, Never semantics
**Section 2: Type Inference** — HM inference, unification, generics
**Section 3: Traits** — Trait definitions, implementations, bounds
**Section 4: Modules** — Imports, exports, namespaces, extensions
**Section 5: Type Declarations** — Structs, enums, newtypes, associated functions

Key files: `compiler/ori_typeck/`, `compiler/ori_ir/src/types.rs`

### Tier 2: Capabilities & Stdlib

**Section 6: Capabilities** — Effect system, capability bounds
**Section 7A-D: Stdlib** — Built-ins, Option/Result, collections, modules

Key files: `library/std/`, `compiler/ori_eval/src/`

### Tier 3: Core Patterns

**Section 8: Patterns** — `run`, `try`, `cache`, `parallel`, etc.
**Section 9: Match** — Pattern matching, guards, exhaustiveness
**Section 10: Control Flow** — Loops, iterators, break/continue

Key files: `compiler/ori_patterns/`, `compiler/oric/src/patterns/`

### Tier 8: Ecosystem

**Section 21A: LLVM Backend** — JIT compilation, LLVM codegen for all language constructs
**Section 21B: AOT Compilation** — Native executables, WebAssembly, linking, debug info

Key files: `compiler/ori_llvm/`, `docker/llvm/`

### Other Tiers

Refer to individual section files for details.

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
