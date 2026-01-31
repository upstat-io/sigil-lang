---
paths: **/compiler/**
---

**Fix issues encountered in code you touch. No "pre-existing" exceptions.**

# Compiler Development

## Architecture

- **Crate deps**: `oric` → `ori_typeck/eval/patterns` → `ori_parse` → `ori_lexer` → `ori_ir/diagnostic`
- **IO only in CLI**: `oric` performs IO; core crates pure
- **No phase bleeding**: parser doesn't type-check, lexer doesn't parse
- **Module clarity**: one responsibility per module; doc comment for purpose

## Dispatch

- **Enum** for fixed sets: exhaustiveness, static dispatch, inlining
- **`dyn Trait`** only for user-extensible (user methods)
- **Cost**: `&dyn` < `Box<dyn>` < `Arc<dyn>`
- **Registry**: only when users add entries at runtime

## Memory

- **Arena**: `ExprArena` + `ExprId`, not `Box<Expr>`
- **Interning**: `Name` for identifiers, not `String`
- **Newtypes**: `ExprId`, `MethodKey` — not raw `u32`
- **No `Arc` cloning** in hot paths; `#[cold]` on error factories

## API Design

- **>3-4 params** → config struct with `Default`
- **No boolean flags** — use enum or separate functions
- **Return iterators**, not `Vec`
- **RAII guards** for context save/restore

## Salsa

- Query types: `Clone, Eq, PartialEq, Hash, Debug`
- No `Arc<Mutex<T>>`, function pointers, or `dyn Trait` in queries
- Queries must be deterministic (no random, time, IO)

## Diagnostics

- All errors have source spans
- Accumulate errors, don't bail early
- Imperative suggestions: "try using X" not "Did you mean X?"
- Three-part: problem → source context → actionable guidance
- No `panic!` on user errors

## Performance

- Flag O(n²) → O(n) or O(n log n)
- Hash lookups instead of linear scans
- No allocation in hot loops
- Iterators over indexing

## Style

- No `#[allow(clippy)]` without justification
- Functions < 50 lines (target < 30)
- No dead code or commented-out code
- No banner comments; use `//!` and `///` docs

## Design Principle

Compiler: constructs requiring special syntax or static analysis. Everything else → stdlib.

- **Compiler**: `run`, `try`, `match`, `recurse`, `parallel`, `spawn`, `timeout`, `cache`, `with`
- **Stdlib**: `map`, `filter`, `fold`, `find`, `retry`, `validate`

## Key Patterns

**TypeChecker** (5 components):
- `CheckContext<'a>` — immutable arena/interner refs
- `InferenceState` — mutable inference ctx, env, expr_types
- `Registries` — pattern, type_op, types, traits
- `DiagnosticState` — errors, queue, source
- `ScopeContext` — function sigs, impl Self, capabilities

**Method Dispatch** (priority order):
- 0: `UserRegistryResolver` — user impls + `#[derive]`
- 1: `CollectionMethodResolver` — map/filter/fold
- 2: `BuiltinMethodResolver` — built-ins

**RAII Guards**: `with_capability_scope()`, `with_impl_scope()`, `with_env_scope()`

## Change Locations

| Change | Files |
|--------|-------|
| Expression | `ori_parse/.../expr.rs`, `ori_typeck/.../expressions/`, `ori_eval/.../expr.rs` |
| Pattern | `ori_patterns/src/<name>.rs`, `registry.rs` |
| Type Decl | `ori_ir/.../items/`, `ori_parse/.../item.rs`, `ori_typeck/.../type_registration.rs` |
| Trait/Impl | `ori_ir/.../items/`, `ori_parse/.../item.rs`, `ori_eval/.../resolvers/` |
| Diagnostic | `ori_diagnostic/src/problem.rs`, `fixes/` |

## Crates

| Crate | Purpose |
|-------|---------|
| `ori_ir` | AST, spans (no deps) |
| `ori_diagnostic` | Errors, DiagnosticQueue, emitters |
| `ori_lexer` | Tokenization |
| `ori_types` | Type system |
| `ori_parse` | Recursive descent parser |
| `ori_typeck` | Type checking |
| `ori_patterns` | Pattern definitions, Value, EvalError |
| `ori_eval` | Interpreter, Environment, method dispatch |
| `oric` | CLI, Salsa queries, orchestration |

## Testing

- **Inline** (`#[cfg(test)]`): <200 lines
- **Separate** (`src/<mod>/tests/`): >200 lines
- **Spec**: `tests/spec/` — conformance
- **TDD for bugs**: failing test first

```bash
cargo test --workspace       # all
cargo test -p oric           # single crate
```

## Debug

```bash
ORI_DEBUG=tokens,ast,types,eval ori run file.ori
```

## Source of Truth

1. `docs/ori_lang/0.1-alpha/spec/` — Language spec (authoritative)
2. `docs/compiler/design/` — Implementation details
3. `~/lang_repos/` — Reference: Rust, Go, TS, Zig, Gleam, Elm, Roc
