# Ori

**Code That Proves Itself**

General-purpose, expression-based language with strict static typing, type inference, and mandatory testing. Ori enforces code integrity — if it compiles, it has tests; if it has tests, they pass; if you change it, you'll know what broke.

## Development Commands

**Primary commands** (run everything, including LLVM):

| Command | Description |
|---------|-------------|
| `./test-all` | Run ALL tests: Rust + Ori spec + LLVM |
| `./clippy-all` | Run clippy on ALL crates: workspace + LLVM |
| `./fmt-all` | Format ALL Rust code: workspace + LLVM |
| `./build-all` | Build ALL crates: workspace + LLVM |

**Individual test commands:**

| Command | Description |
|---------|-------------|
| `cargo t` | Run Rust unit tests only |
| `cargo st` | Run Ori language tests (`tests/`) |
| `cargo st tests/spec/capabilities/` | Run specific Ori test directory |
| `cargo st tests/spec/types/primitives.ori` | Run specific Ori test file |
| `./llvm-test` | Run LLVM Rust unit tests (Docker) |

**Build and check commands** (workspace only, excludes LLVM):

| Command | Description |
|---------|-------------|
| `cargo c` | Check all crates (fast compile check) |
| `cargo cl` | Run clippy on all crates |
| `cargo b` | Build all crates |
| `cargo fmt` | Format all crates |
| `./llvm-build` | Build LLVM crate |
| `./llvm-clippy` | Run clippy on LLVM crate |

**Always run `./test-all` after making compiler changes to verify everything works.**

## Design Philosophy

**Code that proves itself.** Every function tested. Every change traced. Every effect explicit.

Ori makes verification automatic — the compiler enforces what discipline alone cannot.

### The Four Pillars

1. **Mandatory Verification**
   - Every function requires tests or it doesn't compile
   - Tests are bound to functions (`@test tests @target`)
   - Contracts (`pre_check:`/`post_check:`) enforce invariants
   - The compiler refuses to produce code it can't verify

2. **Dependency-Aware Integrity**
   - Tests are in the dependency graph, not external
   - Change a function → its tests run
   - Change a function → callers' tests run too
   - Fast feedback because only affected tests execute
   - **Causality Tracking**: know impact before changing, trace failures after

3. **Explicit Effects**
   - Capabilities declare what a function can do (`uses Http`)
   - No hidden side effects
   - Mocking is trivial (`with Http = MockHttp(...) in`)
   - Tests are fast because everything is injectable

4. **ARC-Safe by Design**
   - Memory managed via ARC (no tracing GC, no borrow checker)
   - Closures capture by value — no reference cycles through environments
   - No shared mutable references — single ownership of mutable data
   - Value semantics by default — reference types are explicit
   - See `spec/15-memory-model.md` for invariants that new features must maintain

### The Virtuous Cycle

```
Capabilities make mocking easy
    → Tests are fast
        → Dependency-aware testing is practical
            → Mandatory testing isn't painful
                → Code integrity is enforced
                    → Code that works, stays working
```

### Lean Core, Rich Libraries

The compiler implements only constructs that require special syntax or static analysis. Everything else belongs in the standard library.

**Compiler patterns** (require special handling):
- `run`, `try`, `match` — sequential evaluation with bindings
- `recurse` — self-referential recursion with `self()`
- `parallel`, `spawn`, `timeout` — concurrency primitives
- `cache`, `with` — capability-aware resource management

**Stdlib methods** (no special syntax needed):
- `map`, `filter`, `fold`, `find` — data transformation on collections
- `retry`, `validate` — resilience and validation logic

This separation keeps the compiler focused and maintainable while allowing the standard library to evolve independently. New data transformations don't require compiler changes.

## Core Features

- **Patterns over loops**: `recurse`, `parallel`, `for` patterns; `map`, `filter`, `fold` as stdlib methods
- **Mandatory testing**: every function requires tests or compilation fails
- **Dependency-aware tests**: tests bound to functions, run on change propagation
- **Causality tracking**: `ori impact` shows blast radius, `ori why` traces failures to source
- **Contracts**: `pre_check:`/`post_check:` for function invariants
- **Explicit oris**: `@` functions, `$` config
- **No null/exceptions**: `Option<T>` for optional, `Result<T, E>` for fallible
- **Capabilities for effects**: `uses Http`, `uses Async` — explicit, injectable, testable
- **Zero-config formatting**: one canonical style, enforced

## Key Paths

| Path | Purpose |
|------|---------|
| `compiler/oric/` | Rust compiler (lexer, parser, types, interpreter, LLVM backend) |
| `docs/ori_lang/0.1-alpha/spec/` | **Formal specification** (authoritative) |
| `docs/ori_lang/proposals/` | Proposals and decision rationale |
| `library/std/` | Standard library |
| `tests/spec/` | Specification conformance tests |
| `plans/roadmap/` | **Compiler roadmap** (phases, tracking, priorities) |

## Roadmap

The compiler development roadmap is in `plans/roadmap/`. Key files:

| File | Purpose |
|------|---------|
| `00-overview.md` | Phase overview, tiers, dependency graph, milestones |
| `plan.md` | Execution plan, phase order, how to use |
| `priority-and-tracking.md` | **Current status**, test results, immediate priorities |
| `phase-XX-*.md` | Individual phase details and checklists |

**22 phases across 8 tiers:**
- Tier 1 (1-5): Foundation — types, inference, traits, modules, type declarations
- Tier 2 (6-7): Capabilities & stdlib
- Tier 3 (8-10): Core patterns — run/try/match, control flow
- Tier 4 (11-12): FFI & interop
- Tier 5 (13-15): Language completion — conditional compilation, testing, syntax
- Tier 6 (16-17): Async & concurrency
- Tier 7 (18-19): Advanced types — const generics, existential types
- Tier 8 (20-22): Advanced features — reflection, **LLVM backend**, tooling

## Reference Repos

External language repos for reference when implementing compiler features:

| Path | Purpose |
|------|---------|
| `~/lang_repos/rust/` | Rust compiler - diagnostics, suggestions, applicability levels |
| `~/lang_repos/golang/` | Go compiler - error handling, go fix tool |
| `~/lang_repos/typescript/` | TypeScript compiler - diagnostics, code fixes, quick fixes |
| `~/lang_repos/zig/` | Zig compiler - explicit errors, comptime, no hidden control flow |
| `~/lang_repos/gleam/` | Gleam compiler - Result types, functional patterns, Rust-based |
| `~/lang_repos/elm/` | Elm compiler - excellent error messages, Haskell-based |
| `~/lang_repos/roc/` | Roc compiler - effects/abilities system, modern functional |

These are shallow clones. To update: `cd ~/lang_repos/<name> && git pull --depth 1`

**Key Rust files** (diagnostics/suggestions):
- `compiler/rustc_errors/src/lib.rs` - Core diagnostic types, `CodeSuggestion`, `Substitution`
- `compiler/rustc_errors/src/diagnostic.rs` - `Diag`, suggestion methods
- `compiler/rustc_errors/src/json.rs` - JSON serialization for machine consumption
- `compiler/rustc_lint_defs/src/lib.rs` - `Applicability` enum (MachineApplicable, MaybeIncorrect, etc.)

**Key Go files** (diagnostics/fixes):
- `src/cmd/compile/internal/base/print.go` - Compiler error queuing and flushing
- `src/go/types/errors.go` - Type-checker multi-part error building
- `src/internal/types/errors/codes.go` - Error code registry (100+ codes)
- `src/cmd/vendor/golang.org/x/tools/go/analysis/diagnostic.go` - `Diagnostic`, `SuggestedFix`, `TextEdit`
- `src/cmd/vendor/golang.org/x/tools/go/analysis/analysis.go` - `Analyzer`, `Pass` definitions
- `src/internal/analysis/driverutil/fix.go` - Three-way merge for fix application
- `src/cmd/fix/main.go` - `go fix` tool entry point
- `src/cmd/vet/main.go` - `go vet` tool entry point
- `src/cmd/vendor/golang.org/x/tools/go/analysis/passes/modernize/` - Modern fix examples

**Key TypeScript files** (diagnostics/code fixes):
- `src/compiler/types.ts` - `Diagnostic`, `DiagnosticCategory`, `CodeFixAction` types
- `src/compiler/diagnosticMessages.json` - All diagnostic message definitions
- `src/services/codeFixProvider.ts` - Registration system, `errorCodeToFixes` multimap
- `src/services/textChanges.ts` - `ChangeTracker` for building edits
- `src/services/types.ts` - `CodeFixRegistration`, `CodeFixContext` interfaces
- `src/services/services.ts` - LSP entry points (`getCodeFixesAtPosition`)
- `src/services/codefixes/*.ts` - 73 individual fix implementations

**Key Zig files** (explicit errors, comptime):
- `src/Compilation.zig` - Main compilation driver, error aggregation
- `src/Sema.zig` - Semantic analysis, type checking
- `src/Type.zig` - Type representation and operations
- `src/Value.zig` - Compile-time value representation
- `src/InternPool.zig` - Interned types and values (memory efficiency)
- `src/Zcu.zig` - Zig Compilation Unit, module management
- `src/main.zig` - CLI entry point, error formatting

**Key Gleam files** (Result types, diagnostics):
- `compiler-core/src/error.rs` - Main error type, formatting, `wrap_format!` macro
- `compiler-core/src/diagnostic.rs` - `Diagnostic`, `Label`, `Location` using codespan
- `compiler-core/src/warning.rs` - Warning types and formatting
- `compiler-core/src/type_/error.rs` - Type error details, hints
- `compiler-core/src/type_.rs` - Type representation, unification
- `compiler-core/src/analyse.rs` - Semantic analysis
- `compiler-core/src/exhaustiveness.rs` - Pattern match exhaustiveness checking

**Key Elm files** (error messages, Haskell):
- `compiler/src/Reporting/Error.hs` - Top-level error type, routing to specific modules
- `compiler/src/Reporting/Error/Type.hs` - Type mismatch messages (famous for clarity)
- `compiler/src/Reporting/Error/Syntax.hs` - Parse error messages with suggestions
- `compiler/src/Reporting/Error/Canonicalize.hs` - Name resolution errors
- `compiler/src/Reporting/Suggest.hs` - "Did you mean?" suggestions
- `compiler/src/Reporting/Doc.hs` - Pretty printing document combinators
- `compiler/src/Reporting/Render/` - Output rendering (terminal, JSON)
- `compiler/src/Type/Solve.hs` - Constraint solving, unification

**Key Roc files** (effects/abilities, error reporting):
- `crates/reporting/src/report.rs` - `RocDocAllocator`, pretty printing, cycle display
- `crates/reporting/src/error/type.rs` - Type error formatting, unification failures
- `crates/reporting/src/error/canonicalize.rs` - Name resolution error messages
- `crates/reporting/src/error/parse.rs` - Parse error formatting
- `crates/compiler/solve/src/` - Constraint solving, abilities
- `crates/compiler/types/src/` - Type representation
- `crates/compiler/can/src/` - Canonicalization (name resolution)
- `crates/compiler/constrain/src/` - Constraint generation
- `crates/compiler/problem/src/` - Problem types (errors/warnings)

## CLI

| Command | Action |
|---------|--------|
| `ori run file.ori` | Run program |
| `ori test` | Run all tests (parallel) |
| `ori check file.ori` | Check test coverage |
| `ori fmt src/` | Format files |

## Files & Tests

- `.ori` source, `.test.ori` tests in `_test/` subdirectory
- Targeted test: `@test_name tests @target () -> void = run(...)`
- Free-floating test: `@test_name () -> void = run(...)`
- Private access via `::` prefix; every function (except `@main`) requires tests

## Program Entry

- `@main () -> void` — basic entry, exit code 0
- `@main () -> int` — return exit code
- `@main (args: [str]) -> void` — with command-line args
- `@main (args: [str]) -> int` — args and exit code
- `args` contains arguments only (not program name)

---

## ⚠️ IMPORTANT: This Is NOT The Specification

**The syntax reference below is a QUICK REFERENCE ONLY — not the authoritative specification.**

| What you want | Where to look |
|---------------|---------------|
| **Authoritative language spec** | `docs/ori_lang/0.1-alpha/spec/` |
| **Decision rationale** | `docs/ori_lang/proposals/` |
| **Quick syntax reminder** | The reference below |

**If this quick reference contradicts the spec, the spec is correct.** Always consult the spec for:
- Compiler/language implementation work
- Edge cases and exact semantics
- Grammar productions and formal definitions
- Any ambiguity in behavior

The reference below is a condensed cheat sheet for writing Ori code quickly.

---

## Ori Quick Reference

### Declarations

**Functions**
- `@name (param: Type) -> ReturnType = expression`
- `pub @name ...` — public visibility
- `@name<T> (x: T) -> T` — generic
- `@name<T: Trait> (x: T) -> T` — constrained generic
- `@name<T: A + B> (x: T) -> T` — multiple bounds
- `@name<T> (...) -> T where T: Clone, U: Default = ...` — where clause
- `@name (...) -> Type uses Capability = ...` — capability
- `@name (x: int = 10) -> int` — default parameter value
- `@name (a: int, b: int = 0, c: int = 0) -> int` — multiple defaults (any position)
- Default expressions evaluated at call time, cannot reference other parameters

**Config Variables** (compile-time constants)
- `$name = value`
- `pub $name = value` — public
- `$name = $other * 2` — can reference other config
- `use './config' { $timeout }` — import config

**Const Functions** (compile-time evaluation)
- `$name (param: Type) -> ReturnType = expression`
- `$square (x: int) -> int = x * x`
- `$factorial (n: int) -> int = if n <= 1 then 1 else n * $factorial(n: n - 1)`
- Must be pure: no capabilities, no I/O, no mutable bindings
- Called with constant args → evaluated at compile time
- Called with runtime args → evaluated at runtime

**Type Definitions**
- `type Name = { field: Type }` — struct
- `type Name = A | B | C(field: Type)` — sum type
- `type Name = ExistingType` — newtype
- `type Name<T> = ...` — generic
- `#[derive(Eq, Clone)] type Name = ...` — derive
- `pub type Name = ...` — public

**Traits**
- `trait Name { @method (self) -> Type }` — required method
- `trait Name { @method (self) -> Type = expr }` — default impl
- `trait Name { type Item }` — associated type
- `trait Child: Parent { ... }` — inheritance

**Implementations**
- `impl Type { @method (self) -> Type = ... }` — inherent
- `impl Trait for Type { ... }` — trait impl
- `impl<T: Bound> Trait for Container<T> { ... }` — generic
- `self` — instance in methods; `Self` — implementing type

**Tests**
- `@test_name tests @target () -> void = run(...)` — targeted test
- `@test_name () -> void = run(...)` — free-floating test
- `@test_name tests @a tests @b () -> void = ...` — multiple targets
- `#[skip("reason")] @test_name ...` — skipped test
- `#[compile_fail("error")] @test_name ...` — compile-fail test
- `#[fail("error")] @test_name ...` — expected failure test

### Types

**Primitives**: `int` (64-bit signed), `float` (64-bit IEEE 754), `bool`, `str` (UTF-8), `char`, `byte`, `void`, `Never`
**Special**: `Duration` (`30s`, `100ms`), `Size` (`4kb`, `10mb`)
**Collections**: `[T]` list, `{K: V}` map, `Set<T>` set
**Compound**: `(T, U)` tuple, `()` unit, `(T) -> U` function, `dyn Trait` trait object
**Generic**: `Option<T>`, `Result<T, E>`, `Range<T>`, `Channel<T>`, `Ordering`
**No implicit conversions**: use `int(x)`, `float(x)`, `str(x)` explicitly
**Integer overflow**: panics (use `std.math` for wrapping/saturating alternatives)
**String indexing**: `str[i]` returns single codepoint as `str`

### Literals

- **Integer**: `42`, `1_000_000`, `0xFF` (hex)
- **Float**: `3.14`, `2.5e-8`
- **String**: `"hello"`, `"line1\nline2"` (escapes: `\\`, `\"`, `\n`, `\t`, `\r`)
- **Char**: `'a'`, `'\n'`, `'λ'` (escapes: `\\`, `\'`, `\n`, `\t`, `\r`, `\0`)
- **Bool**: `true`, `false`
- **Duration**: `100ms`, `30s`, `5m`, `2h`
- **Size**: `1024b`, `4kb`, `10mb`, `2gb`
- **List**: `[]`, `[1, 2, 3]`
- **Map**: `{}`, `{"key": value}`
- **Struct**: `Point { x: 0, y: 0 }`, `Point { x, y }` (shorthand)

### Operators (by precedence, highest first)

1. `.` `[]` `()` `?` — access, call, propagate
2. `!` `-` `~` — unary not, negate, bitwise not
3. `*` `/` `%` `div` — multiply, divide, modulo, floor div
4. `+` `-` — add/concat, subtract
5. `<<` `>>` — left shift, right shift
6. `..` `..=` — exclusive range, inclusive range
7. `<` `>` `<=` `>=` — comparison
8. `==` `!=` — equality
9. `&` — bitwise and
10. `^` — bitwise xor
11. `|` — bitwise or
12. `&&` — logical and (short-circuit)
13. `||` — logical or (short-circuit)
14. `??` — coalesce (None/Err to default)

### Expressions

**Conditionals**
- `if cond then expr else expr`
- `if cond then expr else if cond then expr else expr`
- `if cond then expr` — no else, result type is `void`

**Bindings**
- `let x = value` — immutable
- `let mut x = value` — mutable
- `let x: Type = value` — annotated
- `let x = value` then `let x = x + 1` — shadowing allowed
- `let { x, y } = point` — struct destructure
- `let { x: px, y: py } = point` — destructure with rename
- `let { position: { x, y } } = entity` — nested destructure
- `let (a, b) = tuple` — tuple destructure
- `let [head, ..tail] = list` — list destructure

**Indexing**
- `list[0]`, `list[# - 1]` — `#` is length inside brackets (panics on out-of-bounds)
- `str[0]` — returns single-codepoint `str` (panics on out-of-bounds)
- `map["key"]` — returns `Option<V>` (`None` if key missing)

**Access**
- `value.field`, `value.method()`, `value.method(arg: value)`
- Named arguments required for direct calls: `print(msg: "Hello")`, `len(collection: items)`, `fetch_user(id: 1)`
- Positional allowed for type conversions: `int(x)`, `float(x)`, `str(x)`, `byte(x)`
- Positional allowed for function variable calls: `let f = x -> x + 1; f(5)` (param names unknowable)
- Evaluation: left-to-right, arguments in written order (not parameter order)
- Formatting: width-based (inline if fits, stack if not):
  ```
  // Inline
  send_email(to: a, subject: b, body: c)

  // Stacked (exceeds line width)
  send_email(
      to: recipient_address,
      subject: email_subject,
      body: email_content,
  )
  ```

**Lambdas**
- `x -> x + 1` — single param
- `(a, b) -> a + b` — multiple params
- `() -> 42` — no params
- `(x: int) -> int = x * 2` — typed lambda with explicit signature
- Capture by value: lambdas snapshot outer variables, cannot mutate outer scope

**Loops**
- `for item in items do expr` — imperative
- `for x in items yield x * 2` — collect
- `for x in items if x > 0 yield x` — with guard
- `loop(expr)` with `break`, `continue`
- `break value` — exit loop with value
- `continue` — skip iteration (in `for...yield`: skip element)
- `continue value` — use value for this iteration (in `for...yield`)

**Labeled Loops**
- `loop:name(...)` — labeled loop
- `for:name x in items do ...` — labeled for
- `break:name` — break outer loop
- `break:name value` — break outer loop with value
- `continue:name` — continue outer loop

### Patterns

Patterns are compiler constructs with special syntax. Three categories:

**function_seq** — Sequential expressions (order matters)
- `run(let x = a, let y = b, result)`
- `try(let x = fallible()?, Ok(x))`
- `match(value, Pattern -> expr, _ -> default)`

**function_exp** — Named expressions (`name: expr`)
- `recurse(condition: base_case, base: value, step: self(...), memo: true, parallel: threshold)`
- `parallel(tasks: [...], max_concurrent: n, timeout: duration)` → `[Result<T, E>]`
- `spawn(tasks: [...], max_concurrent: n)` → `void` (fire and forget)
- `timeout(op: expr, after: 5s)`
- `cache(key: k, op: expr, ttl: 5m)`
- `with(acquire: expr, use: r -> expr, release: r -> expr)`
- `for(over: items, match: pattern, default: fallback)`
- `catch(expr: expression)` — catch panics, returns `Result<T, str>`

**function_val** — Type conversion functions (positional allowed)
- `int(x)`, `float(x)`, `str(x)`, `byte(x)`

**Stdlib methods** (not compiler patterns — use method call syntax):
- `items.map(transform: fn)` → `[U]`
- `items.filter(predicate: fn)` → `[T]`
- `items.fold(initial: val, op: fn)` → `U`
- `items.find(where: fn)` → `Option<T>`
- `range.collect()` → `[T]`
- `retry(op: fn, attempts: n, backoff: strategy)` — in `std.resilience`
- `validate(rules: [...], value: v)` — in `std.validate`

**Match patterns**
- `42` — literal
- `x` — binding
- `_` — wildcard
- `Some(x)` — variant
- `{ x, y }` — struct
- `[a, b, ..rest]` — list
- `1..10` — range
- `A | B` — or-pattern
- `x @ pat` — at-pattern
- `x.match(guard_expr)` — guard

### Imports

**Relative (local files)** — path in quotes, relative to current file:
- `use './math' { add, subtract }` — same directory
- `use '../utils' { helper }` — parent directory
- `use './http/client' { get }` — subdirectory

**Module (stdlib/packages)** — dot-separated, no quotes:
- `use std.math { sqrt, abs }` — standard library
- `use std.time { Duration }` — standard library

**Private imports** — `::` prefix for non-public items:
- `use './math' { ::internal_helper }` — explicit private access
- `use '../utils' { pub_fn, ::priv_fn }` — mixed

**Aliases and re-exports**:
- `use './math' { add as plus }` — with alias
- `use std.net.http as http` — module alias
- `pub use './internal' { Widget }` — re-export

**Extension imports** — bring trait extension methods into scope:
- `extension std.iter.extensions { Iterator.count, Iterator.last }`
- `extension './my_extensions' { Iterator.sum }` — local extensions

**Extension definitions** — add methods to existing traits:
- `extend Iterator { @count (self) -> int = ... }` — define extension
- `extend Iterator where Self.Item: Add { @sum (self) -> Self.Item = ... }` — constrained

### Capabilities

Capabilities track effects and async behavior. Functions must declare required capabilities.

**Declaring capabilities**
- `@fetch (url: str) -> Result<str, Error> uses Http = ...`
- `@save (data: str) -> Result<void, Error> uses FileSystem, Async = ...`

**Providing capabilities** — `with...in` expression:
- `with Http = RealHttp { base_url: "https://api.example.com" } in fetch("/data")`
- `with Http = MockHttp { responses: {...} } in test_fetch()` — for testing

**The Async capability** — replaces `async/await`:
- `uses Async` — function may suspend (non-blocking I/O)
- No `uses Async` — function blocks until complete (synchronous)
- No `.await` expression — suspension declared at function level, not call site
- Concurrency via `parallel(...)` pattern

**Standard capabilities**:
- `Http` — HTTP client (`get`, `post`, `put`, `delete`)
- `FileSystem` — file I/O (`read`, `write`, `exists`, `delete`)
- `Clock` — time (`now`, `today`)
- `Random` — random numbers (`rand_int`, `rand_float`)
- `Cache` — caching (`get`, `set`, `delete`)
- `Print` — standard output (`print`, `println`, `output`, `clear`) — has default
- `Logger` — structured logging (`debug`, `info`, `warn`, `error`)
- `Env` — environment variables (`get`)
- `Async` — marker for functions that may suspend

**Pure functions**: no `uses` clause = no side effects, cannot suspend

### Comments

- `// comment` — line comment (must be on its own line, no inline comments)
- Doc comments use special markers (see below)

**Important:** Inline comments are not allowed. Comments must appear on their own line:

```ori
// This is valid
let x = 42

let y = 42  // This is a syntax error
```

### Doc Comments

- `// #Description` — main description
- `// @param name constraint` — parameter note
- `// @field name description` — struct field
- `// !ErrorCondition: when it happens` — error/panic
- `// >expr -> result` — example

### Formatting Rules (enforced, zero config)

**Indentation**: 4 spaces, no tabs
**Line length**: 100 characters hard limit
**Trailing commas**: always on multi-line

**Spacing**
- Space around binary operators: `a + b`, `x == y`
- Space around arrows: `x -> x + 1`, `-> Type`
- Space after colons: `x: int`, `key: value`
- Space after commas: `f(a, b, c)`
- No space inside parens/brackets: `f(x)`, `[1, 2]`
- Space after `//`: `// comment`

**Named Arguments - Inline vs Stacked**

Inline when ALL conditions met:
- Total call fits in 100 chars
- No single value exceeds ~30 chars
- No complex values (list literals, nested calls with args)

```ori
// Inline - short, simple values
assert_eq(actual: result, expected: 10)
items.map(transform: x -> x * 2)
```

Stack when ANY value is long or complex:

```ori
// Stacked - long list literal
assert_eq(
    actual: open_doors(),
    expected: [1, 4, 9, 16, 25, 36, 49, 64, 81, 100],
)

// Stacked - list literal in args
[1, 2, 3, 4, 5].map(
    transform: x -> x * 2,
)
```

**Other Breaking Rules**
- `run`/`try`: always stack contents (block-like)
- List literals: inline if short, stack if long
- Long signatures: break after `->` or break params
- Long binary expressions: break before operator

**Blank lines**
- One after import block
- One after config block
- One between functions
- No consecutive blank lines
- No trailing/leading blank lines

### Keywords

**Reserved**: `async`, `break`, `continue`, `do`, `else`, `false`, `for`, `if`, `impl`, `in`, `let`, `loop`, `match`, `mut`, `pub`, `self`, `Self`, `then`, `trait`, `true`, `type`, `use`, `uses`, `void`, `where`, `with`, `yield`

**Context-sensitive** (compiler patterns only): `cache`, `catch`, `for`, `parallel`, `recurse`, `run`, `spawn`, `timeout`, `try`, `with`

**Reserved built-in function names** (cannot be used for user-defined functions, but CAN be used as variable names):
`int`, `float`, `str`, `byte`, `len`, `is_empty`, `is_some`, `is_none`, `is_ok`, `is_err`, `assert`, `assert_eq`, `assert_ne`, `assert_some`, `assert_none`, `assert_ok`, `assert_err`, `assert_panics`, `assert_panics_with`, `compare`, `min`, `max`, `print`, `panic`

Built-in names are reserved **in call position only** (`name(`). The same names may be used as variables:
- `let min = 5` — OK, variable binding
- `min(a, b)` — OK, calls built-in function
- `@min (...) -> int = ...` — Error, reserved function name

### Prelude (auto-imported)

**Types**: `Option<T>` (`Some`/`None`), `Result<T, E>` (`Ok`/`Err`), `Error`, `Ordering` (`Less`/`Equal`/`Greater`), `PanicInfo` (`message`, `location`)
**Traits**: `Eq`, `Comparable`, `Hashable`, `Printable`, `Clone`, `Default`

**function_val** (type conversions, positional allowed):
- `int(x)`, `float(x)`, `str(x)`, `byte(x)`

**Built-in functions** (named arguments required):
- `print(msg: str)` → `void`
- `len(collection: T)` → `int`
- `is_empty(collection: T)` → `bool`
- `is_some(option: Option<T>)` → `bool`
- `is_none(option: Option<T>)` → `bool`
- `is_ok(result: Result<T, E>)` → `bool`
- `is_err(result: Result<T, E>)` → `bool`
- `assert(condition: bool)` → `void`
- `assert_eq(actual: T, expected: T)` → `void`
- `assert_ne(actual: T, unexpected: T)` → `void`
- `assert_some(option: Option<T>)` → `void`
- `assert_none(option: Option<T>)` → `void`
- `assert_ok(result: Result<T, E>)` → `void`
- `assert_err(result: Result<T, E>)` → `void`
- `assert_panics(f: () -> void)` → `void` — asserts the thunk panics
- `assert_panics_with(f: () -> void, msg: str)` → `void` — asserts the thunk panics with a specific message
- `panic(msg: str)` → `Never`
- `compare(left: T, right: T)` → `Ordering`
- `min(left: T, right: T)` → smallest value
- `max(left: T, right: T)` → largest value

**Option methods**: `.map(transform: fn)`, `.unwrap_or(default: value)`, `.ok_or(error: value)`, `.and_then(transform: fn)`, `.filter(predicate: fn)`
**Result methods**: `.map(transform: fn)`, `.map_err(transform: fn)`, `.unwrap_or(default: value)`, `.ok()`, `.err()`, `.and_then(transform: fn)`
