---
name: code-review
description: Comprehensive compiler review with design synthesis informed by prior art from established compilers
allowed-tools: Read, Grep, Glob, Task, Bash
---

# Compiler Code Review

Analyze the Ori compiler for violations of documented patterns and industry best practices.

**This is a thorough, sprawling review.** Expect 15-20 minutes for full execution. The review systematically examines ALL crates, identifies systemic patterns, and synthesizes **best-of-breed designs** informed by prior art from established compilers.

> *"Good artists borrow, great artists steal."* — Picasso (misattributed)
>
> In language design, studying prior art isn't optional—it's scholarly rigor. Every major language cites influences: Rust learned from ML and C++, Go from Limbo and CSP, Swift from Objective-C and Haskell. This review studies what works elsewhere to inform Ori's unique design.

## Execution Strategy Overview

| Phase | Name | Parallelism | Purpose |
|-------|------|-------------|---------|
| **0** | Automated Tooling | 10 parallel bash | Lint, security, metrics |
| **1** | Discovery & Inventory | 6 parallel bash | Identify hotspots, largest files, complexity |
| **2** | Breadth-First Exploration | 5 parallel agents | Survey all crates systematically |
| **3** | Prior Art Reference | Read prior-art-ref.md (~2 sec) | Design patterns from Rust/Go/Zig/Gleam/Elm/Roc/Swift/Koka/Lean 4 |
| **4** | Deep Category Analysis | 10 parallel agents | Pattern-specific violations |
| **5** | Best-of-Breed Synthesis | 1 agent | Combine reference patterns into superior Ori designs |

---

## Prior Art: Language Design Influences

Ori's design is informed by studying established compilers. Like academic research, we cite our influences and learn from what works. Located at `~/projects/reference_repos/lang_repos/`:

| Repo | Path | Strengths | Key Files |
|------|------|-----------|-----------|
| **Rust** | `rust/` | Error applicability, diagnostic infrastructure, query system | `compiler/rustc_errors/src/{lib,diagnostic}.rs`, `rustc_middle/src/ty/` |
| **Go** | `golang/` | Simplicity, clear error codes, fast compilation | `src/cmd/compile/internal/`, `src/go/types/errors.go` |
| **Zig** | `zig/` | Compile-time execution, "declared here" notes, incremental | `src/{Sema,Compilation,InternPool}.zig` |
| **Gleam** | `gleam/` | Edit distance suggestions, exhaustiveness, functional purity | `compiler-core/src/{error,analyse,exhaustiveness}.rs` |
| **Elm** | `elm/` | Best-in-class error messages, type diffing, progressive hints | `compiler/src/Reporting/{Error,Doc}.hs`, `Error/Type.hs` |
| **Roc** | `roc/` | Semantic annotations, output abstraction, progressive disclosure | `crates/reporting/src/{report,error/type}.rs` |
| **TypeScript** | `typescript/` | IDE integration, code fixes, language service | `src/compiler/{checker,diagnosticMessages}.ts`, `src/services/` |
| **Swift** | `swift/` | ARC optimization, SIL, ownership model, constraint solver | `lib/SILOptimizer/ARC/`, `lib/SIL/`, `lib/Sema/`, `include/swift/AST/Ownership.h` |
| **Koka** | `koka/` | Algebraic effects, effect inference, evidence passing | `src/Type/{Infer,Operations,Unify}.hs`, `src/Core/{Borrowed,CheckFBIP}.hs` |
| **Lean 4** | `lean4/` | Reference counting, reset/reuse, borrow inference | `src/Lean/Compiler/IR/{RC,Borrow,ExpandResetReuse}.lean`, `src/Lean/Compiler/LCNF/` |

### Design Strengths Worth Learning From

**Error Messages:**
- **Elm**: Three-part structure (problem → context → hint), conversational tone, type difference highlighting
- **Rust**: Applicability levels (MachineApplicable, MaybeIncorrect, HasPlaceholders), multi-span suggestions
- **Roc**: Progressive disclosure (show more detail on request), semantic annotation types

**Type Systems:**
- **Rust**: Trait solving, lifetime inference, chalk-style unification
- **Zig**: Comptime, lazy type resolution, intern pools
- **TypeScript**: Structural typing, mapped types, conditional types

**ARC & Memory Management:**
- **Swift**: SIL-level ARC optimization (retain/release elision, copy-on-write, ownership annotations)
- **Lean 4**: Reset/reuse optimization (destructive updates when RC=1), borrow inference
- **Koka**: FBIP (functional but in-place) via reuse analysis

**Effect Systems:**
- **Koka**: Row-polymorphic effects, evidence-passing translation, algebraic effect handlers
- **Swift**: Structured concurrency (async/await, actors — different model but relevant patterns)

**Architecture:**
- **Zig**: Single-pass with lazy resolution, minimal memory, no GC
- **Rust**: Query-based incremental (Salsa-like), arena allocation
- **Go**: Simple multi-pass, fast full rebuilds

**Code Fixes:**
- **TypeScript**: Rich code actions, refactoring infrastructure
- **Rust**: Structured suggestions with applicability
- **Gleam**: Edit distance with substring matching for typo suggestions

---

## Phase 0: Automated Tooling (run first)

Run these **10 cargo/analysis tools in parallel** using Bash. Send a **single message with 10 Bash tool calls**.

**IMPORTANT**: Each command must end with `|| true` to prevent one failure from cascading.

| Tool | Command | What it Detects |
|------|---------|-----------------|
| **clippy** | `./clippy-all.sh 2>&1 \|\| true` | Lint violations, code smells |
| **audit** | `cargo audit 2>&1 \|\| true` | Security vulnerabilities |
| **outdated** | `cargo outdated -R 2>&1 \|\| true` | Outdated direct dependencies |
| **machete** | `cargo machete 2>&1 \|\| true` | Unused dependencies |
| **geiger** | `(cd compiler/oric && cargo geiger 2>&1 \| tail -60) \|\| true` | Unsafe code usage |
| **tree-dups** | `cargo tree -d 2>&1 \|\| true` | Duplicate dependencies |
| **tokei** | `tokei compiler/ 2>&1 \|\| true` | Lines of code metrics |
| **modules-oric** | `cargo modules structure --lib -p oric 2>&1 \|\| true` | oric module structure |
| **modules-types** | `cargo modules structure --lib -p ori_types 2>&1 \|\| true` | types module structure |
| **deny** | `cargo deny check 2>&1 \|\| true` | License/advisory checks (if deny.toml exists) |

**Summarize findings:**
- **Security**: Vulnerabilities from `cargo audit`, advisories from `cargo deny`
- **Dependencies**: Unused (machete), outdated, duplicates (tree -d)
- **Unsafe**: Count and location of unsafe blocks
- **Lints**: Clippy warnings/errors
- **Metrics**: Total LOC by crate

---

## Phase 1: Discovery & Inventory (after Phase 0)

Run these **6 discovery commands in parallel** to identify hotspots. Send a **single message with 6 Bash tool calls**.

| Analysis | Command | Purpose |
|----------|---------|---------|
| **Largest files** | `find compiler/ -name "*.rs" -exec wc -l {} \; 2>/dev/null \| sort -rn \| head -40 \|\| true` | Find complexity hotspots |
| **Most functions** | `for f in $(find compiler/ -name "*.rs" 2>/dev/null); do echo "$(grep -c '^[[:space:]]*pub\?\s*fn ' "$f" 2>/dev/null) $f"; done \| sort -rn \| head -30 \|\| true` | Find god modules |
| **Git churn** | `git log --oneline --since="6 months ago" --name-only 2>/dev/null \| grep -E '\.rs$' \| sort \| uniq -c \| sort -rn \| head -30 \|\| true` | Find frequently changed files |
| **Long functions** | `grep -rn '^[[:space:]]*pub\?\s*fn ' compiler/ --include='*.rs' 2>/dev/null \| head -100 \|\| true` | Map function locations |
| **TODO/FIXME** | `grep -rn 'TODO\|FIXME\|HACK\|XXX' compiler/ --include='*.rs' 2>/dev/null \| head -50 \|\| true` | Find technical debt markers |
| **Skipped tests** | `grep -rn '#\[ignore\]\|#\[skip\]\|#skip' compiler/ tests/ --include='*.rs' --include='*.ori' 2>/dev/null \| head -30 \|\| true` | Find disabled tests |

**Build hotspot list from discovery:**
1. Files appearing in BOTH "largest" AND "git churn" = **critical hotspots**
2. Files with 30+ functions = **god module candidates**
3. Files with 500+ lines = **split candidates**
4. Files with multiple TODO/FIXME = **tech debt hotspots**

**Pass hotspot list to Phase 2 and 4 agents** so they prioritize examining these files.

---

## Phase 2: Breadth-First Exploration (after Phase 1)

Launch **5 parallel Explore agents** that systematically survey the codebase. Send a **single message with 5 Task tool calls**.

These agents take a **sprawling, big-picture approach** rather than pattern-matching.

### Agent 2A: Crate Survey

```
Task(
  subagent_type: "Explore",
  description: "Survey: All Crates",
  prompt: "Systematically survey EVERY crate in the Ori compiler. For EACH of these crates, read lib.rs and identify its purpose:

CRATES TO EXAMINE (read lib.rs for each):
- compiler/ori_ir/
- compiler/ori_lexer/
- compiler/ori_parse/
- compiler/ori_types/
- compiler/ori_eval/
- compiler/ori_patterns/
- compiler/ori_llvm/
- compiler/ori_diagnostic/
- compiler/oric/

For each crate, report:
1. Purpose (1 sentence from doc comment or inferred)
2. Public module count
3. Does lib.rs have a doc comment? (yes/no)
4. Any re-exports that seem wrong?
5. Dependency direction violations (imports from higher-level crate)?

Return a table: CRATE | PURPOSE | MODULES | HAS_DOCS | ISSUES"
)
```

### Agent 2B: Large File Audit

```
Task(
  subagent_type: "Explore",
  description: "Audit: Large Files",
  prompt: "Audit the 20 largest .rs files in compiler/. For EACH file:

1. Read the file (at least first 200 lines and last 100 lines)
2. Count approximate functions (grep for 'fn ')
3. Identify the file's single responsibility (or note if it has multiple)
4. Check for god-module symptoms:
   - Multiple unrelated sections
   - Functions that don't call each other
   - 3+ distinct import clusters
5. Check for match statements with 15+ arms

IMPORTANT: Actually READ each file, don't just grep. Look at structure.

Return: FILE | LINES | FUNCTIONS | RESPONSIBILITY | ISSUES"
)
```

### Agent 2C: Cross-Crate Coupling

```
Task(
  subagent_type: "Explore",
  description: "Analyze: Crate Coupling",
  prompt: "Analyze coupling between compiler crates.

1. For each crate, grep for 'use ori_' to find cross-crate imports
2. Build a dependency map showing which crates import which
3. Check against expected direction:
   oric → ori_types/ori_eval/ori_patterns → ori_parse → ori_lexer → ori_ir/ori_diagnostic
4. Flag any UPWARD dependencies (lower importing higher)
5. Flag any unexpected tight coupling (e.g., ori_lexer importing ori_types)

Also check:
- Are there types being passed through 3+ crates? (suggests wrong home)
- Are there duplicate type definitions in multiple crates?

Return: FROM_CRATE | TO_CRATE | IMPORT_COUNT | DIRECTION_OK? | NOTES"
)
```

### Agent 2D: Public API Surface

```
Task(
  subagent_type: "Explore",
  description: "Audit: Public APIs",
  prompt: "Audit the public API surface of each crate.

For each crate in compiler/:
1. Find all 'pub fn', 'pub struct', 'pub enum', 'pub trait' declarations
2. Check which have doc comments (/// or //!)
3. Identify functions with 5+ parameters (config struct needed)
4. Find 'pub use' re-exports and verify they make sense

Focus on:
- ori_ir (should have clean, well-documented IR types)
- ori_parse (should expose clear parsing API)
- ori_types (should have documented inference entry points)

Return: CRATE | ITEM | TYPE | HAS_DOCS | PARAM_COUNT | ISSUE"
)
```

### Agent 2E: Test Coverage Survey

```
Task(
  subagent_type: "Explore",
  description: "Survey: Test Coverage",
  prompt: "Survey test organization across the compiler.

1. For each crate, find test modules:
   - Inline #[cfg(test)] modules
   - tests/ directories
   - Integration tests

2. For each crate, estimate coverage:
   - Count public functions vs test functions
   - Look for untested public APIs
   - Check if complex functions have corresponding tests

3. Examine test quality:
   - Are tests named descriptively?
   - Do tests follow AAA pattern?
   - Are there snapshot tests for complex output?

4. Find test gaps:
   - Public functions with no tests
   - Error paths not tested
   - Edge cases missing

Return: CRATE | PUB_FNS | TEST_FNS | COVERAGE_ESTIMATE | GAPS"
)
```

---

## Phase 3: Prior Art Reference (pre-cooked)

Read `prior-art-ref.md` from this skill directory. This contains pre-extracted design patterns from all 10 reference compilers, organized by domain:

1. **Error Messages** — Elm, Rust, Roc, Gleam, Swift patterns
2. **Type Systems** — Rust, Zig, Gleam, Koka patterns
3. **Incremental Compilation** — Rust, Zig, TypeScript, Lean 4 patterns
4. **Code Fixes & Suggestions** — Rust, TypeScript, Gleam patterns
5. **Compiler Architecture** — Rust, Zig, Go, Gleam, Swift, Lean 4 patterns
6. **Test Infrastructure** — Rust, Zig, Gleam, Elm patterns

Pass relevant sections to Phase 4 agents as context and to Phase 5 synthesis.

To regenerate: `/regen-prior-art-ref`

---

## Phase 4: Deep Category Analysis (after Phase 3)

Launch **10 parallel Explore agents** (one per category). Send a **single message with 10 Task tool calls**.

**IMPORTANT**: Include BOTH the hotspot list from Phase 1 AND relevant prior art sections from prior-art-ref.md. Agents should evaluate Ori's implementation informed by what we've learned from prior art.

Each agent should:
1. **Read at least 10-15 actual files** (not just grep)
2. **Examine hotspot files first** (from Phase 1)
3. **Consider prior art insights** (see prior-art-ref.md sections relevant to this category) when suggesting improvements
4. Return findings with: severity, location (`file:line`), issue, fix, prior_art_insight

### Agent 4.1: Architecture & Implementation Hygiene

```
prompt: "Search for Architecture & Implementation Hygiene violations per .claude/rules/impl-hygiene.md.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]
PRIOR ART: See prior-art-ref.md section 5 (Compiler Architecture) for reference patterns.

DETECTION PATTERNS:

CRITICAL:
- Upward dependency: lower crate imports higher (ori_ir → oric, ori_parse → ori_types)
- IO in core: file/network/env ops in ori_types, ori_types, ori_ir, ori_parse
- Phase bleeding: parser doing type checking, lexer doing parsing
- Errors swallowed at phase boundary (lexer errors dropped by parser)
- Backward data flow (later phase calling back into earlier phase)

HIGH:
- Missing phase boundary documentation
- Implicit coupling between modules
- Framework types (Salsa) leaking into pure logic
- Unnecessary .clone() at phase boundaries (should move)
- Raw integer IDs crossing boundaries without newtypes
- Phase state leaking into output types (parser cursor in AST nodes)
- Allocation in hot token path (String::from per token)

MEDIUM:
- Unclear module responsibility
- Missing module-level doc comments
- Error types not phase-scoped (generic Error instead of LexError/ParseError)
- Metadata mixed with semantic data in AST

EXAMINE: Read lib.rs and 2-3 key files from EACH of ori_ir, ori_lexer, ori_parse, ori_types, ori_eval, oric. Trace data flow at crate boundaries.

Return: SEVERITY | file:line | issue | fix"
```

### Agent 4.2: Salsa & Incremental

```
prompt: "Search for Salsa & Incremental violations.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]
PRIOR ART: See prior-art-ref.md section 3 (Incremental Compilation) for reference patterns.

DETECTION PATTERNS:
CRITICAL:
- Missing derives on query types (needs Clone, Eq, PartialEq, Hash, Debug)
- Arc<Mutex<T>> or Arc<RwLock<T>> in Salsa-tracked types
- Function pointers or dyn Trait in query signatures
- Non-deterministic query (random, time, IO in query body)

HIGH:
- Query returns Result where (T, Vec<Error>) better
- Coarse query granularity
- Missing #[salsa::tracked] on type that should be tracked
- Query depends on unstable iteration order

EXAMINE: Focus on ori_types (primary Salsa user). Read query definitions, tracked structs. Check ori_parse for any Salsa usage.

Return: SEVERITY | file:line | issue | fix"
```

### Agent 4.3: Memory & Allocation

```
prompt: "Search for Memory & Allocation violations.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]
PRIOR ART: See prior-art-ref.md section 2 (Type Systems — Zig InternPool pattern) for reference patterns.

DETECTION PATTERNS:
CRITICAL:
- Box<Expr> instead of arena (ExprArena + ExprId)
- String for identifiers instead of interned Name
- Raw integer IDs without newtype (u32 instead of ExprId)
- Arc<T> cloned in hot loop

HIGH:
- Type alias instead of newtype: type ExprId = u32
- String comparisons where interned ID works
- Arc<dyn Trait> where &dyn or Box<dyn> suffices

EXAMINE: Focus on ori_ir (IR types), ori_parse (AST construction), ori_types (type representations). Look for .clone() calls, String::from(), Arc::clone().

Return: SEVERITY | file:line | issue | fix"
```

### Agent 4.4: API Design

```
prompt: "Search for API Design violations.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]

DETECTION PATTERNS:
CRITICAL:
- Function with 5+ parameters (needs config struct)
- Manual save/restore without RAII guard
- unwrap() on user input or file IO
- Public API without documentation

HIGH:
- Boolean parameter that changes behavior
- Context threaded through 5+ functions
- Missing builder for complex struct

MEDIUM:
- Return Vec where iterator works
- Option<Option<T>> or Result<Result<...>>

EXAMINE: Check public functions in each crate's lib.rs and main modules. Count parameters. Look for bool parameters.

Return: SEVERITY | file:line | issue | fix"
```

### Agent 4.5: Dispatch & Extensibility

```
prompt: "Search for Dispatch & Extensibility violations.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]

DETECTION PATTERNS:
CRITICAL:
- Arc<dyn Trait> for fixed compile-time set (should be enum)
- Registry lookup for built-in patterns
- dyn Trait where enum gives exhaustiveness

HIGH:
- Hard-coded dispatch with 20+ match arms
- Box<dyn Trait> where &dyn suffices
- Trait object where generic allows inlining

EXAMINE: Look for trait definitions, dyn usage, large match statements. Focus on ori_patterns (pattern dispatch), ori_types (type dispatch).

Return: SEVERITY | file:line | issue | fix"
```

### Agent 4.6: Diagnostics

```
prompt: "Search for Diagnostics violations.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]
PRIOR ART: See prior-art-ref.md section 1 (Error Messages) for reference patterns.

DETECTION PATTERNS:
CRITICAL:
- Cryptic error message
- Missing span on error
- panic! on recoverable error
- Early bailout instead of error accumulation

HIGH:
- Missing 'did you mean?' for typos
- Inconsistent error style
- No error code

Check message phrasing:
- Question phrasing ('Did you mean?') → should be imperative ('try using')
- Noun phrase fixes → should be verb phrase ('Replace X with Y')

EXAMINE: Search for Diagnostic, Error, error!, panic!. Read ori_diagnostic crate. Check error construction in ori_types, ori_parse.

Return: SEVERITY | file:line | issue | fix"
```

### Agent 4.7: Testing

```
prompt: "Search for Testing violations.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]
PRIOR ART: See prior-art-ref.md section 6 (Test Infrastructure) for reference patterns.

DETECTION PATTERNS:
CRITICAL:
- No test for public function
- Test verifies implementation not behavior
- Flaky test
- #[ignore] without reason

HIGH:
- Inline tests >200 lines
- Missing edge case tests
- Stale skipped tests (blocking feature now implemented)

EXAMINE: Check each crate's tests/ dir and #[cfg(test)] modules. Cross-reference public functions with test coverage. Read actual test code to assess quality.

Return: SEVERITY | file:line | issue | fix"
```

### Agent 4.8: Performance

```
prompt: "Search for Performance violations.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]

DETECTION PATTERNS:
CRITICAL:
- O(n²) where O(n) or O(n log n) possible
- Linear scan in hot loop (should hash)
- Allocation in hot loop
- Unbounded recursion

HIGH:
- Repeated lookup that could be cached
- collect() followed by iter()
- HashMap in hot path (should be FxHashMap)

EXAMINE: Focus on ori_types (inference loops), ori_parse (AST construction), ori_llvm (codegen). Look for nested loops, .clone() in loops, Vec::new() in loops.

Return: SEVERITY | file:line | issue | fix"
```

### Agent 4.9: Code Style & Hygiene

```
prompt: "Search for Code Style & Hygiene violations per .claude/rules/code-hygiene.md.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]

DETECTION PATTERNS:

CRITICAL:
- #[allow(clippy::...)] without reason = '...' (prefer #[expect] when possible)
- Duplicated logic across modules
- God module: 1000+ lines, multiple concerns
- Hidden side effects
- Dead pub items (pub but unused outside crate)

HIGH:
- Function >50 lines (target <30; dispatch tables/large matches exempt)
- File >500 lines without single purpose
- Growing match statement (OCP violation)
- Manual trait impl that duplicates derive behavior (PartialEq, Eq, Hash, Debug)
- Missing //! module doc on file
- Missing /// on pub items

MEDIUM:
- Decorative banner comments (// ───, // ===, // ***, // ---)
- Comment explains 'what' not 'why'
- Dead/commented-out code
- File organization out of order (should be: mod decls → imports → type aliases → types → inherent impls → trait impls → free fns → tests)
- Imports not in 3 groups (external → crate:: → super::) with blank-line separators
- Impl block methods out of order (constructors → accessors → predicates → operations → conversions → private helpers)
- Naming violations: functions missing verb prefix, variables not scope-scaled
- Struct/enum fields not ordered (primary data → secondary → config → flags last)

EXAMINE: Read the largest files. Check for long functions. Look for #[allow] attributes. Search for duplicated patterns. Check file/impl ordering. Check naming conventions.

Return: SEVERITY | file:line | issue | fix"
```

### Agent 4.10: Extractable Patterns

```
prompt: "Search for Extractable Patterns & Emergent Complexity.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]

DETECTION PATTERNS:
CRITICAL:
- Match with 15+ arms where 3+ follow identical structure
- 3+ methods with near-identical bodies

HIGH:
- God match: 20+ arms in one function
- Implicit grouping: related arms scattered
- Responsibility divergence: module has 3+ distinct concerns
- Cross-file pattern: same pattern in 4+ files

MEDIUM:
- Same 3-line pattern appears 5+ times
- Functions with common prefix/suffix across files

EXAMINE: Find large match statements. Look for repetitive code. Trace concepts across files (e.g., 'width calculation', 'name resolution' - where do they live?).

Return: SEVERITY | file:line | issue | fix"
```

---

## Phase 5: Best-of-Breed Synthesis (after Phase 4)

Launch **1 final Explore agent** to synthesize all findings AND propose best-of-breed designs combining patterns from reference implementations.

```
Task(
  subagent_type: "Explore",
  description: "Synthesize: Best-of-Breed",
  prompt: "You have findings from 16 parallel analyses (5 breadth + 1 prior art doc + 10 category). Synthesize into systemic insights AND propose best-of-breed designs.

FINDINGS FROM PREVIOUS PHASES:
[Paste summaries from Phase 2 and Phase 4 agents]

PRIOR ART: Read prior-art-ref.md for reference patterns from all 10 compilers.

PART A: ISSUE SYNTHESIS

1. **Pattern Identification**: What issues appear in 3+ reports? These are systemic.

2. **Hotspot Correlation**: Files appearing in 4+ violation categories = 'worst offenders'.

3. **Architectural Health**: Rate overall health (1-10) with justification.

4. **Technical Debt Map**: Combine TODO/FIXME + code quality issues into debt clusters.

5. **Priority Ranking**: TOP 10 most impactful changes considering severity, breadth, risk, effort.

PART B: BEST-OF-BREED DESIGN PROPOSALS

For each major finding, propose a **combined design** that takes the best from multiple reference implementations:

6. **Error Message Design**: Combine:
   - Elm's three-part structure (problem/context/hint)
   - Rust's applicability levels (MachineApplicable, MaybeIncorrect, HasPlaceholders)
   - Roc's progressive disclosure (show more detail on request)
   - Gleam's edit-distance suggestions
   → Propose: Ori's unique error message architecture

7. **Type Representation Design**: Combine:
   - Rust's TyKind enum structure
   - Zig's InternPool for deduplication
   - Gleam's functional type representation
   → Propose: Ori's unique type system architecture

8. **Incremental Compilation Design**: Combine:
   - Rust's query-based approach (fine-grained caching)
   - Zig's lazy resolution (minimal recomputation)
   - Go's simplicity (fast full rebuilds when needed)
   → Propose: Ori's unique incrementality strategy

9. **Diagnostic Infrastructure Design**: Combine:
   - Rust's structured suggestions with spans
   - TypeScript's code action system
   - Elm's conversational error format
   → Propose: Ori's unique diagnostic infrastructure

10. **Test Infrastructure Design**: Combine:
    - Rust's UI test framework (compile-fail, run-pass)
    - Zig's inline test expectations
    - Gleam's snapshot testing for errors
    → Propose: Ori's unique testing approach

For each proposal:
- Cite specific patterns from 2-3 reference repos
- Explain why this combination is superior to any single source
- Identify what Ori can do that none of the references do
- Provide a concrete implementation sketch

Return:

## PART A: Issue Synthesis
### Systemic Issues (3+ occurrences)
### Worst Offender Files
### Architecture Health Score: X/10
### Top 10 Priority Actions

## PART B: Best-of-Breed Designs
### 1. Error Message Architecture
**Sources**: [repos used]
**Combined Design**: [description]
**Ori Unique Advantage**: [what we do better]
**Implementation Sketch**: [concrete steps]

### 2. Type Representation
[same format]

### 3. Incremental Strategy
[same format]

### 4. Diagnostic Infrastructure
[same format]

### 5. Test Infrastructure
[same format]

## Recommended Roadmap
Prioritized implementation order for the best-of-breed designs."
)
```

---

## Severity Guide

- **CRITICAL**: Must fix before merge (security vulns, breaking bugs, panic on user input)
- **HIGH**: Should fix, blocks new code (outdated deps, unsafe in wrong places, missing tests)
- **MEDIUM**: Fix when touching code (style, minor improvements, missing docs)

---

## Final Output

**Do NOT output the full review to the screen.** All findings go directly to the plan files (see Phase 6).

After all phases complete:

1. **Write the plan** to `plans/cr_MMDDYYYY_##/` (see Phase 6 for structure)
2. **Output only a brief summary** to the user:

```
Code review complete.

Health Score: X/10
Plan written to: plans/cr_MMDDYYYY_##/

Quick Stats:
- Critical: N issues
- High: N issues
- Medium: N issues
- Design Proposals: N

Top 3 priorities:
1. {brief description}
2. {brief description}
3. {brief description}

Run `cat plans/cr_MMDDYYYY_##/00-overview.md` to see the full summary.
```

---

## Tool Reference

### Quick Commands

```bash
# Security & Dependencies
cargo audit                    # Security vulnerabilities
cargo outdated -R              # Outdated direct dependencies
cargo machete                  # Unused dependencies
cargo deny check               # License/advisory checks
cargo tree -d                  # Duplicate dependencies

# Code Quality
./clippy-all.sh                # Clippy on all crates
cargo geiger                   # Unsafe code count (from crate dir)
tokei compiler/                # Lines of code stats

# Architecture
cargo modules structure --lib -p oric     # Module tree
cargo modules dependencies --lib -p oric  # Dependency graph
cargo tree                                 # External deps

# Discovery
find compiler/ -name "*.rs" -exec wc -l {} \; | sort -rn | head -30  # Largest files
git log --oneline --since="6 months ago" --name-only | grep '\.rs$' | sort | uniq -c | sort -rn | head -20  # Churn
```

### Interpreting Results

**cargo audit**: Any vulnerability = CRITICAL.

**cargo machete**: Unused deps. Verify before removing (some are feature-gated).

**cargo geiger**: Unsafe count. ori_ir/ori_parse/ori_lexer should have ZERO unsafe.

**cargo tree -d**: Duplicate deps increase binary size and can cause version conflicts.

**Git churn + size**: Files that are BOTH large AND frequently changed are highest priority for refactoring.

---

## Category Reference

The 10 analysis categories with full detection patterns:

### 1. Architecture & Implementation Hygiene
> Full rules in `.claude/rules/impl-hygiene.md`. Phase boundaries, data flow, error propagation, abstraction discipline.

**Dependency direction**: `oric` → `ori_types/eval/patterns` → `ori_parse` → `ori_lexer` → `ori_ir/diagnostic`

**IO isolation**: Only `oric` CLI performs IO; core crates are pure.

**Phase boundaries**: One-way data flow, minimal crossing types, clean ownership transfer.

**Error propagation**: Accumulate across phases, phase-scoped types, upstream errors propagated not swallowed.

### 2. Salsa & Incremental
> Query design, derives, determinism, caching granularity

**Determinism**: Same inputs → same outputs, always.

**Partial results**: Return best-effort + errors, not `Result<T, E>`.

### 3. Memory & Allocation
> Arenas, interning, newtypes, reference counting

**Arena pattern**: AST/IR nodes in arenas, reference by ID.

**Interning**: Identifiers → O(1) comparison.

### 4. API Design
> Config structs, RAII guards, function signatures

**Config structs**: >3-4 params → single config struct.

**RAII guards**: For lexically-scoped context changes.

### 5. Dispatch & Extensibility
> Enum vs dyn Trait, registries, static vs dynamic

**Enum for fixed sets**: Built-ins → exhaustiveness, static dispatch.

**Cost hierarchy**: `&dyn` < `Box<dyn>` < `Arc<dyn>`.

### 6. Diagnostics
> Error messages, suggestions, recovery

**Three-part structure**: Problem → context → guidance.

**Imperative suggestions**: "try using X" not "Did you mean X?".

### 7. Testing
> Snapshot testing, organization, coverage

**Three layers**: Unit, integration, spec conformance.

**Skipped tests**: Every skip needs reason AND unskip criteria.

### 8. Performance
> Algorithm complexity, hot paths, allocations

**O(n²) → O(n log n)**: Beats micro-optimization.

**Iterators over indexing**: Bounds checks eliminated.

### 9. Code Style & Hygiene
> Full rules in `.claude/rules/code-hygiene.md`. DRY/SOLID, file organization, naming, comments, visibility.

**Functions**: Target < 30 lines, max 50 (dispatch tables exempt).

**File organization**: mod decls → imports (3 groups) → types → impls → free fns → tests.

**Impl ordering**: constructors → accessors → predicates → operations → conversions → private helpers.

**Comments**: `//!` on every file, `///` on all pub items, WHY not WHAT, no decorative banners.

**Derive vs manual**: Derive when standard; manual only when behavior differs.

**No dead code**: If you opened the file, you own it.

### 10. Extractable Patterns
> Match clustering, repetitive structures, emergent abstractions

**Match with 15+ similar arms**: Extract to module.

**Concept spread across 3+ files**: Needs a home.

---

## References

- Ori guidelines: `.claude/rules/compiler.md`
- Code hygiene rules: `.claude/rules/code-hygiene.md` (file org, naming, comments, derive, visibility, style)
- Implementation hygiene rules: `.claude/rules/impl-hygiene.md` (phase boundaries, data flow, error propagation, type discipline)

**Diagnostic patterns:**
- **Rust** (`rustc_errors`): Applicability levels, imperative suggestions
- **Go** (`go/types/errors.go`): Verb phrase fixes, error codes
- **Elm** (`Reporting/`): Three-part structure, type highlighting
- **Zig** (`Sema.zig`): "declared here" notes, reference traces
- **Gleam** (`error.rs`): Edit distance, extra labels
- **Roc** (`reporting/`): Progressive disclosure, semantic annotations
- **Swift** (`CSDiagnostics.cpp`): Constraint solver failure diagnosis, ARC diagnostics

**ARC & memory management:**
- **Swift** (`lib/SILOptimizer/ARC/`): Retain/release optimization, copy elision, ownership model
- **Lean 4** (`Compiler/IR/{RC,Borrow,ExpandResetReuse}.lean`): RC insertion, borrow inference, reset/reuse
- **Koka** (`Core/{Borrowed,CheckFBIP}.hs`): Functional-but-in-place, reuse analysis

**Effect systems:**
- **Koka** (`Type/{Infer,Operations}.hs`): Row-polymorphic effects, evidence passing, algebraic handlers

---

## Phase 6: Write Plan Output (REQUIRED)

After completing the review, you **MUST** write the findings to a plan in `plans/` using the standard template format.

### Naming Convention

```
plans/cr_MMDDYYYY_##/
```

Where:
- `cr_` = code review prefix
- `MMDDYYYY` = date (e.g., `02042026` for February 4, 2026)
- `_##` = sequential number (01, 02, etc.) if multiple reviews on same day

**To determine the sequence number:**
1. Check existing `plans/cr_MMDDYYYY_*` directories for today's date
2. Use the next available number (start with `_01` if none exist)

### Directory Structure

Create this structure:

```
plans/cr_MMDDYYYY_##/
├── index.md           # Keyword index for findings
├── 00-overview.md     # Executive summary, health score, priorities
├── section-01-critical.md    # CRITICAL severity issues
├── section-02-high.md        # HIGH severity issues
├── section-03-medium.md      # MEDIUM severity issues
├── section-04-proposals.md   # Best-of-breed design proposals
└── section-05-roadmap.md     # Recommended action plan
```

### File Templates

#### `00-overview.md`

```markdown
---
plan: "cr_MMDDYYYY_##"
title: Code Review - {Date}
status: complete
health_score: {X}/10
critical_count: {N}
high_count: {N}
medium_count: {N}
---

# Code Review: {Month Day, Year}

**Health Score:** {X}/10
**Review Duration:** {approximate time}

## Executive Summary

{Top 3 systemic problems identified}

## Automated Tool Results

| Tool | Result Summary |
|------|----------------|
| clippy | {summary} |
| audit | {summary} |
| ... | ... |

## Hotspot Files

Files that are large AND frequently changed:

| File | Lines | Churn | Issues |
|------|-------|-------|--------|

## Quick Stats

- **Critical Issues:** {N}
- **High Issues:** {N}
- **Medium Issues:** {N}
- **Design Proposals:** {N}
```

#### `section-01-critical.md` (and similar for HIGH/MEDIUM)

```markdown
---
section: "01"
title: Critical Issues
status: not-started
severity: critical
issue_count: {N}
---

# Section 01: Critical Issues

**Status:** Planned
**Count:** {N} issues

---

## 01.1 {Category Name}

- [ ] **{Issue Title}** — `file:line`
  - Description: {what's wrong}
  - Fix: {how to fix}
  - Prior Art: {reference if applicable}

- [ ] **{Another Issue}** — `file:line`
  - Description: {what's wrong}
  - Fix: {how to fix}

---

## 01.N Completion Checklist

- [ ] All critical issues addressed
- [ ] Re-run automated tools to verify
- [ ] No new critical issues introduced

**Exit Criteria:** Zero CRITICAL issues remaining
```

#### `section-04-proposals.md`

```markdown
---
section: "04"
title: Best-of-Breed Design Proposals
status: not-started
---

# Section 04: Design Proposals

**Status:** Planned

Based on prior art study from Rust, Go, Zig, Gleam, Elm, Roc, Swift, Koka, and Lean 4.

---

## 04.1 Error Message Architecture

**Influences:** Elm (structure), Rust (applicability), Roc (disclosure), Gleam (suggestions)

**Proposed Design:**
{description}

**What Makes Ori's Design Unique:**
{differentiation}

**Implementation Tasks:**
- [ ] {task 1}
- [ ] {task 2}

---

## 04.2 Type Representation

{same format}

---

## 04.N Completion Checklist

- [ ] All proposals documented
- [ ] Implementation tasks identified
- [ ] Dependencies mapped

**Exit Criteria:** Proposals ready for implementation planning
```

#### `index.md`

```markdown
# Code Review {MMDDYYYY} Index

> **Generated:** {timestamp}

## How to Use

1. Search this file (Ctrl+F) for keywords
2. Find the section
3. Open the section file

---

## Sections

### Section 01: Critical Issues
**File:** `section-01-critical.md` | **Count:** {N}

```
{categories of critical issues}
security, panic, data loss
```

---

### Section 02: High Issues
**File:** `section-02-high.md` | **Count:** {N}

```
{categories}
```

---

### Section 03: Medium Issues
**File:** `section-03-medium.md` | **Count:** {N}

```
{categories}
```

---

### Section 04: Design Proposals
**File:** `section-04-proposals.md`

```
error messages, types, incremental, diagnostics, testing
best-of-breed, prior art, architecture
```

---

### Section 05: Recommended Roadmap
**File:** `section-05-roadmap.md`

```
priorities, action plan, sequence
```

---

## Quick Reference

| ID | Title | File | Count |
|----|-------|------|-------|
| 01 | Critical Issues | `section-01-critical.md` | {N} |
| 02 | High Issues | `section-02-high.md` | {N} |
| 03 | Medium Issues | `section-03-medium.md` | {N} |
| 04 | Design Proposals | `section-04-proposals.md` | — |
| 05 | Roadmap | `section-05-roadmap.md` | — |
```

### Important Notes

1. **Always write the plan** — This is not optional. Every code review must produce a plan.
2. **Use real findings** — Populate sections with actual issues found, not placeholders.
3. **Track by checkbox** — Each issue becomes a trackable task.
4. **Link to code** — Always include `file:line` references.
5. **Report the path** — Tell the user where the plan was written: `Plan written to: plans/cr_MMDDYYYY_##/`
