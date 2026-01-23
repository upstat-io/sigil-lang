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

## CLI

| Command | Action |
|---------|--------|
| `sigil run file.si` | Run program |
| `sigil test` | Run all tests (parallel) |
| `sigil check file.si` | Check test coverage |
| `sigil fmt src/` | Format files |

## Files & Tests

- `.si` source, `.test.si` tests in `_test/` subdirectory
- Test syntax: `@test_name tests @target () -> void = run(...)`
- Private access via `::` prefix; every function (except `@main`) requires tests

---

> **For compiler/language work**: consult `spec/` and `design/` docs.
> **For writing Sigil code**: use reference below.

## Sigil Coding Rules

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
- `@test_name tests @target () -> void = run(...)`
- `@test_name tests @a tests @b () -> void = ...` — multiple targets
- `#[skip("reason")] @test_name tests @target ...` — skipped test
- `// #compile-fail` + `// #error: message` — compile-fail test

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
- `value.field`, `value.method()`, `value.method(arg)`
- Multi-argument calls require named arguments: `func(.a: 1, .b: 2)`
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

Patterns are distinct from function calls. Two categories:

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
- `parallel(.task1: expr1, .task2: expr2)` or `parallel(.tasks: list, .max_concurrent: n)`
- `timeout(.op: expr, .after: 5s)`
- `retry(.op: expr, .attempts: 3, .backoff: strategy)`
- `cache(.key: k, .op: expr, .ttl: 5m)`
- `validate(.rules: [...], .then: value)`
- `with(.acquire: expr, .use: r -> expr, .release: r -> expr)`
- `for(.over: items, .match: pattern, .default: fallback)`

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

- `// comment` — line comment (to end of line)
- Doc comments use special markers (see below)

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

### Prelude (auto-imported)

**Types**: `Option<T>` (`Some`/`None`), `Result<T, E>` (`Ok`/`Err`), `Error`, `Ordering` (`Less`/`Equal`/`Greater`)
**Traits**: `Eq`, `Comparable`, `Hashable`, `Printable`, `Clone`, `Default`
**Functions**: `print`, `len`, `is_empty`, `str`, `int`, `float`, `byte`, `panic`, `is_some`, `is_none`, `is_ok`, `is_err`, `assert`, `assert_some`, `assert_none`, `assert_ok`, `assert_err`, `assert_panics`

**Multi-arg prelude functions** (use named arguments):
- `compare(.left: a, .right: b)` → `Ordering`
- `min(.left: a, .right: b)` → smallest value
- `max(.left: a, .right: b)` → largest value
- `assert_eq(.actual: val, .expected: exp)` → void
- `assert_ne(.actual: val, .unexpected: other)` → void
- `assert_panics_with(.expr: e, .message: msg)` → void

**Option methods**: `.map(fn)`, `.unwrap_or(default)`, `.ok_or(err)`, `.and_then(fn)`, `.filter(pred)`
**Result methods**: `.map(fn)`, `.map_err(fn)`, `.unwrap_or(default)`, `.ok()`, `.err()`, `.and_then(fn)`
