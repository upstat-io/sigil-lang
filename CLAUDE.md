# Sigil

General-purpose, expression-based language with strict static typing, type inference, and mandatory testing. Designed for AI-first development: explicit, predictable, tooling-friendly.

## Core Concepts

- **Patterns over loops**: `map`, `filter`, `fold`, `recurse`, `parallel` as first-class constructs
- **Mandatory testing**: every function requires tests or compilation fails
- **Explicit sigils**: `@` functions, `$` config, `.name:` named args
- **No null/exceptions**: `Option<T>` for optional, `Result<T, E>` for fallible
- **Capabilities for effects**: `uses Http`, `uses Async` — explicit, injectable, testable
- **Zero-config formatting**: one canonical style, enforced

## Key Paths

| Path | Purpose |
|------|---------|
| `compiler/sigilc/` | Rust compiler (lexer, parser, types, interpreter, codegen) |
| `docs/sigil_lang/0.1-alpha/spec/` | **Formal specification** (authoritative) |
| `docs/sigil_lang/0.1-alpha/design/` | Design rationale |
| `library/std/` | Standard library |
| `tests/spec/` | Specification conformance tests |

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
| `sigil run file.si` | Run program |
| `sigil test` | Run all tests (parallel) |
| `sigil check file.si` | Check test coverage |
| `sigil fmt src/` | Format files |

## Files & Tests

- `.si` source, `.test.si` tests in `_test/` subdirectory
- Targeted test: `@test_name tests @target () -> void = run(...)`
- Free-floating test: `@test_name () -> void = run(...)`
- Private access via `::` prefix; every function (except `@main`) requires tests

---

## ⚠️ IMPORTANT: This Is NOT The Specification

**The syntax reference below is a QUICK REFERENCE ONLY — not the authoritative specification.**

| What you want | Where to look |
|---------------|---------------|
| **Authoritative language spec** | `docs/sigil_lang/0.1-alpha/spec/` |
| **Design rationale & decisions** | `docs/sigil_lang/0.1-alpha/design/` |
| **Quick syntax reminder** | The reference below |

**If this quick reference contradicts the spec, the spec is correct.** Always consult the spec for:
- Compiler/language implementation work
- Edge cases and exact semantics
- Grammar productions and formal definitions
- Any ambiguity in behavior

The reference below is a condensed cheat sheet for writing Sigil code quickly.

---

## Sigil Quick Reference

### Declarations

**Functions**
- `@name (param: Type) -> ReturnType = expression`
- `pub @name ...` — public visibility
- `@name<T> (x: T) -> T` — generic
- `@name<T: Trait> (x: T) -> T` — constrained generic
- `@name<T: A + B> (x: T) -> T` — multiple bounds
- `@name<T> (...) -> T where T: Clone, U: Default = ...` — where clause
- `@name (...) -> Type uses Capability = ...` — capability

**Config Variables** (compile-time constants, must use literals)
- `$name = value`
- `pub $name = value` — public
- `use './config' { $timeout }` — import config

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

**Primitives**: `int`, `float`, `bool`, `str`, `char`, `byte`, `void`, `Never`
**Special**: `Duration` (`30s`, `100ms`), `Size` (`4kb`, `10mb`)
**Collections**: `[T]` list, `{K: V}` map, `Set<T>` set
**Compound**: `(T, U)` tuple, `()` unit, `(T) -> U` function, `dyn Trait` trait object
**Generic**: `Option<T>`, `Result<T, E>`, `Range<T>`, `Channel<T>`, `Ordering`
**No implicit conversions**: use `int(x)`, `float(x)`, `str(x)` explicitly

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
- `value.field`, `value.method()`, `value.method(.arg: value)`
- User-defined function calls: positional for single-arg, named for multi-arg
- function_val (type conversions): positional allowed (`int(x)`, `float(x)`, `str(x)`, `byte(x)`)
- function_exp (core functions): named arguments required
- Named arguments must stack vertically:
  ```
  func(
      .a: 1,
      .b: 2,
  )
  ```

**Lambdas**
- `x -> x + 1` — single param
- `(a, b) -> a + b` — multiple params
- `() -> 42` — no params
- `(x: int) -> int = x * 2` — typed lambda with explicit signature

**Loops**
- `for item in items do expr` — imperative
- `for x in items yield x * 2` — collect
- `for x in items if x > 0 yield x` — with guard
- `loop(expr)` with `break`, `continue`

### Patterns

Patterns are distinct from function calls. Three categories:

**function_seq** — Sequential expressions (order matters)
- `run(let x = a, let y = b, result)`
- `try(let x = fallible()?, Ok(x))`
- `match(value, Pattern -> expr, _ -> default)`

**function_exp** — Named expressions (`.name: expr`, each on own line)
- `map(.over: items, .transform: fn)`
- `filter(.over: items, .predicate: fn)`
- `fold(.over: items, .init: val, .op: fn)`
- `find(.over: items, .where: fn)` or `find(.over: items, .map: fn)` (find_map)
- `collect(.range: 0..10, .transform: fn)`
- `recurse(.cond: base_case, .base: val, .step: self(...), .memo: true, .parallel: threshold)`
- `parallel(.tasks: [...], .max_concurrent: n, .timeout: duration)` → `[Result<T, E>]`
- `spawn(.tasks: [...], .max_concurrent: n)` → `void` (fire and forget)
- `timeout(.op: expr, .after: 5s)`
- `retry(.op: expr, .attempts: 3, .backoff: strategy)`
- `cache(.key: k, .op: expr, .ttl: 5m)`
- `validate(.rules: [...], .then: value)`
- `with(.acquire: expr, .use: r -> expr, .release: r -> expr)`
- `for(.over: items, .match: pattern, .default: fallback)`

**function_val** — Type conversion functions (positional allowed)
- `int(x)`, `float(x)`, `str(x)`, `byte(x)`

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
- `Random` — random numbers (`int`, `float`)
- `Cache` — caching (`get`, `set`, `delete`)
- `Logger` — logging (`debug`, `info`, `warn`, `error`)
- `Env` — environment variables (`get`)
- `Async` — marker for functions that may suspend

**Pure functions**: no `uses` clause = no side effects, cannot suspend

### Comments

- `// comment` — line comment (must be on its own line, no inline comments)
- Doc comments use special markers (see below)

**Important:** Inline comments are not allowed. Comments must appear on their own line:

```sigil
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
- Space after colons: `x: int`, `.key: value`
- Space after commas: `f(a, b, c)`
- No space inside parens/brackets: `f(x)`, `[1, 2]`
- Space after `//`: `// comment`

**Breaking**
- Named params (`.name:`): always stack vertically (even single property)
- List literals: inline, bump brackets and wrap values at column width if too long
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

**Context-sensitive** (patterns only): `cache`, `collect`, `filter`, `find`, `fold`, `map`, `parallel`, `recurse`, `retry`, `run`, `timeout`, `try`, `validate`

**Reserved built-in function names** (cannot be used for user-defined functions, but CAN be used as variable names):
`int`, `float`, `str`, `byte`, `len`, `is_empty`, `is_some`, `is_none`, `is_ok`, `is_err`, `assert`, `assert_eq`, `assert_ne`, `assert_some`, `assert_none`, `assert_ok`, `assert_err`, `assert_panics`, `assert_panics_with`, `compare`, `min`, `max`, `print`, `panic`

Built-in names are reserved **in call position only** (`name(`). The same names may be used as variables:
- `let min = 5` — OK, variable binding
- `min(.left: a, .right: b)` — OK, calls built-in function
- `@min (...) -> int = ...` — Error, reserved function name

### Prelude (auto-imported)

**Types**: `Option<T>` (`Some`/`None`), `Result<T, E>` (`Ok`/`Err`), `Error`, `Ordering` (`Less`/`Equal`/`Greater`)
**Traits**: `Eq`, `Comparable`, `Hashable`, `Printable`, `Clone`, `Default`

**function_val** (type conversions, positional allowed):
- `int(x)`, `float(x)`, `str(x)`, `byte(x)`

**function_exp** (core functions, named arguments required):
- `len(.collection: c)` → `int`
- `is_empty(.collection: c)` → `bool`
- `is_some(.opt: o)` → `bool`
- `is_none(.opt: o)` → `bool`
- `is_ok(.result: r)` → `bool`
- `is_err(.result: r)` → `bool`
- `assert(.cond: b)` → `void`
- `assert_some(.opt: o)` → `void`
- `assert_none(.opt: o)` → `void`
- `assert_ok(.result: r)` → `void`
- `assert_err(.result: r)` → `void`
- `assert_panics(.expr: e)` → `void`
- `print(.msg: s)` → `void`
- `panic(.msg: s)` → `Never`
- `compare(.left: a, .right: b)` → `Ordering`
- `min(.left: a, .right: b)` → smallest value
- `max(.left: a, .right: b)` → largest value
- `assert_eq(.actual: val, .expected: exp)` → `void`
- `assert_ne(.actual: val, .unexpected: other)` → `void`
- `assert_panics_with(.expr: e, .message: msg)` → `void`

**Option methods**: `.map(.transform: fn)`, `.unwrap_or(.default: v)`, `.ok_or(.err: e)`, `.and_then(.then: fn)`, `.filter(.predicate: fn)`
**Result methods**: `.map(.transform: fn)`, `.map_err(.transform: fn)`, `.unwrap_or(.default: v)`, `.ok()`, `.err()`, `.and_then(.then: fn)`
