**Fix every issue encountered. No "unrelated" or "pre-existing" exceptions.**

**TDD for bugs**: Issue found + tests pass → write test for correct behavior (must fail) → fix code → test passes unchanged

---

# Ori — Code That Proves Itself

Expression-based language with strict static typing, type inference, mandatory testing. If it compiles, it has tests; if it has tests, they pass.

## Commands

**Primary** (includes LLVM): `./test-all`, `./clippy-all`, `./fmt-all`, `./build-all`
**Tests**: `cargo t` (Rust), `cargo st` (Ori), `cargo st tests/spec/path/` (specific), `./llvm-test`
**Build**: `cargo c` (check), `cargo cl` (clippy), `cargo b`, `cargo fmt`, `./llvm-build`, `./llvm-clippy`

**Always run `./test-all` after compiler changes.**

## Key Paths

- `compiler/oric/` — Rust compiler (lexer, parser, types, interpreter, LLVM)
- `docs/ori_lang/0.1-alpha/spec/` — **Formal specification (authoritative)**
- `docs/ori_lang/proposals/` — Proposals and rationale
- `library/std/` — Standard library
- `tests/spec/` — Spec conformance tests
- `plans/roadmap/` — Compiler roadmap

## Design Pillars

1. **Mandatory Verification**: Every function needs tests; contracts (`pre_check:`/`post_check:`)
2. **Dependency-Aware Integrity**: Tests in dependency graph; change propagates to callers' tests
3. **Explicit Effects**: Capabilities (`uses Http`); trivial mocking (`with Http = Mock in`)
4. **ARC-Safe**: No GC/borrow checker; capture by value; no shared mutable refs; see `spec/15-memory-model.md`

## Reference Repos (`~/lang_repos/`)

- `rust/` — diagnostics: `rustc_errors/src/{lib,diagnostic,json}.rs`, `rustc_lint_defs/src/lib.rs`
- `golang/` — errors: `cmd/compile/internal/base/print.go`, `go/types/errors.go`, `internal/types/errors/codes.go`; fixes: `cmd/vendor/.../analysis/{diagnostic,analysis}.go`, `cmd/fix/main.go`
- `typescript/` — `compiler/{types.ts,diagnosticMessages.json}`, `services/{codeFixProvider,textChanges,types,services}.ts`, `services/codefixes/*.ts`
- `zig/` — `src/{Compilation,Sema,Type,Value,InternPool,Zcu,main}.zig`
- `gleam/` — `compiler-core/src/{error,diagnostic,warning,analyse,exhaustiveness}.rs`, `type_/{error,mod}.rs`
- `elm/` — `compiler/src/Reporting/{Error,Suggest,Doc}.hs`, `Error/{Type,Syntax,Canonicalize}.hs`, `Type/Solve.hs`
- `roc/` — `crates/reporting/src/{report,error/{type,canonicalize,parse}}.rs`, `compiler/{solve,types,can,constrain,problem}/src/`

## CLI

`ori run file.ori` | `ori check file.ori` | `ori check --no-test` | `ori check --strict` | `ori test` | `ori test --only-attached` | `ori fmt src/`

## Files & Tests

- `.ori` source, `.test.ori` in `_test/` subdirectory
- Attached: `@test tests @target () -> void = run(...)` — runs on target/caller changes
- Floating: `@test tests _ () -> void = run(...)` — runs only via `ori test`
- Private access via `::` prefix; every function (except `@main`) requires tests
- Bug fix = failing test first (TDD): write test for correct behavior, verify failure, fix code, test passes unchanged

## Entry Points

- `@main () -> void` | `@main () -> int` | `@main (args: [str]) -> void` | `@main (args: [str]) -> int`
- `args` excludes program name

---

## ⚠️ Quick Reference Only — Spec is authoritative: `docs/ori_lang/0.1-alpha/spec/`

---

## Declarations

**Functions**: `@name (p: T) -> R = expr` | `pub @name` | `@name<T>` | `@name<T: Trait>` | `@name<T: A + B>` | `where T: Clone` | `uses Capability` | `(x: int = 10)` defaults
**Clauses**: `@f (0: int) -> int = 1` then `@f (n) = n * f(n-1)` | `if guard` | exhaustive, top-to-bottom
**Constants**: `let $name = value` | `pub let $name` | module-level must be `$`
**Const Functions**: `$name (p: T) -> R = expr` — pure, comptime with const args, limits: 1M steps/1000 depth/100MB/10s
**Types**: `type N = { f: T }` struct | `A | B | C(f: T)` sum | `type N = Existing` newtype | `type N<T>` | `#derive(Eq)` | `pub type`
**Traits**: `trait N { @m (self) -> T }` | `@m (self) -> T = default` | `type Item` assoc | `trait C: P` inheritance
**Impls**: `impl T { @m }` inherent | `impl Trait for T` | `impl<T: B> Trait for C<T>` | `self`/`Self`
**Default Impls**: `pub def impl Trait { @m }` — stateless, one per trait/module, auto-bound on import, override with `with`
**Resolution**: Diamond=single impl; Inherent>Trait>Extension; qualified: `Trait.method(v)`; `Type::Trait::Assoc`
**Object Safety**: No `Self` return/param (except receiver), no generic methods; safe: `Printable`, `Debug`, `Hashable`; unsafe: `Clone`, `Eq`, `Iterator`
**Tests**: `@t tests @fn () -> void` | `tests _` floating | `tests @a tests @b` multi | `#skip("r")` | `#compile_fail("e")` | `#fail("e")`

## Conditional Compilation

**Target**: `#target(os: "linux")` | `arch: "x86_64"` | `family: "unix"` | `any_os: [...]` | `not_os:` | file-level: `#!target(...)`
**Config**: `#cfg(debug)` | `release` | `feature: "ssl"` | `any_feature:` | `not_debug` | `not_feature:`
**Constants**: `$target_os`, `$target_arch`, `$target_family`, `$debug`, `$release` — false branch not type-checked

## Types

**Primitives**: `int` (i64), `float` (f64), `bool`, `str` (UTF-8), `char`, `byte`, `void`, `Never`
**Special**: `Duration` (`30s`, `100ms`), `Size` (`4kb`, `10mb`)
**Collections**: `[T]` list, `[T, max N]` fixed-capacity list, `{K: V}` map, `Set<T>`
**Compound**: `(T, U)` tuple, `()` unit, `(T) -> U` fn, `Trait` object
**Generic**: `Option<T>`, `Result<T, E>`, `Range<T>`, `Ordering`
**Const Generics**: `$N: int` const param | `@f<T, $N: int>` | `type Buffer<$N: int>` | `$B: bool` | `where N > 0` | `where N > 0 && N <= 100` | `where A || B`
**Const Bounds**: comparison (`==`, `!=`, `<`, `<=`, `>`, `>=`), logical (`&&`, `||`, `!`), arithmetic (`+`, `-`, `*`, `/`, `%`), bitwise (`&`, `|`, `^`, `<<`, `>>`) | multiple `where` = AND | caller must imply callee bounds
**Channels**: `Producer<T>`, `Consumer<T>`, `CloneableProducer<T>`, `CloneableConsumer<T>` (`T: Sendable`)
**Concurrency**: `Nursery`, `NurseryErrorMode` (`CancelRemaining | CollectAll | FailFast`)
**FFI**: `CPtr` (C opaque pointer), `JsValue` (JS object handle), `JsPromise<T>` (JS async)
**Rules**: No implicit conversions; overflow panics; `str[i]` returns single-codepoint `str`

### Fixed-Capacity Lists

`[T, max N]` — inline-allocated list with compile-time max capacity N, dynamic length 0 to N
**Subtype**: `[T, max N] <: [T]` — can pass to functions expecting `[T]`; capacity limits retained
**Methods**: `.capacity()`, `.is_full()`, `.remaining()`, `.push()` (panics if full), `.try_push()` → `bool`, `.push_or_drop()`, `.push_or_oldest()` (FIFO), `.to_dynamic()` → `[T]`
**Conversion**: `list.to_fixed<$N: int>()` panics if too large | `list.try_to_fixed<$N: int>()` → `Option`

## Literals

`42`, `1_000_000`, `0xFF` | `3.14`, `2.5e-8` | `"hello"` (escapes: `\\\"\n\t\r\0`) | `` `{name}` `` template | `'a'` char | `true`/`false` | `100ms`, `30s`, `5m`, `2h` | `4kb`, `10mb` | `[1, 2]`, `[...a, ...b]` | `{key: v}` or `{"key": v}` (literal str key), `{[expr]: v}` (computed key), `{...a, ...b}` | `Point { x, y }`, `{ ...p, x: 10 }`

## Operators (precedence high→low)

1. `.` `[]` `()` `?` — 2. `!` `-` `~` — 3. `*` `/` `%` `div` — 4. `+` `-` — 5. `<<` `>>` — 6. `..` `..=` `by` — 7. `<` `>` `<=` `>=` — 8. `==` `!=` — 9. `&` — 10. `^` — 11. `|` — 12. `&&` — 13. `||` — 14. `??`

## Expressions

**Conditionals**: `if c then e else e` | `if c then e` (void)
**Bindings**: `let x = v` mutable | `let $x` immutable | `let x: T` | shadowing OK | `let { x, y }` | `let { x: px }` | `let (a, b)` | `let [$h, ..t]`
**Indexing**: `list[0]`, `list[# - 1]` (`#`=length, panics OOB) | `map["k"]` → `Option<V>`
**Access**: `v.field`, `v.method(arg: v)` — named args required except: fn variables, single-param with inline lambda
**Lambdas**: `x -> x + 1` | `(a, b) -> a + b` | `() -> 42` | `(x: int) -> int = x * 2` — capture by value
**Ranges**: `0..10` excl | `0..=10` incl | `0..10 by 2` step | descending: `10..0 by -1` | infinite: `0..` (ascending), `0.. by -1` (descending) | int only
**Loops**: `for i in items do e` | `for x in items yield x * 2` | `for x in items if g yield x` | `loop(e)` + `break`/`continue` | `break value` | `continue value`
**Labels**: `loop:name(...)` | `for:name` | `break:name` | `continue:name`
**Spread**: `[...a, ...b]` | `{...a, ...b}` | `P { ...orig, x: 10 }` — later wins, literal contexts only

## Patterns (compiler constructs)

**function_seq**: `run(let x = a, result)` | `run(pre_check: c, body, post_check: r -> c)` | `try(let x = f()?, Ok(x))` | `match(v, P -> e, _ -> d)`
**function_exp**: `recurse(condition:, base:, step: self(...), memo:, parallel:)` | `parallel(tasks:, max_concurrent:, timeout:)` → `[Result]` | `spawn(tasks:, max_concurrent:)` → `void` | `timeout(op:, after:)` | `cache(key:, op:, ttl:)` | `with(acquire:, use: r ->, release: r ->)` | `for(over:, match:, default:)` | `catch(expr:)` → `Result<T, str>` | `nursery(body: n ->, on_error:, timeout:)`
**Channels**: `channel<T>(buffer:)` → `(Producer, Consumer)` | `channel_in` fan-in | `channel_out` fan-out | `channel_all` many-many
**Conversions**: `42 as float` infallible | `"42" as? int` fallible → `Option`
**Match patterns**: literal | `x` binding | `_` | `Some(x)` | `{ x, y }` | `[a, ..rest]` | `1..10` | `A | B` | `x @ pat` | `x.match(guard)`
**Exhaustiveness**: match must be exhaustive; guards require catch-all `_`; `let` binding patterns must be irrefutable

## Imports

**Relative**: `use "./math" { add }` | `"../utils"` | `"./http/client"`
**Module**: `use std.math { sqrt }` | `use std.net.http as http`
**Private**: `use "./m" { ::internal }` | **Alias**: `{ add as plus }` | **Re-export**: `pub use`
**Without default**: `use "m" { Trait without def }` — import trait without its `def impl`
**Extensions**: `extension std.iter.extensions { Iterator.count }` | `extend Iterator { @count (self) = ... }`

## FFI (Foreign Function Interface)

**Native (C ABI)**: `extern "c" from "m" { @_sin (x: float) -> float as "sin" }` | `from "lib"` specifies library | `as "name"` maps C name
**JavaScript (WASM)**: `extern "js" { @_sin (x: float) -> float as "Math.sin" }` | `extern "js" from "./utils.js"` for modules
**FFI Types**: `CPtr` opaque pointer | `Option<CPtr>` nullable | `JsValue` JS object handle | `JsPromise<T>` async JS
**C Types**: `c_char`, `c_short`, `c_int`, `c_long`, `c_longlong`, `c_float`, `c_double`, `c_size` — platform-specific sizes
**Struct Layout**: `#repr("c") type T = { ... }` — C-compatible memory layout
**Unsafe**: `unsafe { ptr_read(...) }` — operations Ori cannot verify
**Capability**: `uses FFI` — required for all foreign function calls
**Async WASM**: `JsPromise<T>` implicitly resolved at binding sites in async context (no `await` keyword)
**Compile Error**: `compile_error("message")` — compile-time error for platform availability

## Capabilities

**Declare**: `@f (...) -> T uses Http = ...` | `uses FileSystem, Async`
**Provide**: `with Http = RealHttp { } in expr` | `with Http = mock, Cache = mock in expr`
**Resolution**: with...in > imported `def impl` > module-local `def impl`
**Async**: `uses Async` = may suspend; no `uses` = sync; no `.await`; concurrency via `parallel(...)`
**Standard**: `Http`, `FileSystem`, `Clock`, `Random`, `Crypto`, `Cache`, `Print` (has default), `Logger`, `Env`, `Async`, `FFI`

## Comments

`// comment` — own line only, no inline | Doc: `// Desc` | `// * name:` | `// ! Error:` | `// > expr -> result`

## Formatting (enforced)

- 4 spaces, 100 char limit, trailing commas on multi-line only
- Space around: binary ops, arrows, after colons/commas, after `pub`, inside struct braces `{ }`, around `as`/`by`/`|`
- No space: inside parens/brackets, around `.`/`..`/`?`, empty delimiters
- Width-based breaking: inline ≤100, else break; `run`/`try`/`match`/`recurse`/`parallel`/`spawn`/`nursery` always stacked
- Breaking: params/args/generics/where/fields/variants one-per-line; lists wrap (simple) or one-per-line (complex); chains break each `.method()`; binary break before op; conditionals: `if...then` together, `else` newline

## Keywords

**Reserved**: `async break continue def do else extern false for if impl in let loop match pub self Self then trait true type unsafe use uses void where with yield`
**Context-sensitive**: `by cache catch for max parallel recurse run spawn timeout try with without`
**Built-in names** (call position only): `int float str byte len is_empty is_some is_none is_ok is_err assert assert_eq assert_ne assert_some assert_none assert_ok assert_err assert_panics assert_panics_with compare min max print panic todo unreachable dbg compile_error`

## Prelude

**Types**: `Option<T>` (`Some`/`None`), `Result<T, E>` (`Ok`/`Err`), `Error`, `TraceEntry`, `Ordering`, `PanicInfo`, `CancellationError`, `CancellationReason`
**Traits**: `Eq`, `Comparable`, `Hashable`, `Printable`, `Formattable`, `Debug`, `Clone`, `Default`, `Drop`, `Iterator`, `DoubleEndedIterator`, `Iterable`, `Collect`, `Into`, `Traceable`, `Index`

**Built-ins**: `print(msg:)`, `len(collection:)`, `is_empty(collection:)`, `is_some/is_none(option:)`, `is_ok/is_err(result:)`, `assert(condition:)`, `assert_eq(actual:, expected:)`, `assert_ne(actual:, unexpected:)`, `assert_some/none/ok/err(...)`, `assert_panics(f:)`, `assert_panics_with(f:, msg:)`, `panic(msg:)` → `Never`, `todo()`, `todo(reason:)` → `Never`, `unreachable()`, `unreachable(reason:)` → `Never`, `dbg(value:)`, `dbg(value:, label:)` → `T`, `compare(left:, right:)` → `Ordering`, `min/max(left:, right:)`, `hash_combine(seed:, value:)` → `int`, `repeat(value:)` → infinite iter, `is_cancelled()` → `bool`, `compile_error(msg:)` → compile-time error

**Option**: `.map(transform:)`, `.unwrap_or(default:)`, `.ok_or(error:)`, `.and_then(transform:)`, `.filter(predicate:)`
**Result**: `.map(transform:)`, `.map_err(transform:)`, `.unwrap_or(default:)`, `.ok()`, `.err()`, `.and_then(transform:)`, `.context(msg:)`, `.trace()` → `str`, `.trace_entries()` → `[TraceEntry]`, `.has_trace()` → `bool`
**Error**: `.trace()` → `str`, `.trace_entries()` → `[TraceEntry]`, `.has_trace()` → `bool`

**Printable**: `trait { @to_str (self) -> str }` — required for `` `{x}` ``; all primitives impl
**Formattable**: `trait { @format (self, spec: FormatSpec) -> str }` — blanket impl for Printable; spec: `[[fill]align][width][.precision][type]`; align: `<>^`; types: `bxXoeE`
**Debug**: `trait { @debug (self) -> str }` — shows escaped strings, derivable, internal structure
**Clone**: `trait { @clone (self) -> Self }` — all primitives/collections impl when elements do, derivable
**Iterator**: `trait { type Item; @next (self) -> (Option<Self.Item>, Self) }` — fused guarantee; copy elision when rebound; lazy evaluation
**DoubleEndedIterator**: `trait: Iterator { @next_back (self) -> (Option<Self.Item>, Self) }`
**Iterable**: `trait { type Item; @iter (self) -> impl Iterator }`
**Collect**: `trait<T> { @from_iter (iter: impl Iterator) -> Self }`
**Iterator methods**: `.map`, `.filter`, `.fold`, `.find`, `.collect`, `.count`, `.any`, `.all`, `.take`, `.skip`, `.enumerate`, `.zip`, `.chain`, `.flatten`, `.flat_map`, `.cycle`
**DoubleEnded methods**: `.rev`, `.last`, `.rfind`, `.rfold`
**Infinite iterators**: `repeat(value:)` → infinite; `(0..).iter()` → infinite range; bound with `.take(count:)` before `.collect()`
**Into**: `trait<T> { @into (self) -> T }` — `str` impls `Into<Error>`
**Traceable**: `trait { @with_trace (self, entry: TraceEntry) -> Self; @trace (self) -> str; @trace_entries (self) -> [TraceEntry]; @has_trace (self) -> bool }`
**TraceEntry**: `type = { function: str, file: str, line: int, column: int }` — function includes `@` prefix; entries ordered most recent first
**Drop**: `trait { @drop (self) -> void }` — custom destructor; runs when refcount reaches zero; cannot be async; panic during unwind aborts
**Index**: `trait<Key, Value> { @index (self, key: Key) -> Value }` — `x[k]` → `x.index(key: k)`; return `T` (panics), `Option<T>`, or `Result<T, E>`; `#` shorthand built-in only
**Eq**: `trait { @equals (self, other: Self) -> bool }` — reflexive, symmetric, transitive; derives `==`/`!=` operators; all primitives impl
**Comparable**: `trait: Eq { @compare (self, other: Self) -> Ordering }` — total ordering; derives `<`/`<=`/`>`/`>=` operators; IEEE 754 for floats (NaN > all); `None < Some`; `Ok < Err`
**Hashable**: `trait: Eq { @hash (self) -> int }` — if `a == b` then `a.hash() == b.hash()`; all primitives impl; +0.0/-0.0 same hash; use `hash_combine` for custom impls
