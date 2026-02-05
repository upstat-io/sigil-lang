---
paths:
  - "**/compiler/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/`.

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

**Expression-based — NO `return`**: Last expression IS the value. Exit via `?`/`break`/`panic`.

# Compiler

## Architecture
- **Deps**: `oric` → `ori_types/eval/patterns` → `ori_parse` → `ori_lexer` → `ori_ir/diagnostic`
- **IO**: only in `oric`; core crates pure
- **No phase bleeding**: parser ≠ type-check, lexer ≠ parse

## Memory
- Arena + ID (`ExprArena`+`ExprId`), not `Box<Expr>`
- Intern identifiers (`Name`), not `String`
- Newtypes for IDs; no `Arc` cloning in hot paths
- `&'a T` for borrowing, `Arc<T>` only for shared ownership

## Dispatch
- Enum for fixed sets (exhaustiveness, static dispatch)
- `dyn Trait` only for user-extensible
- Cost: `&dyn` < `Box<dyn>` < `Arc<dyn>`

## API
- >3 params → config struct
- No boolean flags
- Return iterators, not `Vec`
- RAII guards for context

## Salsa
- Query types: `Clone, Eq, PartialEq, Hash, Debug`
- No `Arc<Mutex<T>>`, fn pointers, or `dyn Trait`
- Deterministic (no random/time/IO)

## Diagnostics
- All errors have spans
- Accumulate, don't bail
- Imperative: "try using X"
- No `panic!` on user errors

## Tracing
- Use `tracing` crate, never `println!`/`eprintln!` for debug output
- Levels: `error` (should never happen), `warn` (recoverable), `debug` (phases/queries), `trace` (per-expression, hot paths)
- `#[tracing::instrument]` on public API entry points; use `skip_all` or `skip(arena, engine)` for large/non-Debug args
- Salsa `#[tracked]` functions: use manual `tracing::debug!()` events (not `#[instrument]`)
- Env vars: `ORI_LOG` (filter), `ORI_LOG_TREE=1` (hierarchical output), falls back to `RUST_LOG`
- Setup: `compiler/oric/src/tracing_setup.rs`, initialized in `main.rs`

## Style
- Functions < 50 lines (target < 30)
- No dead code, no `#[allow(clippy)]` without reason
- Use `//!`/`///` docs

## Testing
- TDD for bugs: tests first, verify fail, fix, tests pass unchanged
- Inline < 200 lines; separate if larger
- `cargo t` (all), `cargo st` (spec), `./test-all.sh` (full)

## Key Patterns

**TypeChecker (V2)**: InferEngine, Pool, Registries, ModuleChecker

**Method Dispatch**: BuiltinMethods → InherentImpl → TraitImpl (via MethodRegistry)

## Crates
- `ori_ir`: AST, spans, TypeId
- `ori_lexer`: Tokenization
- `ori_parse`: Parser
- `ori_types`: Type checking (V2 — Pool, InferEngine, registries)
- `ori_eval`: Interpreter
- `ori_patterns`: Pattern system
- `ori_llvm`: LLVM backend
- `ori_rt`: AOT runtime
- `ori_diagnostic`: Error reporting
- `oric`: CLI, Salsa

## Change Locations
- Expression: `ori_parse/grammar/expr/`, `ori_types/infer/expr.rs`, `ori_eval/interpreter/`
- Type: `ori_ir/type_id.rs`, `ori_types/pool/`, `ori_types/check/`
- Method: `ori_types/registry/methods.rs`, `ori_eval/interpreter/method_dispatch.rs`

## Source of Truth
1. `docs/ori_lang/0.1-alpha/spec/` — authoritative
2. `~/lang_repos/` — Rust, Go, TS, Zig, Gleam, Elm, Roc
