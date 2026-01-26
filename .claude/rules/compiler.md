---
paths: **/compiler**
---

# Compiler Development

## Pragmatic Guidelines

### Dispatch & Extensibility

- **Enum** for fixed sets (built-in patterns): exhaustiveness, static dispatch, inlining, jump-to-def
- **`dyn Trait`** only for user-extensible (user methods)
- Cost hierarchy: `&dyn` < `Box<dyn>` < `Arc<dyn>` (atomic refcount)
- Registry: when users add entries (user methods)
- Match: fixed sets (built-in patterns) — compiler catches missing cases

### Memory

- Expressions: `ExprArena` + `ExprId`, not `Box<Expr>`
- Identifiers: `Name` (interned), not `String`
- Method keys: `MethodKey`, not `(String, String)`
- Shared values: `Arc<T>` after construction, never `Arc<RwLock<T>>`

### API Design

- >3-4 params → config struct
- No single-use "doer" objects → just functions
- Return iterators, not `Vec` — push allocations to caller
- Imports: std → external → workspace → local

### Builders & RAII

- Builders: use when many optional params, validation needed, fluent API helps
- Builders: skip when few params, `Default` + struct update works
- RAII: use when scope is clear and lexical
- Explicit params: when scope unclear or long-lived (but params pollute signatures)

### Complexity & Style

- Flag O(n²) → O(n), linear scans → hash lookups, repeated lookups → cache
- Line count is smell, not rule — 600 lines one concept → keep; three concepts → split
- All public items: documented
- Newtypes: `ExprId`, `Name`, `MethodKey`
- Iterators over indexing
- `#[cold]` on error factories
- No banner comments — use `//!` module docs or `///` item docs, not decorative `// ====` headers

### Errors

- `Result<T, E>`: recoverable (user input, file I/O)
- `panic!`: invariant violations (compiler bug)
- `unreachable!()`: impossible paths
- `#[allow(clippy)]`: fix issue; if clippy wrong, comment why

## Salsa

- Query types must derive: `Clone, Eq, PartialEq, Hash, Debug`
- No function pointers, trait objects, or `Arc<Mutex<T>>` in queries
- `SharedRegistry<T>`: build fully, then wrap in `Arc` (immutable)

## Design Principle

Compiler implements only constructs requiring **special syntax or static analysis**. Everything else → stdlib.

- **Compiler**: `run`, `try`, `match`, `recurse`, `parallel`, `spawn`, `timeout`, `cache`, `with`, `int`, `float`, `str`, `byte`
- **Stdlib**: `map`, `filter`, `fold`, `find`, `retry`, `validate`

---

## Key Patterns

**TypeChecker** (5 components in `sigilc/src/typeck/checker/components.rs`):
- `CheckContext<'a>` — immutable arena/interner refs
- `InferenceState` — mutable inference ctx, env, expr_types
- `Registries` — pattern, type_op, types, traits
- `DiagnosticState` — errors, queue, source
- `ScopeContext` — function sigs, impl Self, capabilities

**Construction**: `TypeCheckerBuilder::new(&arena, &interner).with_source(source).build()`

**Method Dispatch** (Chain of Responsibility, `sigilc/src/eval/evaluator/resolvers/`):
- Priority 0: `UserRegistryResolver` — user impl blocks + `#[derive]` methods (unified)
- Priority 1: `CollectionMethodResolver` — map/filter/fold
- Priority 2: `BuiltinMethodResolver` — built-ins

**Construction**: `EvaluatorBuilder::new(&interner, &arena).user_method_registry(registry).build()`

**RAII Guards**: `checker.with_capability_scope(caps, |c| { ... })`, `checker.with_impl_scope(self_type, |c| { ... })`, `eval.with_env_scope(|e| { ... })`

**Arena Threading**: `self.create_function_evaluator(func_arena, call_env)`

---

## Change Locations

| Change | Files |
|--------|-------|
| **Expression** | `sigil_parse/src/grammar/expr.rs`, `sigilc/src/typeck/infer/expr.rs`, `sigilc/src/eval/exec/expr.rs` |
| **Pattern** | `sigilc/src/patterns/<name>.rs`, `sigilc/src/patterns/registry.rs` |
| **Type Decl** | `sigil_ir/src/ast/items/`, `sigil_parse/src/grammar/item.rs`, `sigilc/src/typeck/checker/type_registration.rs` |
| **Trait/Impl** | `sigil_ir/src/ast/items/`, `sigil_parse/src/grammar/item.rs`, `sigilc/src/eval/evaluator/resolvers/`, `sigil_eval/src/user_methods.rs` |
| **Resolver** | `sigilc/src/eval/evaluator/resolvers/<name>.rs`, implement `MethodResolver` trait, register in `builder.rs` |
| **Diagnostic** | `sigil_diagnostic/src/problem.rs`, `sigil_diagnostic/src/fixes/` |
| **Control Flow** | `sigil_lexer/src/lib.rs`, `sigil_ir/src/ast/`, `sigil_parse/src/grammar/control.rs`, `sigilc/src/typeck/infer/control.rs`, `sigilc/src/eval/exec/control.rs` |

## Testing

- **Inline** (`#[cfg(test)]`): <200 lines, tightly coupled to impl
- **Separate** (`src/<mod>/tests/`): >200 lines, comprehensive suites, edge cases
- **Spec**: `tests/spec/` — conformance
- **Run-pass**: `tests/run-pass/` — e2e
- **Compile-fail**: `tests/compile-fail/` — expected failures

```bash
cargo test --workspace       # all
cargo test -p sigilc         # single crate
cargo test -- eval::tests    # specific module
```

## Crates

| Crate | Purpose |
|-------|---------|
| `sigil_ir` | AST, spans (no deps) |
| `sigil_diagnostic` | Errors, DiagnosticQueue, emitters |
| `sigil_lexer` | Tokenization |
| `sigil_types` | Type system |
| `sigil_parse` | Recursive descent parser |
| `sigil_typeck` | Type checking |
| `sigil_patterns` | Pattern definitions |
| `sigil_eval` | Tree-walking interpreter |
| `sigil-macros` | Proc-macros |
| `sigilc` | CLI, Salsa queries, orchestration |

## Source of Truth

1. `docs/sigil_lang/0.1-alpha/spec/` — Language spec (authoritative)
2. `docs/compiler/design/` — Implementation details
3. `~/lang_repos/` — Reference: Rust, Go, TS, Zig, Gleam, Elm, Roc

## Doc Sync

- Spec changed → update `docs/sigil_lang/0.1-alpha/spec/`
- Syntax changed → update `CLAUDE.md`
- Architecture changed → update `docs/compiler/design/`

## Debug

```bash
SIGIL_DEBUG=tokens,ast,types,eval sigil run file.si
```

See `docs/compiler/design/appendices/D-debugging.md`
