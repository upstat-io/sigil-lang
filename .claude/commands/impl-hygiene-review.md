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

Read `.claude/rules/impl-hygiene.md` and `.claude/rules/compiler.md` to have the full rule set in context. Keep these rules available — you will embed them in every agent prompt.

### Step 2: Enumerate Files & Partition into Agent Workloads

1. **Glob** all `.rs` source files in the target crate(s) — exclude `/target/`, `/tests/`, and generated files.
2. **Get line counts** for each file using `wc -l` via Bash.
3. **Partition files into workloads** where each workload contains ≤ **2000 lines total**:
   - Sort files by path (to keep related modules together).
   - Greedily pack files into workloads: add files to the current workload until the next file would exceed 2000 lines, then start a new workload.
   - If a single file exceeds 2000 lines, it gets its own workload (the agent will handle it — the 2k limit is a target, not a hard wall).
4. **Report the partition** to the user: "N files, M total lines → K discovery agents (≤2000 lines each)".

### Step 3: Launch Discovery Agents (parallel)

Launch **K discovery agents** in parallel using the **Task tool** (`subagent_type: "general-purpose"`). Each agent receives:

**Agent prompt template:**

```
You are a discovery agent for an implementation hygiene review of the Ori compiler.

## Your Assignment
You are reviewing the following files (workload {i} of {K}):
{list of file paths with line counts}

These files belong to crate(s): {crate names}
The review scope covers: {crate names derived from $ARGUMENTS}

**IMPORTANT: Review ALL code in these files for hygiene violations. The scope was chosen to focus your attention on this area of the codebase — report every finding you see, regardless of when it was introduced. Do NOT consider git history, commit authorship, or recency. Treat these files as if reviewing them for the first time.**

## Rules to Check Against
{paste full contents of .claude/rules/impl-hygiene.md}

## Your Two Tasks

### Task A: Record Boundaries
For each file, identify and record all **phase boundary points** — places where data, types, or control flow cross (or could cross) a phase/crate boundary:

- **Boundary types**: Structs/enums that are `pub` and used across crate boundaries (check `use` imports in other crates)
- **Boundary functions**: `pub fn` that serve as entry points from another phase/crate
- **Data flow points**: Where data is constructed for the next phase or received from the previous phase
- **Error propagation points**: Where errors from one phase are converted, wrapped, or forwarded
- **Trait implementations**: `impl` blocks for traits defined in other crates

For each boundary, record:
- `file:line` location
- Direction: which phases are on each side (e.g., "lexer → parser")
- What crosses: types, ownership, lifetime, error info

### Task B: Record Violations
For each file, audit against ALL rule categories and record potential violations:

**Phase Boundary Discipline:**
- Data flows one way? (no callbacks to earlier phase, no reaching back)
- No circular imports?
- Boundary types minimal? (only what's needed crosses)
- Clean ownership transfer? (move at boundaries, borrow within)
- No phase bleeding? (each phase does only its job)

**Data Flow:**
- Zero-copy where possible? (spans, not string copies)
- No allocation in hot paths?
- Interned values via opaque IDs?
- Source text borrowed, not copied?
- Arena/temporary data freed with phase?

**Error Handling at Boundaries:**
- Errors accumulated, not bailed on first?
- Phase-scoped error types?
- Upstream errors propagated?
- All errors carry spans?
- Recovery behavior explicit?

**Type Discipline:**
- Separate raw vs cooked types?
- Newtypes for all IDs?
- No phase state leaked in output types?
- Metadata separated from semantic data?

**Pass Composition (if applicable):**
- Each pass is IR → IR?
- Pass ordering explicit?
- No shared mutable state?
- Boundary invariants asserted?

For each violation, record:
- `file:line` location
- Category: LEAK | WASTE | EXPOSURE
- Rule violated (which specific rule from the list above)
- Description of what's wrong
- Whether you are CONFIDENT or UNCERTAIN (uncertain = needs cross-boundary verification)

## Output Format

Return your findings as TWO sections:

### BOUNDARIES
```
BOUNDARY | file:line | direction | what_crosses | notes
```

### VIOLATIONS
```
VIOLATION | file:line | category | rule | confidence | description
```

Be thorough but precise. Do NOT flag things you don't understand — mark them UNCERTAIN.
Read every line of every assigned file. Do not skim.
```

**Important**: Launch ALL discovery agents in a **single message** with multiple Task tool calls so they run in parallel.

### Step 4: Launch Boundary Investigation Agent

After ALL discovery agents complete, launch a **single boundary investigation agent** (`subagent_type: "general-purpose"`) that performs cross-boundary analysis.

**Agent prompt template:**

```
You are the boundary investigation agent for an implementation hygiene review.

## Context
The review scope covers: {crate names derived from $ARGUMENTS}
Discovery agents analyzed {N} files across {crate names}.

**IMPORTANT: All findings are valid regardless of when they were introduced. Do NOT filter, annotate, or deprioritize findings based on git history or commit recency. The scope was chosen to focus attention on this area — every hygiene issue found is reportable.**

## Discovery Agent Reports
{paste ALL boundary reports and violation reports from Step 3 agents}

## Your Task: Cross-Boundary Analysis

The discovery agents found boundaries and potential violations within their individual file chunks. Your job is to analyze the boundaries ACROSS files — things a single-file agent cannot see.

### Analysis 1: Boundary Coherence
For each boundary identified by multiple agents (e.g., a type defined in one file, used in another):
- Does the data flow make sense end-to-end?
- Are boundary types consistent on both sides?
- Is ownership transferred cleanly across the full chain?

### Analysis 2: Validate UNCERTAIN Violations
For each UNCERTAIN violation from discovery agents:
- Read both sides of the boundary (use Read tool on the specific files/lines)
- Determine if it's a real violation or an acceptable pattern
- Upgrade to CONFIRMED or downgrade to DISMISSED with explanation

### Analysis 3: Cross-File Violations
Look for violations that span multiple files and that no single discovery agent could catch:
- Circular dependencies between files/modules
- Data that's cloned at boundary A, passed through B, cloned again at C (redundant allocations)
- Error types that are swallowed between phases (produced in file X, never checked in file Y)
- Phase bleeding where phase-specific logic leaks across multiple files
- Types that cross more boundaries than necessary

### Analysis 4: Boundary Map
Create a final boundary map showing:
- All phase boundaries in the reviewed scope
- What types/data flow across each
- Which boundaries have violations

## Output Format

### CONFIRMED VIOLATIONS
```
VIOLATION | file:line | category | rule | description | fix_suggestion
```

### DISMISSED (from UNCERTAIN)
```
DISMISSED | file:line | original_category | reason_dismissed
```

### NEW CROSS-BOUNDARY VIOLATIONS
```
VIOLATION | file:line(s) | category | rule | description | fix_suggestion
```

### BOUNDARY MAP
```
{Phase A} --[types: X, Y; data: Z]--> {Phase B}
  Violations: N (X leak, Y waste, Z exposure)
```

Read actual source code to verify — do NOT rely solely on discovery agent reports for cross-boundary analysis.
```

### Step 5: Compile Final Report

In the main context, compile the final report from:
1. **All discovery agent reports** — file-level boundaries and violations
2. **Boundary investigation agent report** — cross-boundary analysis, confirmed/dismissed violations, new findings

Merge and deduplicate findings. Final categories:
- **LEAK** — Data or control flow crossing a boundary it shouldn't
- **WASTE** — Unnecessary allocation, clone, or transformation at boundary
- **EXPOSURE** — Internal state leaking through boundary types
- **NOTE** — Observation, not actionable (acceptable tradeoff, documented exception)

Summarize for the user before entering plan mode:
```
## Hygiene Review Summary: {target}
- Files analyzed: N (M total lines, K discovery agents)
- Boundaries found: B
- Findings: X total (L leak, W waste, E exposure, N note)
- Cross-boundary issues: C (found by boundary investigation)
```

### Step 6: Generate Plan

Use **EnterPlanMode** to create a fix plan. The plan should:

1. List every LEAK, WASTE, and EXPOSURE finding with `file:line` references
2. Group by boundary (e.g., "lexer→parser", "parser→types")
3. Include the boundary map from the investigation agent
4. Estimate scope: "N boundaries, ~M findings"
5. Order: leaks first (phase bleeding), then waste (perf), then exposure (type safety)

### Plan Format

```
## Implementation Hygiene Review: {target}

**Scope:** N files analyzed (M lines, K agents) | B boundaries | F findings

### Boundary Map
{Phase A} --[types, data]--> {Phase B}: X findings
{Phase B} --[types, data]--> {Phase C}: Y findings

### {Boundary: Phase A → Phase B}

**Interface types:** {list types crossing this boundary}
**Entry points:** {list key functions}

1. **[LEAK]** `file:line` — {description}
   **Fix:** {concrete fix suggestion}
2. **[WASTE]** `file:line` — {description}
   **Fix:** {concrete fix suggestion}
3. **[EXPOSURE]** `file:line` — {description}
   **Fix:** {concrete fix suggestion}
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
4. **Read both sides** — The boundary investigation agent MUST read both producer and consumer
5. **Understand before flagging** — Some apparent violations are intentional (e.g., lexer tracking nesting depth for nested comments is acceptable phase-local state, not phase bleeding)
6. **Be specific** — Every finding must have `file:line`, the boundary it violates, and a concrete fix
7. **Compare to reference compilers** — When in doubt, check how Rust/Zig/Go/Gleam handle the same boundary at `~/projects/reference_repos/lang_repos/`
8. **Agent workloads ≤ 2000 lines** — Partition files so no discovery agent processes more than 2000 lines of source code
9. **Parallel execution** — ALL discovery agents MUST be launched in a single message (parallel Task calls)
10. **No false positives** — UNCERTAIN violations must be verified by the boundary investigation agent before appearing in the final report
