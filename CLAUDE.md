# Sigil

## Overview

**What is Sigil?**
- General-purpose programming language built on declarative patterns and mandatory testing
- Designed for AI-first development: explicit, predictable, tooling-friendly
- Expression-based with strict static typing and type inference

**Core Philosophy**
- Patterns as first-class constructs (`map`, `filter`, `fold`, `recurse`, `parallel`)
- Mandatory testing: every function must have tests or compilation fails
- Explicit over implicit: `@` for functions, `$` for config, `.name:` for named args
- One canonical format: zero configuration formatter
- Types document intent; comments add what types cannot express

**Design Principles**
- Context-sensitive keywords: pattern names (`map`, `filter`) usable as identifiers outside patterns
- Named-only pattern args: `.property: value` syntax, never positional
- No semicolons: newlines separate statements, commas separate pattern elements
- No null: use `Option<T>` (`Some`/`None`) for optional values
- No exceptions: use `Result<T, E>` (`Ok`/`Err`) for fallible operations

## Project Structure

```
sigil/
├── compiler/sigilc/src/   # Rust compiler
│   ├── lexer/             # Tokenizer (logos)
│   ├── parser/            # Recursive descent
│   ├── ast/               # AST definitions
│   ├── types/             # Type checker
│   ├── eval/              # Tree-walking interpreter
│   └── codegen/           # C code generator
├── library/std/           # Standard library (Sigil)
├── docs/sigil_lang/       # Language documentation
│   └── 0.1-alpha/         # Current version
│       ├── spec/          # Formal specification
│       ├── design/        # Design rationale
│       └── modules/       # Stdlib API docs
├── tests/
│   ├── run-pass/          # Should compile and run
│   └── compile-fail/      # Should fail to compile
└── examples/              # Example programs
```

## CLI Commands

- `sigil run file.si` — run program
- `sigil build file.si` — compile to C
- `sigil emit file.si` — emit C code
- `sigil test` — run all tests (parallel)
- `sigil test file.test.si` — run specific tests
- `sigil check file.si` — check test coverage
- `sigil fmt src/` — format files
- `sigil fmt --check src/` — check formatting (CI)

## Test Convention

- Test files: `_test/` subdirectory, named `*.test.si`
- Test declaration: `@test_name tests @target () -> void = run(...)`
- Test files can access private items from parent module
- Every function (except `@main`) requires at least one test

## Current Implementation Status

- Lexer, parser, AST: complete
- Type checker: complete
- Tree-walking interpreter: complete
- C code generator: basic
- Test runner: parallel execution, mandatory coverage
- Pattern system: named property syntax, memoization

---

## Sigil Coding Rules

### Declarations

**Functions**
- `@name (param: Type) -> ReturnType = expression`
- `pub @name ...` — public visibility
- `@name<T> (x: T) -> T` — generic
- `@name<T: Trait> (x: T) -> T` — constrained generic
- `@name<T: A + B> (x: T) -> T` — multiple bounds
- `@name (...) -> Type uses Capability = ...` — capability

**Config Variables**
- `$name = value`
- `pub $name = value` — public

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
- `trait Child: Parent { ... }` — inheritance

**Implementations**
- `impl Type { @method (self) -> Type = ... }` — inherent
- `impl Trait for Type { ... }` — trait impl
- `impl<T: Bound> Trait for Container<T> { ... }` — generic

**Tests**
- `@test_name tests @target () -> void = run(...)`
- `@test_name tests @a tests @b () -> void = ...` — multiple targets
- `#[skip("reason")] @test_name tests @target ...` — skipped test

### Types

**Primitives**: `int`, `float`, `bool`, `str`, `char`, `byte`, `void`, `Never`
**Special**: `Duration` (`30s`, `100ms`), `Size` (`4kb`, `10mb`)
**Collections**: `[T]` list, `{K: V}` map, `Set<T>` set
**Compound**: `(T, U)` tuple, `()` unit, `(T) -> U` function
**Generic**: `Option<T>`, `Result<T, E>`, `Range<T>`, `Channel<T>`, `Ordering`

### Literals

- **Integer**: `42`, `1_000_000`
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

1. `.` `[]` `()` `.await` `?` — access, call, await, propagate
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
- `let { x, y } = point` — struct destructure
- `let (a, b) = tuple` — tuple destructure
- `let [head, ..tail] = list` — list destructure

**Indexing**
- `list[0]`, `list[# - 1]` — `#` is length inside brackets
- `map["key"]`

**Access**
- `value.field`, `value.method()`, `value.method(arg)`

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

### Patterns (named args only: `.name:`)

**Sequential**
- `run(let x = a, let y = b, result)`

**Error handling**
- `try(let x = fallible()?, Ok(x))`

**Matching**
- `match(value, Pattern -> expr, _ -> default)`

**Data patterns**
- `map(.over: items, .transform: fn)`
- `filter(.over: items, .predicate: fn)`
- `fold(.over: items, .init: val, .op: fn)`
- `find(.over: items, .where: fn)`
- `collect(.range: 0..10, .transform: fn)`
- `recurse(.cond: base_case, .base: val, .step: self(...), .memo: true)`

**Concurrency**
- `parallel(.task1: expr1, .task2: expr2)`
- `timeout(.op: expr, .after: 5s)`
- `retry(.op: expr, .attempts: 3, .backoff: strategy)`

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
- Pattern args: always stack vertically (even single property)
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
**Functions**: `print`, `len`, `str`, `int`, `float`, `compare`, `panic`, `assert`, `assert_eq`
