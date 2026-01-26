---
paths: **compiler**
---

# Compiler Development

## Design Principle: Lean Core, Rich Libraries

The compiler implements only constructs that **require special syntax or static analysis**. Everything else belongs in the standard library as methods or functions.

**In the compiler** (special syntax/analysis needed):
- `run`, `try`, `match` — sequential patterns with bindings
- `recurse` — self-referential recursion via `self()`
- `parallel`, `spawn`, `timeout` — concurrency requiring runtime support
- `cache`, `with` — capability-aware resource management
- `int`, `float`, `str`, `byte` — type conversion (function_val)

**In stdlib** (no compiler support needed):
- `[T].map()`, `[T].filter()`, `[T].fold()`, `[T].find()` — collection methods
- `retry()`, `validate()` — library functions in `std.resilience`, `std.validate`

When adding features, ask: "Does this require special syntax or static analysis?" If no, it belongs in stdlib.

## Source of Truth

1. **Language Specification** - `docs/sigil_lang/0.1-alpha/spec/` (authoritative)
2. **Compiler Design** - `docs/compiler/design/` (implementation details)
3. **Reference Repos** - `~/lang_repos/` (patterns from Rust, Go, TS, Zig, Gleam, Elm, Roc)

## Crate Structure

| Crate | Path | Purpose |
|-------|------|---------|
| `sigil_ir` | `compiler/sigil_ir/` | Core IR types (AST, spans, no dependencies) |
| `sigil_diagnostic` | `compiler/sigil_diagnostic/` | Error reporting, DiagnosticQueue, emitters |
| `sigil_lexer` | `compiler/sigil_lexer/` | Tokenization |
| `sigil_types` | `compiler/sigil_types/` | Type system definitions |
| `sigil_parse` | `compiler/sigil_parse/` | Recursive descent parser |
| `sigil_typeck` | `compiler/sigil_typeck/` | Type checking infrastructure |
| `sigil_patterns` | `compiler/sigil_patterns/` | Pattern definitions, Value/Heap system |
| `sigil_eval` | `compiler/sigil_eval/` | Tree-walking interpreter |
| `sigil-macros` | `compiler/sigil-macros/` | Proc-macros (#[derive(Diagnostic)]) |
| `sigilc` | `compiler/sigilc/` | CLI, Salsa queries, orchestration |

## Salsa Compatibility

All types in query signatures must derive: `Clone, Eq, PartialEq, Hash, Debug`
- No function pointers, trait objects, or interior mutability (`Arc<Mutex<T>>`)
- Use `SharedRegistry<T>` pattern: build fully, then wrap in `Arc` (immutable)

## Memory Management

- **Expressions**: `ExprArena` + `ExprId`, not `Box<Expr>`
- **Identifiers**: `Name` (interned), not `String`
- **Method keys**: `MethodKey` for type/method pairs, not `(String, String)` tuples
- **Shared values**: `Arc<T>` after construction, never `Arc<RwLock<T>>`
- **Exception**: `SharedMutableRegistry<T>` uses `Arc<RwLock<T>>` for cached dispatchers that need post-construction updates

## Key Architectural Patterns

### TypeChecker Components

TypeChecker is organized into 5 logical components (see `sigilc/src/typeck/checker/components.rs`):

| Component | Purpose |
|-----------|---------|
| `CheckContext<'a>` | Immutable refs to arena and interner |
| `InferenceState` | Mutable inference ctx, env, expr_types |
| `Registries` | Pattern, type_op, types, traits |
| `DiagnosticState` | Errors, queue, source |
| `ScopeContext` | Function sigs, impl Self, capabilities |

Use `TypeCheckerBuilder` for construction:
```rust
TypeCheckerBuilder::new(&arena, &interner)
    .with_source(source)
    .with_context(&compiler_context)
    .build()
```

### Evaluator Method Dispatch

Method resolution uses Chain of Responsibility (see `sigilc/src/eval/evaluator/resolvers/`):

| Resolver | Priority | Purpose |
|----------|----------|---------|
| `UserMethodResolver` | 0 | User-defined methods from impl blocks |
| `DerivedMethodResolver` | 1 | Methods from `#[derive(...)]` |
| `CollectionMethodResolver` | 2 | map, filter, fold (need evaluator) |
| `BuiltinMethodResolver` | 3 | Built-in methods in MethodRegistry |

Use `EvaluatorBuilder` for construction:
```rust
EvaluatorBuilder::new(&interner, &arena)
    .user_method_registry(registry)
    .build()
```

### RAII Scope Guards

Use scope guards for safe context management in TypeChecker:
```rust
// Capabilities restored automatically, even on early return
checker.with_capability_scope(caps, |c| { ... });

// Impl Self type restored automatically
checker.with_impl_scope(self_type, |c| { ... });
```

### Arena Threading

Functions carry their own `SharedArena` for thread safety. Use `create_function_evaluator()`:
```rust
let func_evaluator = self.create_function_evaluator(func_arena, call_env);
```

## Change Categories

### New Expression
- Parser: `sigil_parse/src/grammar/expr.rs`
- Type inference: `sigilc/src/typeck/infer/expr.rs`
- Evaluator: `sigilc/src/eval/exec/expr.rs`
- Spec: `docs/sigil_lang/0.1-alpha/spec/09-expressions.md`

### New Pattern
- Create: `sigilc/src/patterns/<name>.rs`
- Register: `sigilc/src/patterns/registry.rs`
- Add type checking + evaluation logic
- Spec: `docs/sigil_lang/0.1-alpha/spec/10-patterns.md`
- See: `docs/compiler/design/06-pattern-system/adding-patterns.md`

### New Type Declaration
- IR: `sigil_ir/src/ast/items/`
- Parser: `sigil_parse/src/grammar/item.rs`
- Type registry: `sigilc/src/typeck/checker/type_registration.rs`
- Spec: `docs/sigil_lang/0.1-alpha/spec/06-types.md`

### New Trait/Impl
- IR: `sigil_ir/src/ast/items/`
- Parser: `sigil_parse/src/grammar/item.rs`
- Method dispatch: `sigilc/src/eval/evaluator/resolvers/`
- User methods: `sigil_eval/src/user_methods.rs`

### New Method Resolver
- Create: `sigilc/src/eval/evaluator/resolvers/<name>.rs`
- Implement: `MethodResolver` trait with `resolve()`, `priority()`, `name()`
- Register: Add to `MethodDispatcher::new()` in `builder.rs`
- Priority: Lower number = higher priority (user=0, derived=1, collection=2, builtin=3)

### New Diagnostic
- Problem type: `sigil_diagnostic/src/problem.rs`
- Code fix: `sigil_diagnostic/src/fixes/`
- Error codes: `docs/compiler/design/appendices/C-error-codes.md`

### Control Flow
- Lexer: `sigil_lexer/src/lib.rs` (if new keywords)
- AST: `sigil_ir/src/ast/`
- Parser: `sigil_parse/src/grammar/control.rs`
- Type inference: `sigilc/src/typeck/infer/control.rs`
- Evaluator: `sigilc/src/eval/exec/control.rs`

## Testing

### Test Organization (Hybrid Approach)

Following Rust compiler conventions, tests use a hybrid organization:

**Inline tests** (`#[cfg(test)] mod tests`) for:
- Small utility functions (< 200 lines of tests)
- Simple unit tests that are tightly coupled to implementation
- Tests that benefit from being next to the code

**Separate test files** (`src/<module>/tests/<name>_tests.rs`) for:
- Comprehensive test suites (> 200 lines)
- Tests adapted from other languages (Go, Rust stdlib, etc.)
- Edge cases and stress tests
- Integration-style tests within a module

Example structure:
```
sigilc/src/eval/
├── function_val.rs           # Implementation
├── tests/
│   ├── mod.rs                # Test module declaration
│   └── function_val_tests.rs # Comprehensive tests
```

### Test Locations

| Location | Purpose |
|----------|---------|
| `#[cfg(test)]` inline | Simple unit tests, close to implementation |
| `src/<mod>/tests/` | Comprehensive test suites for complex modules |
| `tests/spec/` | Language specification conformance tests |
| `tests/run-pass/` | End-to-end execution tests |
| `tests/compile-fail/` | Expected compilation failure tests |

### Running Tests

```bash
cargo test --workspace        # All tests
cargo test -p sigilc          # Single crate
cargo test -- eval::tests     # Specific module
```

Target ~300 lines/file, max 500 (grammar files may exceed)

## Coding Guidelines

See `docs/compiler/design/appendices/E-coding-guidelines.md` for comprehensive coding standards including:

- **Testing**: Organization, naming, coverage requirements
- **Code Style**: Formatting, file length, imports, naming conventions
- **Error Handling**: Result vs panic, error types, factory functions
- **Documentation**: Module docs, public API docs, internal comments
- **Architecture**: Module design, dependency direction, trait design, registry pattern
- **Type Safety**: Newtypes, builder pattern, exhaustive matching, conversion safety
- **Performance**: Allocation, cloning, iteration, stack safety
- **Clippy Compliance**: Required lints, pedantic fixes, never use `#[allow]`
- **Git Practices**: Commit messages, branch naming, PR requirements

**Key Rules**:
- Fix clippy warnings properly—never use `#[allow(...)]` attributes
- All public items must have documentation
- Use newtypes for type safety (`ExprId`, `Name`, `MethodKey`)
- Use builder pattern for complex struct construction (`TypeCheckerBuilder`, `EvaluatorBuilder`)
- Use RAII scope guards for context management (`with_capability_scope`, `with_impl_scope`)
- Prefer iterators over indexing
- Use `#[cold]` on error factory functions

## Documentation Sync

When modifying behavior:
- Update spec if language semantics changed
- Update `CLAUDE.md` if syntax/types/patterns changed
- Update compiler design docs if architecture changed

## Debugging

```bash
SIGIL_DEBUG=tokens,ast,types,eval sigil run file.si
```

See `docs/compiler/design/appendices/D-debugging.md`
