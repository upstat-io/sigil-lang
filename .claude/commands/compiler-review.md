---
name: compiler-review
description: Analyze the Ori compiler for DRY/SOLID violations and industry best practices
allowed-tools: Read, Grep, Glob, Task
---

# Compiler Code Review

Analyze the Ori compiler for violations of documented patterns and industry best practices.

## Execution Strategy

Use the **Task tool** to launch **9 parallel Explore agents** (one per category below). Send a **single message with 9 Task tool calls** to maximize parallelism.

Each agent prompt should:
1. Specify the category name and detection patterns from that section
2. Search `compiler/` for violations matching those patterns
3. Return findings with: severity, location (`file:line`), issue, fix suggestion

**Example Task call:**
```
Task(
  subagent_type: "Explore",
  description: "Review: Architecture",
  prompt: "Search compiler/ for Architecture & Boundaries violations: [paste detection patterns]. Return findings as: SEVERITY | file:line | issue | fix"
)
```

**After all 9 agents complete**, aggregate and synthesize:
1. Group findings by severity (CRITICAL → HIGH → MEDIUM)
2. Identify patterns (same issue in multiple places)
3. Prioritize by impact on maintainability
4. Present actionable summary to user

## Severity Guide

- **CRITICAL**: Must fix before merge
- **HIGH**: Should fix, blocks new code
- **MEDIUM**: Fix when touching code

---

## 1. Architecture & Boundaries

> Phase organization, layer dependencies, invariants, IO isolation

### Detection Patterns

**CRITICAL**
- Upward dependency: lower crate imports higher (`ori_ir` → `oric`, `ori_parse` → `ori_typeck`)
- IO in core: file/network/env ops in `ori_typeck`, `ori_types`, `ori_ir`, `ori_parse`
- Circular dependency between crates
- Phase bleeding: parser doing type checking, lexer doing parsing

**HIGH**
- Missing phase boundary documentation
- Implicit coupling: module A assumes internal state of module B
- Framework types in core: Salsa types leaking into pure logic
- Mixed abstraction levels in single function

**MEDIUM**
- Unclear module responsibility (does multiple unrelated things)
- Missing module-level doc comment explaining purpose
- Cross-cutting concern not isolated (e.g., span tracking scattered)

### Principles

- **Dependency direction**: `oric` → `ori_typeck/eval/patterns` → `ori_parse` → `ori_lexer` → `ori_ir/diagnostic`
- **IO isolation**: Only `oric` CLI performs IO; core crates are pure
- **Phase contracts**: Each phase has documented input/output types
- **Invariants**: Document what must always hold (parser never fails, always produces AST)

### Checklist

- [ ] No upward dependencies between crates
- [ ] IO isolated to CLI layer (`oric`)
- [ ] Each crate has clear single responsibility
- [ ] Phase boundaries documented in module docs
- [ ] No Salsa types in non-query code

---

## 2. Salsa & Incremental

> Query design, derives, determinism, caching granularity

### Detection Patterns

**CRITICAL**
- Missing derives on query types: needs `Clone, Eq, PartialEq, Hash, Debug`
- `Arc<Mutex<T>>` or `Arc<RwLock<T>>` in Salsa-tracked types
- Function pointers or `dyn Trait` in query signatures
- Non-deterministic query: random, time, or IO in query body
- Side effects in queries (mutation, IO, global state)

**HIGH**
- Query returns `Result` where `(T, Vec<Error>)` better (partial results)
- Coarse query granularity: recomputes too much on small changes
- Missing `#[salsa::tracked]` on type that should be tracked
- Query depends on unstable iteration order (HashMap without sort)

**MEDIUM**
- Query could be split for better incrementality
- Expensive computation not memoized
- Debug impl on query type is expensive

### Principles

- **Determinism**: Same inputs → same outputs, always
- **Partial results**: Return best-effort result + errors, not `Result<T, E>`
- **Granularity**: Finer queries = better incrementality, but more overhead
- **Immutable after construction**: Build fully, then wrap in `Arc`

### Checklist

- [ ] All query types derive required traits
- [ ] No interior mutability in tracked types
- [ ] No side effects in query bodies
- [ ] Queries are deterministic
- [ ] Error accumulation, not early bailout

---

## 3. Memory & Allocation

> Arenas, interning, newtypes, reference counting

### Detection Patterns

**CRITICAL**
- `Box<Expr>` instead of arena allocation (`ExprArena` + `ExprId`)
- `String` for identifiers instead of interned `Name`
- Raw integer IDs without newtype (`u32` instead of `ExprId`)
- `Arc<T>` cloned in hot loop
- Unbounded collection growth (Vec/HashMap never cleared)

**HIGH**
- Type alias instead of newtype: `type ExprId = u32;`
- `(String, String)` tuples instead of `MethodKey` newtype
- String comparisons where interned ID comparison works
- Excessive cloning of IR structures
- `Arc<dyn Trait>` where `&dyn` or `Box<dyn>` suffices

**MEDIUM**
- Scattered heap allocations for related nodes
- Missing `#[cold]` on error factory functions
- Intermediate collections in recursive functions
- `to_string()` / `clone()` in hot path

### Principles

- **Arena allocation**: AST/IR nodes in arenas, reference by ID
- **Interning**: Identifiers, strings, method keys → O(1) comparison
- **Newtypes**: Type-safe IDs prevent mixing `ExprId` with `TypeId`
- **Push allocations to caller**: Return iterators, not `Vec`

### Checklist

- [ ] AST nodes use arena + ID pattern
- [ ] Identifiers are interned `Name` type
- [ ] IDs are newtypes, not raw integers
- [ ] No `Arc` cloning in hot paths
- [ ] Error paths marked `#[cold]`

---

## 4. API Design

> Config structs, builders, RAII guards, function signatures

### Detection Patterns

**CRITICAL**
- Function with 5+ parameters (should use config struct)
- Manual save/restore of context without RAII guard
- `unwrap()` on user input or file IO
- Public API without documentation

**HIGH**
- Boolean parameter that changes behavior (flag argument)
- "Doer" object: `Builder::new().set_x(x).execute()` for simple operation
- Missing builder for complex struct with many optional fields
- Context threaded through 5+ functions (consider RAII or context object)

**MEDIUM**
- Return `Vec` where iterator would work
- `Option<Option<T>>` or `Result<Result<T, E1>, E2>` (flatten)
- Inconsistent parameter ordering across similar functions
- Missing `Default` impl for config struct

### Principles

- **Config structs**: >3-4 params → single config/options struct
- **Functions over doer objects**: Prefer `do_thing(Config { x, y })` over builder ceremony
- **RAII guards**: Use for lexically-scoped context changes (capabilities, impl scope)
- **Push allocations to caller**: Return iterators, accept slices

### Checklist

- [ ] No functions with 5+ parameters
- [ ] No boolean flag parameters
- [ ] RAII guards for context save/restore
- [ ] Public items documented
- [ ] Config structs implement `Default`

---

## 5. Dispatch & Extensibility

> Enum vs dyn Trait, registries, static vs dynamic dispatch

### Detection Patterns

**CRITICAL**
- `Arc<dyn Trait>` for fixed, compile-time-known set (should be enum)
- Registry lookup for built-in patterns (`run`, `try`, `match`)
- `dyn Trait` where enum gives exhaustiveness checking

**HIGH**
- Missing registry for user-extensible system (user methods need dynamic dispatch)
- Hard-coded dispatch growing with every feature (match with 20+ arms on type)
- `Box<dyn Trait>` where `&dyn Trait` suffices (unnecessary allocation)
- Trait object where generic would allow inlining

**MEDIUM**
- Enum variant added but match not updated (missing exhaustiveness benefit)
- Over-abstracted: trait with single implementation
- Registry for things that won't change at runtime

### Principles

- **Enum for fixed sets**: Built-in patterns, operators, keywords → exhaustiveness, static dispatch, inlining
- **`dyn Trait` for user-extensible**: User methods, plugins → runtime dispatch necessary
- **Cost hierarchy**: `&dyn` < `Box<dyn>` < `Arc<dyn>` (prefer cheapest that works)
- **Registries**: Only when users add entries at runtime

### Checklist

- [ ] Built-in patterns use enum, not registry
- [ ] User methods use registry/trait objects
- [ ] No `Arc<dyn>` for fixed sets
- [ ] Trait objects only where necessary
- [ ] Match statements on enums (not type strings)

---

## 6. Diagnostics

> Error messages, suggestions, recovery, error codes

### Detection Patterns

**CRITICAL**
- Terse/cryptic error message (user can't understand what's wrong)
- Missing source location (span) on error
- `panic!` on recoverable error (user input, file not found)
- Early bailout: stops at first error instead of accumulating

**HIGH**
- Missing "did you mean?" suggestion for typos
- Inconsistent error message style (capitalization, punctuation)
- Error without context (what was being done when error occurred)
- No error code for programmatic handling

**MEDIUM**
- Missing fix suggestion where one is obvious
- Error message uses internal jargon instead of user terms
- Duplicate error for same underlying issue
- Warning that should be error (or vice versa)

### Principles

- **User-first messages**: Write for the person seeing the error, not the compiler author
- **Context + cause + fix**: What happened, why, how to fix
- **Accumulate errors**: Don't stop at first error; show all problems
- **Suggestions**: "Did you mean X?" when edit distance is small

### Checklist

- [ ] All errors have source spans
- [ ] Error messages are actionable
- [ ] Errors accumulate, not early bailout
- [ ] Typo suggestions implemented
- [ ] No `panic!` on user errors

---

## 7. Testing

> Snapshot testing, test organization, coverage layers

### Detection Patterns

**CRITICAL**
- No test for public function
- Test verifies implementation, not behavior
- Flaky test (timing, shared state, order-dependent)
- `#[ignore]` without tracking issue

**HIGH**
- Inline tests exceeding 200 lines (should be in `tests/` subdirectory)
- Missing edge case tests (empty, boundary, error conditions)
- Snapshot test without clear expected output
- Test mocks 5+ dependencies (suggests SRP violation)

**MEDIUM**
- Poor test naming (`test_1`, `test_parser`)
- No AAA structure (Arrange-Act-Assert unclear)
- Missing compile-fail tests for error paths
- Test duplicates logic instead of using fixtures

### Principles

- **Three layers**: Unit (isolated), integration (components), spec (language conformance)
- **Snapshot testing**: Complex output (errors, IR dumps) use snapshots
- **Behavior, not implementation**: Test what it does, not how
- **Data-driven**: Fixture + expected output, not API-direct

### Checklist

- [ ] Public functions have tests
- [ ] Edge cases covered (empty, boundary, error)
- [ ] Inline tests < 200 lines
- [ ] Snapshot tests for complex output
- [ ] No flaky tests

---

## 8. Performance

> Algorithm complexity, hot paths, allocation patterns

### Detection Patterns

**CRITICAL**
- O(n²) where O(n) or O(n log n) possible
- Linear scan in hot loop (should use hash lookup)
- Allocation in hot loop (`String::new()`, `Vec::new()`, `clone()`)
- Unbounded recursion without tail-call or iteration

**HIGH**
- Repeated lookup that could be cached
- Nested loops over same data
- `collect()` followed by `iter()` (intermediate allocation)
- HashMap with bad hash function in hot path

**MEDIUM**
- Missing `#[inline]` on small hot function
- `FxHashMap` would outperform `HashMap` in hot path
- Bounds check on every iteration (use iterators)
- Debug-only code in hot path

### Principles

- **Measure first**: Profile before optimizing
- **Algorithmic complexity**: O(n²) → O(n log n) beats micro-optimization
- **Allocation hierarchy**: Stack < arena < heap; reuse > allocate
- **Iterators over indexing**: Bounds checks eliminated, better optimization

### Checklist

- [ ] No O(n²) in hot paths
- [ ] Hash lookups instead of linear scans
- [ ] No allocation in hot loops
- [ ] Iterators preferred over indexing
- [ ] Hot functions profiled

---

## 9. Code Style

> DRY/SOLID adapted for compilers, file organization, documentation

### Detection Patterns

**CRITICAL**
- `#[allow(clippy::...)]` without comment explaining why
- Duplicated logic across modules (DRY violation)
- God module: 1000+ lines doing multiple unrelated things
- Hidden side effect: function does more than name suggests

**HIGH**
- Function > 50 lines (target < 30)
- File > 500 lines without clear single purpose
- Match statement growing with every feature (OCP violation)
- Import from sibling's internals (coupling)

**MEDIUM**
- Banner comments (`// ====`) instead of doc comments
- Comment explains "what" instead of "why"
- Inconsistent naming conventions
- Dead code / commented-out code

### Principles

- **Single responsibility**: One reason to change per module/function
- **Open/closed**: New features = new code, not modified code
- **Line count as smell**: Investigate 500+ line files, don't auto-split
- **Documentation**: Public items documented, modules have doc comments

### Checklist

- [ ] No `#[allow(clippy)]` without justification
- [ ] Functions < 50 lines
- [ ] Files have single clear purpose
- [ ] No dead code or commented-out code
- [ ] Public items documented

---

## Output Format

For each finding:
1. **Severity**: CRITICAL / HIGH / MEDIUM
2. **Category**: Which section above
3. **Location**: `file:line` or file path
4. **Issue**: What's wrong (one line)
5. **Fix**: How to resolve (one line)

Group by severity, then by category. Identify patterns (same issue in multiple places).

## References

- Ori guidelines: `.claude/rules/compiler.md`
- rust-analyzer style: `~/lang_repos/rust/src/tools/rust-analyzer/docs/`
- Gleam compiler: `~/lang_repos/gleam/compiler-core/`
- Roc compiler: `~/lang_repos/roc/crates/`
