---
name: code-review
description: Comprehensive compiler review with design synthesis informed by prior art from established compilers
allowed-tools: Read, Grep, Glob, Task, Bash
---

# Compiler Code Review

Analyze the Ori compiler for violations of documented patterns and industry best practices.

**This is a thorough, sprawling review.** Expect 20-30 minutes for full execution. The review systematically examines ALL crates, identifies systemic patterns, and synthesizes **best-of-breed designs** informed by prior art from established compilers.

> *"Good artists borrow, great artists steal."* — Picasso (misattributed)
>
> In language design, studying prior art isn't optional—it's scholarly rigor. Every major language cites influences: Rust learned from ML and C++, Go from Limbo and CSP, Swift from Objective-C and Haskell. This review studies what works elsewhere to inform Ori's unique design.

## Execution Strategy Overview

| Phase | Name | Parallelism | Purpose |
|-------|------|-------------|---------|
| **0** | Automated Tooling | 10 parallel bash | Lint, security, metrics |
| **1** | Discovery & Inventory | 6 parallel bash | Identify hotspots, largest files, complexity |
| **2** | Breadth-First Exploration | 5 parallel agents | Survey all crates systematically |
| **3** | Prior Art Research | 6 parallel agents | Study design patterns from Rust/Go/Zig/Gleam/Elm/Roc |
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

### Design Strengths Worth Learning From

**Error Messages:**
- **Elm**: Three-part structure (problem → context → hint), conversational tone, type difference highlighting
- **Rust**: Applicability levels (MachineApplicable, MaybeIncorrect, HasPlaceholders), multi-span suggestions
- **Roc**: Progressive disclosure (show more detail on request), semantic annotation types

**Type Systems:**
- **Rust**: Trait solving, lifetime inference, chalk-style unification
- **Zig**: Comptime, lazy type resolution, intern pools
- **TypeScript**: Structural typing, mapped types, conditional types

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
| **clippy** | `./clippy-all 2>&1 \|\| true` | Lint violations, code smells |
| **audit** | `cargo audit 2>&1 \|\| true` | Security vulnerabilities |
| **outdated** | `cargo outdated -R 2>&1 \|\| true` | Outdated direct dependencies |
| **machete** | `cargo machete 2>&1 \|\| true` | Unused dependencies |
| **geiger** | `(cd compiler/oric && cargo geiger 2>&1 \| tail -60) \|\| true` | Unsafe code usage |
| **tree-dups** | `cargo tree -d 2>&1 \|\| true` | Duplicate dependencies |
| **tokei** | `tokei compiler/ 2>&1 \|\| true` | Lines of code metrics |
| **modules-oric** | `cargo modules structure --lib -p oric 2>&1 \|\| true` | oric module structure |
| **modules-typeck** | `cargo modules structure --lib -p ori_typeck 2>&1 \|\| true` | typeck module structure |
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

**Pass hotspot list to Phase 2 and 3 agents** so they prioritize examining these files.

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
- compiler/ori_typeck/
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
   oric → ori_typeck/ori_eval/ori_patterns → ori_parse → ori_lexer → ori_ir/ori_diagnostic
4. Flag any UPWARD dependencies (lower importing higher)
5. Flag any unexpected tight coupling (e.g., ori_lexer importing ori_typeck)

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
- ori_typeck (should have documented inference entry points)

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

## Phase 3: Prior Art Research (after Phase 2)

Launch **6 parallel Explore agents** to study design patterns from established compilers. Send a **single message with 6 Task tool calls**.

These agents examine prior art in `~/projects/reference_repos/lang_repos/` to understand proven approaches that can inform Ori's unique design. This is standard practice in language design—every RFC and proposal cites prior art.

### Agent 3A: Error Message Design Study

```
Task(
  subagent_type: "Explore",
  description: "Prior Art: Error Messages",
  prompt: "Study error message design patterns from established compilers to inform Ori's approach.

EXAMINE THESE FILES:
- ~/projects/reference_repos/lang_repos/elm/compiler/src/Reporting/Error/Type.hs (type error messages)
- ~/projects/reference_repos/lang_repos/elm/compiler/src/Reporting/Doc.hs (document formatting)
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_errors/src/diagnostic.rs (diagnostic structure)
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_errors/src/lib.rs (applicability levels)
- ~/projects/reference_repos/lang_repos/roc/crates/reporting/src/report.rs (progressive disclosure)
- ~/projects/reference_repos/lang_repos/gleam/compiler-core/src/error.rs (error formatting)

STUDY:
1. How does Elm structure its three-part error messages? (problem/context/hint)
2. How does Rust define applicability levels for suggestions?
3. How does Roc implement progressive disclosure (show more on request)?
4. How does Gleam format error output?

Return: SOURCE | DESIGN_PATTERN | APPROACH | EXAMPLE | RELEVANCE_TO_ORI"
)
```

### Agent 3B: Type System Design Study

```
Task(
  subagent_type: "Explore",
  description: "Prior Art: Type Systems",
  prompt: "Study type system implementation approaches from established compilers.

EXAMINE THESE FILES:
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_middle/src/ty/mod.rs (type representation)
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_infer/src/infer/mod.rs (inference)
- ~/projects/reference_repos/lang_repos/zig/src/InternPool.zig (type interning)
- ~/projects/reference_repos/lang_repos/zig/src/Sema.zig (semantic analysis)
- ~/projects/reference_repos/lang_repos/gleam/compiler-core/src/analyse/infer.rs (HM inference)

STUDY:
1. How does Rust represent types (TyKind enum, interning)?
2. How does Zig's InternPool work for deduplication?
3. How does Gleam implement Hindley-Milner inference?
4. How do they handle type errors without stopping?

Return: SOURCE | DESIGN_PATTERN | APPROACH | EXAMPLE | RELEVANCE_TO_ORI"
)
```

### Agent 3C: Incremental Compilation Study

```
Task(
  subagent_type: "Explore",
  description: "Prior Art: Incremental",
  prompt: "Study incremental compilation approaches from established compilers.

EXAMINE THESE FILES:
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_query_system/src/ (query system)
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_middle/src/dep_graph/ (dependency tracking)
- ~/projects/reference_repos/lang_repos/zig/src/Compilation.zig (compilation model)
- ~/projects/reference_repos/lang_repos/typescript/src/compiler/builder.ts (incremental builds)

STUDY:
1. How does Rust's query system track dependencies?
2. How does Zig achieve fast incremental without a query system?
3. How does TypeScript handle incremental type checking?
4. What are the tradeoffs between query-based vs rebuild-based?

Return: REPO | PATTERN_NAME | HOW_IT_WORKS | TRADEOFFS | ORI_APPLICABILITY"
)
```

### Agent 3D: Code Fix Design Study

```
Task(
  subagent_type: "Explore",
  description: "Prior Art: Code Fixes",
  prompt: "Study code fix and suggestion approaches from established compilers.

EXAMINE THESE FILES:
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_errors/src/diagnostic.rs (suggestions)
- ~/projects/reference_repos/lang_repos/typescript/src/services/codeFixProvider.ts (code fixes)
- ~/projects/reference_repos/lang_repos/typescript/src/services/textChanges.ts (text edits)
- ~/projects/reference_repos/lang_repos/gleam/compiler-core/src/error.rs (did-you-mean)

STUDY:
1. How does Rust structure multi-part suggestions?
2. How does TypeScript provide rich code actions?
3. How does Gleam compute edit distance for suggestions?
4. How do they indicate confidence (auto-applicable vs uncertain)?

Return: SOURCE | DESIGN_PATTERN | APPROACH | EXAMPLE | RELEVANCE_TO_ORI"
)
```

### Agent 3E: Compiler Architecture Study

```
Task(
  subagent_type: "Explore",
  description: "Prior Art: Architecture",
  prompt: "Study compiler architecture approaches from established implementations.

EXAMINE THESE FILES:
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_driver/src/lib.rs (compiler driver)
- ~/projects/reference_repos/lang_repos/zig/src/main.zig (entry point)
- ~/projects/reference_repos/lang_repos/zig/src/Zcu.zig (compilation unit)
- ~/projects/reference_repos/lang_repos/go/src/cmd/compile/internal/gc/main.go (compilation phases)
- ~/projects/reference_repos/lang_repos/gleam/compiler-core/src/lib.rs (crate structure)

STUDY:
1. How does Rust organize compiler passes?
2. How does Zig achieve single-pass compilation?
3. How does Go structure its simple multi-pass approach?
4. How does Gleam organize its functional compiler?

Return: REPO | PATTERN_NAME | HOW_IT_WORKS | PROS_CONS | ORI_APPLICABILITY"
)
```

### Agent 3F: Test Infrastructure Study

```
Task(
  subagent_type: "Explore",
  description: "Prior Art: Testing",
  prompt: "Study compiler testing approaches from established implementations.

EXAMINE THESE DIRECTORIES:
- ~/projects/reference_repos/lang_repos/rust/tests/ui/ (UI tests structure)
- ~/projects/reference_repos/lang_repos/zig/test/ (test organization)
- ~/projects/reference_repos/lang_repos/gleam/compiler-core/src/ (inline tests)
- ~/projects/reference_repos/lang_repos/elm/tests/ (test structure)

STUDY:
1. How does Rust organize UI tests (compile-fail, run-pass)?
2. How does Rust handle expected error annotations?
3. How does Zig test compiler behavior?
4. How does Gleam test error messages?

Return: REPO | PATTERN_NAME | HOW_IT_WORKS | EXAMPLE | ORI_APPLICABILITY"
)
```

---

## Phase 4: Deep Category Analysis (after Phase 3)

Launch **10 parallel Explore agents** (one per category). Send a **single message with 10 Task tool calls**.

**IMPORTANT**: Include BOTH the hotspot list from Phase 1 AND relevant insights from Phase 3. Agents should evaluate Ori's implementation informed by what we've learned from prior art.

Each agent should:
1. **Read at least 10-15 actual files** (not just grep)
2. **Examine hotspot files first** (from Phase 1)
3. **Consider prior art insights** (from Phase 3) when suggesting improvements
4. Return findings with: severity, location (`file:line`), issue, fix, prior_art_insight

### Agent 4.1: Architecture & Boundaries

```
prompt: "Search for Architecture & Boundaries violations.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]

DETECTION PATTERNS:
CRITICAL:
- Upward dependency: lower crate imports higher (ori_ir → oric, ori_parse → ori_typeck)
- IO in core: file/network/env ops in ori_typeck, ori_types, ori_ir, ori_parse
- Phase bleeding: parser doing type checking, lexer doing parsing

HIGH:
- Missing phase boundary documentation
- Implicit coupling between modules
- Framework types (Salsa) leaking into pure logic
- Mixed abstraction levels in single function

MEDIUM:
- Unclear module responsibility
- Missing module-level doc comments

EXAMINE: Read lib.rs and 2-3 key files from EACH of ori_ir, ori_lexer, ori_parse, ori_typeck, ori_eval, oric.

Return: SEVERITY | file:line | issue | fix"
```

### Agent 4.2: Salsa & Incremental

```
prompt: "Search for Salsa & Incremental violations.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]

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

EXAMINE: Focus on ori_typeck (primary Salsa user). Read query definitions, tracked structs. Check ori_parse for any Salsa usage.

Return: SEVERITY | file:line | issue | fix"
```

### Agent 4.3: Memory & Allocation

```
prompt: "Search for Memory & Allocation violations.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]

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

EXAMINE: Focus on ori_ir (IR types), ori_parse (AST construction), ori_typeck (type representations). Look for .clone() calls, String::from(), Arc::clone().

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

EXAMINE: Look for trait definitions, dyn usage, large match statements. Focus on ori_patterns (pattern dispatch), ori_typeck (type dispatch).

Return: SEVERITY | file:line | issue | fix"
```

### Agent 4.6: Diagnostics

```
prompt: "Search for Diagnostics violations.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]

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

EXAMINE: Search for Diagnostic, Error, error!, panic!. Read ori_diagnostic crate. Check error construction in ori_typeck, ori_parse.

Return: SEVERITY | file:line | issue | fix"
```

### Agent 4.7: Testing

```
prompt: "Search for Testing violations.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]

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

EXAMINE: Focus on ori_typeck (inference loops), ori_parse (AST construction), ori_llvm (codegen). Look for nested loops, .clone() in loops, Vec::new() in loops.

Return: SEVERITY | file:line | issue | fix"
```

### Agent 4.9: Code Style

```
prompt: "Search for Code Style violations.

HOTSPOTS TO PRIORITIZE: [paste from Phase 1]

DETECTION PATTERNS:
CRITICAL:
- #[allow(clippy::...)] without comment
- Duplicated logic across modules
- God module: 1000+ lines, multiple concerns
- Hidden side effects

HIGH:
- Function >50 lines
- File >500 lines without single purpose
- Growing match statement (OCP violation)

MEDIUM:
- Banner comments instead of doc comments
- Comment explains 'what' not 'why'
- Dead/commented code

EXAMINE: Read the largest files. Check for long functions. Look for #[allow] attributes. Search for duplicated patterns.

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
  prompt: "You have findings from 21 parallel analyses (5 breadth + 6 reference + 10 category). Synthesize into systemic insights AND propose best-of-breed designs.

FINDINGS FROM PREVIOUS PHASES:
[Paste summaries from Phase 2, Phase 3, and Phase 4 agents]

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

## Final Output Format

After all phases complete, present:

### 1. Executive Summary
- Overall health score (1-10)
- Critical issues count
- High issues count
- Top 3 systemic problems

### 2. Automated Tool Results
- Security vulnerabilities
- Dependency issues
- Unsafe code locations
- Lint violations

### 3. Hotspot Analysis
- Files that are large AND frequently changed
- God module candidates
- Tech debt clusters

### 4. Findings by Severity

#### CRITICAL (must fix)
| Category | Location | Issue | Fix |
|----------|----------|-------|-----|

#### HIGH (should fix)
| Category | Location | Issue | Fix |
|----------|----------|-------|-----|

#### MEDIUM (fix when touching)
| Category | Location | Issue | Fix |
|----------|----------|-------|-----|

### 5. Systemic Patterns
- Issues appearing in 3+ places
- Architectural concerns
- Suggested extractions

### 6. Prior Art Insights
Summary of design patterns learned from studying established compilers:
| Area | Source | Design Pattern | Relevance to Ori |
|------|--------|----------------|------------------|

### 7. Ori Design Proposals (Informed by Prior Art)

For each major area, a unique Ori design synthesized from studying multiple established approaches:

#### Error Messages
- **Influences**: Elm (structure), Rust (applicability), Roc (disclosure), Gleam (suggestions)
- **Ori's Approach**: [description]
- **What Makes Ori's Design Unique**: [differentiation]

#### Type Representation
- **Influences**: Rust (TyKind), Zig (InternPool), Gleam (functional)
- **Ori's Approach**: [description]

#### Incremental Compilation
- **Influences**: Rust (queries), Zig (lazy), Go (simplicity)
- **Ori's Approach**: [description]

#### Diagnostics Infrastructure
- **Influences**: Rust (suggestions), TypeScript (code actions), Elm (format)
- **Ori's Approach**: [description]

#### Test Infrastructure
- **Influences**: Rust (UI tests), Zig (inline), Gleam (snapshots)
- **Ori's Approach**: [description]

### 8. Recommended Action Plan
Prioritized list combining:
1. Critical fixes
2. Best-of-breed implementations
3. Architectural improvements

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
./clippy-all                   # Clippy on all crates
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

### 1. Architecture & Boundaries
> Phase organization, layer dependencies, invariants, IO isolation

**Dependency direction**: `oric` → `ori_typeck/eval/patterns` → `ori_parse` → `ori_lexer` → `ori_ir/diagnostic`

**IO isolation**: Only `oric` CLI performs IO; core crates are pure.

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

### 9. Code Style
> DRY/SOLID, file organization, documentation

**Functions < 50 lines**: Target < 30.

**No dead code**: If you opened the file, you own it.

### 10. Extractable Patterns
> Match clustering, repetitive structures, emergent abstractions

**Match with 15+ similar arms**: Extract to module.

**Concept spread across 3+ files**: Needs a home.

---

## References

- Ori guidelines: `.claude/rules/compiler.md`

**Diagnostic patterns:**
- **Rust** (`rustc_errors`): Applicability levels, imperative suggestions
- **Go** (`go/types/errors.go`): Verb phrase fixes, error codes
- **Elm** (`Reporting/`): Three-part structure, type highlighting
- **Zig** (`Sema.zig`): "declared here" notes, reference traces
- **Gleam** (`error.rs`): Edit distance, extra labels
- **Roc** (`reporting/`): Progressive disclosure, semantic annotations
