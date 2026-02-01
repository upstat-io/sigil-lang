# Continue Roadmap Command

Resume work on the Ori compiler roadmap, picking up where we left off.

## Usage

```
/continue-roadmap [phase]
```

- No args: Auto-detect first incomplete item by scanning all phases in tier order
- `phase-4`, `4`, or `modules`: Continue Phase 4 (Modules)
- `phase-8`, `8`, or `patterns`: Continue Phase 8 (Patterns)
- `phase-9`, `9`, or `match`: Continue Phase 9 (Match)
- `phase-7`, `7`, or `stdlib`: Continue Phase 7 (Stdlib)
- `phase-15`, `15`, or `syntax`: Continue Phase 15 (Syntax Proposals)

---

## Workflow

### Step 1: Determine Focus Phase

**If argument provided**, use that phase and skip to Step 3.

**If no argument provided**, scan phase files in tier order to find the first incomplete item:

#### Phase Scanning Order (by tier)

Scan phases in this order (matching `plans/roadmap/00-overview.md` tier structure):

```
Tier 1 (Foundation):
  phase-01-type-system.md
  phase-02-type-inference.md
  phase-03-traits.md
  phase-04-modules.md
  phase-05-type-declarations.md

Tier 2 (Capabilities & Stdlib):
  phase-06-capabilities.md
  phase-07A-core-builtins.md
  phase-07B-option-result.md
  phase-07C-collections.md
  phase-07D-stdlib-modules.md

Tier 3 (Core Patterns):
  phase-08-patterns.md
  phase-09-match.md
  phase-10-control-flow.md

Tier 4 (FFI & Interop):
  phase-11-ffi.md
  phase-12-variadic-functions.md

Tier 5 (Language Completion):
  phase-13-conditional-compilation.md
  phase-14-testing.md
  phase-15A-attributes-comments.md
  phase-15B-function-syntax.md
  phase-15C-literals-operators.md
  phase-15D-bindings-types.md

Tier 6 (Async & Concurrency):
  phase-16-async.md
  phase-17-concurrency.md

Tier 7 (Advanced Type System):
  phase-18-const-generics.md
  phase-19-existential-types.md

Tier 8 (Ecosystem):
  phase-20-reflection.md
  phase-21A-llvm.md
  phase-21B-aot.md
  phase-22-tooling.md
```

### Step 2: Scan for First Incomplete Item

For each phase file in order:

1. Read the phase file
2. Find all checkboxes: `- [ ]` (incomplete) and `- [x]` (complete)
3. Look for the **first** `- [ ]` checkbox (incomplete item)
4. If found, this phase has incomplete work — use this phase
5. If all checkboxes are `[x]`, continue to next phase

**Stop at the first phase with incomplete work.** This is the focus phase.

If ALL phases are complete, report "Roadmap complete!"

### Step 3: Load Phase Details

Read the focus phase file (`plans/roadmap/phase-XX-*.md`) and extract:

1. **Phase title** from the `# Phase N:` header
2. **Completion stats**: Count `[x]` vs `[ ]` checkboxes
3. **First incomplete item**: The first `- [ ]` line and its context (section header, description)
4. **Recently completed items**: Last few `- [x]` items for context

### Step 4: Present Summary

Present to the user:

```
## Phase N: [Name]

**Progress:** X/Y items complete (Z%)

### Recently Completed
- [last 2-3 completed items]

### Next Up
**Section X.Y: [Section Name]**
- [ ] [First incomplete item description]
  - [sub-items if any]

### Remaining in This Phase
- [count of remaining incomplete items]
```

### Step 5: Ask What to Do

Use AskUserQuestion with options:
1. **Start next task (Recommended)** — Begin implementing the first incomplete item
2. **Show task details** — See more context about the task (read spec, find related code)
3. **Pick different task** — Choose a specific incomplete task from this phase
4. **Switch phases** — Work on a different phase

### Step 6: Execute Work

Based on user choice:
- **Start next task**: Begin implementing, following the Implementation Guidelines below
- **Show task details**: Read relevant spec sections, explore codebase for implementation location
- **Pick different task**: List all incomplete items in the phase, let user choose
- **Switch phases**: Ask which phase to switch to

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
4. **Check off items** — Update phase file checkboxes as you complete sub-items

### After Writing Code

1. **Run tests** — `./test-all` to verify everything passes
2. **Check formatting impact** — If syntax was added or changed:
   - Does the formatter handle the new syntax? Check `compiler/ori_fmt/`
   - Are formatting tests needed? Check/update `tests/spec/formatting/`
   - Run `./fmt-all` to ensure formatter still works
3. **Update phase file** — Check off completed items with `[x]`
4. **Commit with clear message** — Reference the phase and task

---

## Phase-Specific Notes

### Tier 1: Foundation

**Phase 1: Type System** — Primitive types, Duration/Size, Never semantics
**Phase 2: Type Inference** — HM inference, unification, generics
**Phase 3: Traits** — Trait definitions, implementations, bounds
**Phase 4: Modules** — Imports, exports, namespaces, extensions
**Phase 5: Type Declarations** — Structs, enums, newtypes, associated functions

Key files: `compiler/ori_typeck/`, `compiler/ori_ir/src/types.rs`

### Tier 2: Capabilities & Stdlib

**Phase 6: Capabilities** — Effect system, capability bounds
**Phase 7A-D: Stdlib** — Built-ins, Option/Result, collections, modules

Key files: `library/std/`, `compiler/ori_eval/src/`

### Tier 3: Core Patterns

**Phase 8: Patterns** — `run`, `try`, `cache`, `parallel`, etc.
**Phase 9: Match** — Pattern matching, guards, exhaustiveness
**Phase 10: Control Flow** — Loops, iterators, break/continue

Key files: `compiler/ori_patterns/`, `compiler/oric/src/patterns/`

### Tier 4-8: Later Phases

Refer to individual phase files for details.

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
- [ ] Update phase file checkboxes (mark items `[x]`)
- [ ] Commit with phase reference in message
