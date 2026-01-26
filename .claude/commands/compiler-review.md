---
description: Analyze the Sigil compiler for DRY/SOLID violations and industry best practices
---

# Code Review: DRY and SOLID Analysis

Analyze the Sigil compiler codebase for violations of documented patterns and industry best practices from major compiler projects (Rust, Go, TypeScript, Zig, Gleam, Elm, Roc).

## Scope

Focus on the compiler crates in `compiler/`:
- `sigilc/` - Main compiler driver, Salsa queries, orchestration
- `sigil_diagnostic/` - Error reporting and diagnostics
- `sigil_eval/` - Tree-walking interpreter
- `sigil_ir/` - Core IR types (AST, spans, no dependencies)
- `sigil_lexer/` - Tokenization
- `sigil_parse/` - Recursive descent parser
- `sigil_patterns/` - Pattern definitions
- `sigil_typeck/` - Type checking
- `sigil_types/` - Type system definitions

## What to Look For

### DRY Violations
- Duplicated code blocks across modules
- Type definitions duplicated instead of re-exported
- Similar patterns that could use shared registries
- Repeated error handling logic
- Copy-pasted struct definitions or enum variants

### SOLID Violations

**S - Single Responsibility**
- Files exceeding 500 lines (target ~300)
- Functions exceeding 100 lines (target <50)
- Modules doing multiple unrelated things

**O - Open/Closed**
- Hard-coded dispatch that should use registry pattern
- Match statements that grow with every new feature
- Missing trait abstractions for extensible systems

**L - Liskov Substitution**
- Trait implementations that behave inconsistently
- Subtypes that violate parent contract expectations

**I - Interface Segregation**
- Large traits that force implementors to define unused methods
- Overly broad APIs

**D - Dependency Inversion**
- Upward dependencies (lower crates depending on higher)
- Expected direction: sigilc → sigil_typeck/eval/patterns → sigil_parse → sigil_lexer → sigil_ir/diagnostic

---

## Cross-Project Patterns

### Function & API Design (from rust-analyzer)

**Config Structs Over Many Parameters**
- Functions with >3-4 parameters should use a config/options struct
- Especially for boolean or optional parameters
- Bad: `fn check(x, verbose: bool, strict: bool, limit: Option<usize>)`
- Good: `fn check(x, opts: CheckOptions)`

**Functions Over Single-Use Objects**
- Avoid "doer" objects that exist only to perform one action
- Bad: `Builder::new().set_x(x).set_y(y).execute()`
- Good: `do_thing(x, y)` or `do_thing(Config { x, y })`

**Push Allocations to Caller**
- If a function needs a collection, let the caller provide it
- Return iterators instead of `Vec` where possible
- Avoid intermediate collections in recursive functions

**Import Ordering**
```rust
// 1. Standard library
use std::collections::HashMap;
// 2. External crates
use salsa::Database;
// 3. Workspace crates
use sigil_ir::Span;
// 4. Local modules
use crate::utils;
```

### Algorithm Complexity (from Zig)

**O(N) vs O(log N) Awareness**
- Flag O(n²) patterns that could be O(n) or O(n log n)
- Linear scans through collections that could use hash lookups
- Repeated lookups that could be cached
- Nested loops over the same data

### Architecture Purity (from Gleam)

**Pure Core Separation**
- Core compilation logic should have no IO
- IO (file reads, network, env vars) belongs in driver/CLI layer
- `sigil_ir`, `sigil_types`, `sigil_typeck` should be pure
- Only `sigilc` CLI should perform IO

**Snapshot Testing**
- Complex output (error messages, IR dumps) should use snapshot tests
- Allows bulk updates when output format changes
- Makes expected output review easier

### Error Severity (from Go)

**Three-Level Error Handling**
- `Result<T, E>` - Recoverable errors (user input, file not found)
- `panic` macro - Programming errors, invariant violations (bug in compiler)
- Unrecoverable with context - Fatal errors that should never happen

**Error Message Conventions**
- Prefix convention for error sources (e.g., "parse:", "typecheck:")
- Consistent capitalization and punctuation
- Include context: what was being done when error occurred

### Variable Hygiene (from Elm)

**Shadowing Awareness**
- Variable shadowing can hide bugs during refactoring
- Each shadow has ~5% chance of causing confusion per edit
- Consider unique names over shadowing, especially for important bindings
- Shadowing is sometimes appropriate (e.g., `let x = transform(x)`)

### Incremental Complexity (from Roc)

**N+1 Feature Development**
- New features should be incremental additions, not giant leaps
- Each change should be reviewable in isolation
- Avoid PRs that touch >10 files for a single feature
- Break large features into smaller, mergeable chunks

---

## Sigil-Specific Patterns

### Salsa Compatibility

**Query Type Requirements**
- Types in query signatures missing required derives: `Clone, Eq, PartialEq, Hash, Debug`
- `Arc<Mutex<T>>` or `Arc<RwLock<T>>` in Salsa-tracked types
- Function pointers or trait objects in query signatures
- Side effects in Salsa queries (should use event logging)
- Non-deterministic query implementations

### Memory Management

**Arena Allocation**
- `Box<Expr>` instead of `ExprArena` + `ExprId`
- Scattered heap allocations for AST nodes
- Excessive cloning of IR structures

**Interning**
- `String` for identifiers instead of `Name` (interned)
- String comparisons where interned ID comparison would work
- `(String, String)` tuples instead of `MethodKey`

**ID-Based References**
- Raw integers where newtypes should be used (`ExprId`, `Name`)
- Type aliases instead of newtypes: `type ExprId = u32;`

### Builder & RAII Patterns

**Builder Pattern**
- Complex struct construction without builders
- Should use: `TypeCheckerBuilder`, `EvaluatorBuilder`

**RAII Scope Guards**
- Manual save/restore of context (capabilities, impl Self type)
- Should use: `with_capability_scope()`, `with_impl_scope()`

### Registry Pattern

**Missing Registry Usage**
- Hard-coded pattern dispatch instead of `PatternRegistry`
- Hard-coded method dispatch instead of `MethodDispatcher`
- Hard-coded operator handling instead of operator registry
- New cases requiring core code modification

---

## Code Quality

### Clippy Compliance
- `#[allow(clippy::...)]` attributes (NEVER allowed - fix the issue)
- `#[expect(...)]` attributes (same rule)
- Unchecked conversions: `n as i32` instead of `i32::try_from(n)`
- `unwrap()` on user input (should use Result)

### Iteration Patterns
- Indexing in loops instead of iterators
- Bounds checks on every iteration
- Consider `rustc_hash::FxHashMap` for hot paths

### Documentation
- Public items without documentation
- Modules without module-level doc comments
- Comments explaining "what" instead of "why"
- Banner comments (e.g., `// ====`, `// ----`) — remove and use module docs or item docs instead

### Testing Organization

**Hybrid Approach**
- Inline tests exceeding ~200 lines (should be in `tests/` subdirectory)
- Comprehensive test suites not in separate files
- Missing test coverage: happy path, edge cases, error conditions

### Error Handling

**Result vs Panic**
- `panic` macro on recoverable errors (user input, file I/O)
- `unwrap()` where `?` or proper error handling needed
- Missing `#[cold]` on error factory functions

### Diagnostic Quality

**Error Messages**
- Terse or cryptic error messages
- Missing "did you mean?" suggestions
- Inconsistent error message style across similar errors
- Missing error codes

**Error Recovery**
- Early bailout on first error instead of accumulating
- Missing synchronization points for parser recovery

---

## Review Scale (from rust-analyzer)

Apply different scrutiny levels based on change scope:

**Category 1: Internal Changes** (single module, no API changes)
- Works for happy case
- Has tests
- Doesn't panic on unhappy case

**Category 2: API Changes** (new public functions, changed signatures)
- API design matters more than implementation
- Consider future extensibility
- Minimize changed lines

**Category 3: New Dependencies** (between crates or external)
- Rare, requires careful consideration
- Impact on compile times
- Maintenance burden

---

## Over-Engineering Watch

Patterns that are good in moderation but can be taken too far:

### Static vs Dynamic Dispatch

**When to prefer enums over `dyn Trait`:**
- Small, fixed set of variants (e.g., built-in patterns like `run`/`try`/`match`)
- Not extended at runtime
- Language-defined constructs that users cannot add to

Enum benefits: exhaustiveness checking, static dispatch, better inlining, clearer code navigation (jump-to-definition works).

**When `dyn Trait` is appropriate:**
- User-extensible systems (user-defined methods)
- Plugin architectures
- When users can add entries

**If dynamic dispatch is needed, prefer cheaper options:**
- `&dyn Trait` - borrowed, no refcount
- `Box<dyn Trait>` - owned, no atomic ops
- `Arc<dyn Trait>` - atomic refcount on every clone/drop, only when shared ownership required

**Flag:** `Arc<dyn T>` for fixed, compile-time-known sets. Also flag `Arc<dyn T>` where `&dyn T` or `Box<dyn T>` would suffice.

### Registry Granularity

**Registries make sense for:**
- User-defined methods (users create them)
- Plugin systems
- Things that genuinely vary per-project

**Simple match may be better for:**
- Built-in patterns (`run`, `try`, `parallel`) - these won't change at runtime
- Built-in operators - fixed set, compiler can optimize match
- Core language constructs

**Flag:** Registry lookup for things that could be a simple, exhaustiveness-checked match.

### Line Count as Smell, Not Rule

**Line count depends on "why" the file is long:**
- 600 lines handling one cohesive concept → keep it together
- 600 lines handling three concepts that evolved together → split it
- Rustc has many 1000+ line files that are perfectly maintainable

**The real question:** "Does this file have one clear purpose?" not "Is it under 300 lines?"

**Flag as smell (investigate, don't auto-split):**
- Files over 500 lines → check if multiple concepts are entangled
- Files split purely to meet line targets → check if related code is now scattered
- Many small files with heavy cross-imports → may indicate over-splitting

### Builder Pattern Overhead

**Builders are valuable when:**
- Many optional parameters with complex defaults
- Construction requires validation
- Fluent API improves readability

**Simple construction may be better when:**
- Few parameters, most required
- `Default` + struct update syntax works: `Foo { field: val, ..Default::default() }`
- The "builder" just sets fields then calls `build()`

**Flag:** Builders that add ceremony without enabling anything a plain struct couldn't do.

### RAII Guard Tradeoffs

**RAII guards are idiomatic Rust when:**
- Context change is short-lived and lexically scoped
- Early returns need automatic cleanup
- The pattern is well-established (e.g., `with_capability_scope`)

**Explicit parameters have their own cost:**
- Every function signature gets polluted with context
- Threading context through many layers adds noise
- Changes to context shape require updating many signatures

**The real question:** Is the scope clear and lexical?
- Yes → RAII is idiomatic, use it
- Unclear or long-lived → explicit parameters are safer

**Flag:** RAII guards where the scope boundary is unclear or spans multiple call sites.

### Suggesting Simplification

**The review can recommend undoing abstractions.** If code was over-refactored, suggest consolidating back:

- Inline single-use helper functions that obscure rather than clarify
- Collapse over-split modules back together when they have heavy cross-dependencies
- Replace registry/trait indirection with simple match for fixed sets
- Remove builders that just set fields and call `build()`
- Merge scattered small files back into cohesive units
- Replace `Arc<dyn Trait>` with enum when the set is fixed and compile-time known

**Be careful:**
- Don't suggest simplification if the abstraction enables testing, mocking, or future extension
- Consider churn cost — small gains may not justify touching many files
- Check if the pattern is used consistently elsewhere (don't create inconsistency)
- Ask "why was this abstracted?" before suggesting removal — there may be history

**Phrasing:** "Consider simplifying by..." or "This abstraction may not be paying for itself—suggest inlining..."

**The bar:** Does the abstraction make the code easier to understand and change, or harder? If harder AND the simplification is low-risk, suggest removing it.

### Absolute Rules

**Rules that should have escape hatches:**
- "Never use `#[allow]`" - Sometimes clippy is wrong, or you're mid-refactor. Require a comment explaining why.
- "Always use Result" - Sometimes `unwrap()` on internal invariants is correct (with a comment).
- "No files over X lines" - Cohesion matters more than line count.

**Flag:** Contortions to satisfy absolute rules when a pragmatic exception would be cleaner.

---

## Output Format

For each finding, provide:
1. **Location**: File path and line numbers
2. **Category**: DRY / SOLID / API-Design / Algorithm / Purity / Errors / Salsa / Memory / Registry / Style / Testing / Diagnostics / Over-Engineering
3. **Description**: What the issue is
4. **Severity**: Low / Medium / High
5. **Suggestion**: How to refactor (reference existing patterns in codebase or industry examples)

**Note on Over-Engineering:** When flagging potential over-engineering, explain the tradeoff. The goal is pragmatic code, not pattern purity. Sometimes the "wrong" pattern is the right choice for the specific situation.

Prioritize findings by severity and impact on maintainability.

**References:**
- Sigil guidelines: `docs/compiler/design/appendices/E-coding-guidelines.md`
- rust-analyzer style: `~/lang_repos/rust/src/tools/rust-analyzer/docs/book/src/contributing/style.md`
- Go compiler: `~/lang_repos/golang/src/cmd/compile/README.md`
- Gleam contributing: `~/lang_repos/gleam/CONTRIBUTING.md`
