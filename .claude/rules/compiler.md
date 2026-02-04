---
paths:
  - "**/compiler/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/lang_repos/`.

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

**Expression-based — NO `return`**: Last expression IS the value. Exit via `?`/`break`/`panic`.

# Compiler

## Architecture
- **Deps**: `oric` → `ori_typeck/eval/patterns` → `ori_parse` → `ori_lexer` → `ori_ir/diagnostic`
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

## Style
- Functions < 50 lines (target < 30)
- No dead code, no `#[allow(clippy)]` without reason
- Use `//!`/`///` docs

## Testing
- TDD for bugs: tests first, verify fail, fix, tests pass unchanged
- Inline < 200 lines; separate if larger
- `cargo t` (all), `cargo st` (spec), `./test-all` (full)

## Key Patterns

**TypeChecker**: CheckContext, InferenceState, Registries, DiagnosticState, ScopeContext

**Method Dispatch**: UserRegistryResolver → CollectionMethodResolver → BuiltinMethodResolver

## Crates
- `ori_ir`: AST, spans
- `ori_lexer`: Tokenization
- `ori_parse`: Parser
- `ori_typeck`: Type checking
- `ori_eval`: Interpreter
- `ori_patterns`: Pattern system
- `ori_llvm`: LLVM backend
- `ori_rt`: AOT runtime
- `oric`: CLI, Salsa

## Change Locations
- Expression: `ori_parse/expr.rs`, `ori_typeck/expressions/`, `ori_eval/expr.rs`
- Operator: `ori_typeck/operators.rs`, `ori_eval/interpreter/`, `spec/operator-rules.md`
- Type: `ori_ir/items/`, `ori_parse/item.rs`, `ori_typeck/type_registration.rs`

## Source of Truth
1. `docs/ori_lang/0.1-alpha/spec/` — authoritative
2. `~/lang_repos/` — Rust, Go, TS, Zig, Gleam, Elm, Roc
