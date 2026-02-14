---
name: impl-hygiene-review
description: Review implementation hygiene at phase boundaries. NOT architecture or code style — purely plumbing quality.
allowed-tools: Read, Grep, Glob, Task, Bash, EnterPlanMode
---

# Implementation Hygiene Review

Review implementation hygiene against `.claude/rules/impl-hygiene.md` and generate a plan to fix violations.

**Implementation hygiene is NOT architecture** (design decisions are made) **and NOT code style** (naming, comments, formatting). It's the plumbing layer — phase boundaries, data flow, error propagation, abstraction discipline.

## Target

`$ARGUMENTS` specifies the boundary or scope to review. There are two modes:

### Path Mode (explicit crate/directory targets)
- `/impl-hygiene-review compiler/ori_lexer compiler/ori_parse` — review lexer→parser boundary
- `/impl-hygiene-review compiler/ori_parse compiler/ori_types` — review parser→type-checker boundary
- `/impl-hygiene-review compiler/ori_types` — review internal phase boundaries within a crate
- `/impl-hygiene-review compiler/ori_arc` — review ARC pass composition

### Commit Mode (use a commit as a scope selector)
- `/impl-hygiene-review last commit` — review files touched by the most recent commit
- `/impl-hygiene-review last 3 commits` — review files touched by the last N commits
- `/impl-hygiene-review <commit-hash>` — review files touched by a specific commit

**CRITICAL: Commits are scope selectors, NOT content filters.** The commit determines WHICH files and areas to review. Once the files are identified, review them completely — report ALL hygiene findings in those files, regardless of whether the finding is "related to" or "caused by" the commit. The commit is a lens to focus on a region of the codebase, nothing more. Do NOT annotate findings with whether they relate to the commit. Do NOT deprioritize or exclude findings because they predate the commit.

**Commit scoping procedure:**
1. Use `git diff --name-only HEAD~N..HEAD` (or appropriate range) to get the list of changed `.rs` files
2. Expand to include the full crate(s) those files belong to (e.g., if `compiler/ori_llvm/src/derive.rs` was touched, include all of `compiler/ori_llvm/`)
3. Proceed with the standard review process using those crates as the target

If no argument: ask the user what boundary to review.

## Execution

### Step 1: Load Rules

Read `.claude/rules/impl-hygiene.md` and `.claude/rules/compiler.md` to have the full rule set in context.

### Step 2: Map the Boundary

Identify the phase boundary being reviewed:
1. What types cross the boundary? (tokens, AST nodes, IR types)
2. What functions form the interface? (entry points, constructors, conversion functions)
3. What data flows across? (source text, spans, errors, metadata)

For each crate in the target, read `lib.rs` and the key interface files to understand the public API surface.

### Step 3: Trace Data Flow

Follow the data from producer to consumer:
1. **Read the producer's output types** — What does the upstream phase emit?
2. **Read the consumer's input handling** — How does the downstream phase receive and process it?
3. **Check the boundary types** — Are they minimal? Do they carry unnecessary baggage?
4. **Check ownership** — Is data moved, borrowed, or cloned? Are clones necessary?

### Step 4: Audit Each Rule Category

**Phase Boundary Discipline:**
- [ ] Data flows one way? (no callbacks to earlier phase, no reaching back)
- [ ] No circular imports between phase crates?
- [ ] Boundary types are minimal? (only what's needed crosses)
- [ ] Clean ownership transfer? (move at boundaries, borrow within)
- [ ] No phase bleeding? (each phase does only its job)

**Data Flow:**
- [ ] Zero-copy where possible? (spans, not string copies)
- [ ] No allocation in hot paths? (no `String::from()` per token)
- [ ] Interned values via opaque IDs? (not raw integers)
- [ ] Source text borrowed, not copied?
- [ ] Arena/temporary data freed with phase?

**Error Handling at Boundaries:**
- [ ] Errors accumulated, not bailed on first?
- [ ] Phase-scoped error types? (lexer errors ≠ parse errors)
- [ ] Upstream errors propagated? (not swallowed or silently dropped)
- [ ] All errors carry spans?
- [ ] Recovery behavior explicit? (enum, not boolean flag)

**Type Discipline:**
- [ ] Separate raw vs cooked types at each boundary?
- [ ] Newtypes for all IDs crossing boundaries?
- [ ] No phase state leaked in output types? (no parser cursor in AST)
- [ ] Metadata separated from semantic data?

**Pass Composition (for optimization passes):**
- [ ] Each pass is IR → IR? (no hidden inputs)
- [ ] Pass ordering explicit and documented?
- [ ] No shared mutable state between passes?
- [ ] Boundary invariants asserted?

### Step 5: Compile Findings

Organize findings by boundary/interface, categorized as:

- **LEAK** — Data or control flow crossing a boundary it shouldn't (phase bleeding, backward reference, swallowed error)
- **WASTE** — Unnecessary allocation, clone, or transformation at boundary (extra copy, redundant conversion)
- **EXPOSURE** — Internal state leaking through boundary types (parser state in AST, raw IDs without newtypes)
- **NOTE** — Observation, not actionable (acceptable tradeoff, documented exception)

### Step 6: Generate Plan

Use **EnterPlanMode** to create a fix plan. The plan should:

1. List every LEAK, WASTE, and EXPOSURE finding with `file:line` references
2. Group by boundary (e.g., "lexer→parser", "parser→types")
3. Estimate scope: "N boundaries, ~M findings"
4. Order: leaks first (phase bleeding), then waste (perf), then exposure (type safety)

### Plan Format

```
## Implementation Hygiene Review: {target}

**Scope:** N boundaries reviewed, ~M findings (X leak, Y waste, Z exposure)

### {Boundary: Phase A → Phase B}

**Interface types:** {list types crossing this boundary}
**Entry points:** {list key functions}

1. **[LEAK]** `file:line` — {description}
2. **[WASTE]** `file:line` — {description}
3. **[EXPOSURE]** `file:line` — {description}
...

### {Next Boundary}
...

### Execution Order

1. Phase bleeding fixes (may require interface changes)
2. Error propagation fixes (may add error variants)
3. Ownership/allocation fixes (perf, no API change)
4. Type discipline fixes (newtypes, generics)
5. Run `./test-all.sh` to verify no behavior changes
6. Run `./clippy-all.sh` to verify no regressions
```

## Important Rules

1. **No architecture changes** — Don't propose new phases, new IRs, or restructured crate graphs
2. **No code style fixes** — Don't flag naming, comments, or file organization (that's `/code-hygiene-review`)
3. **Trace, don't grep** — Follow actual data flow through the code, don't just search for patterns
4. **Read both sides** — Always read both the producer and consumer of a boundary
5. **Understand before flagging** — Some apparent violations are intentional (e.g., lexer tracking nesting depth for nested comments is acceptable phase-local state, not phase bleeding)
6. **Be specific** — Every finding must have `file:line`, the boundary it violates, and a concrete fix
7. **Compare to reference compilers** — When in doubt, check how Rust/Zig/Go/Gleam handle the same boundary at `~/projects/reference_repos/lang_repos/`
