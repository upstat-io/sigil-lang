---
paths: **compiler**
---

# Compiler Development

## Source of Truth

1. **Language Specification** - `docs/sigil_lang/0.1-alpha/spec/` (authoritative)
2. **Compiler Design** - `docs/compiler/design/` (implementation details)
3. **Reference Repos** - `~/lang_repos/` (patterns from Rust, Go, TS, Zig, Gleam, Elm, Roc)

## Crate Structure

| Crate | Path | Purpose |
|-------|------|---------|
| `sigil_ir` | `compiler/sigil_ir/` | Core IR types (no dependencies) |
| `sigil_diagnostic` | `compiler/sigil_diagnostic/` | Error reporting system |
| `sigil_lexer` | `compiler/sigil_lexer/` | Tokenization |
| `sigil_types` | `compiler/sigil_types/` | Type system definitions |
| `sigil_parse` | `compiler/sigil_parse/` | Recursive descent parser |
| `sigilc` | `compiler/sigilc/` | CLI, Salsa queries, typeck, eval, patterns |

## Salsa Compatibility

All types in query signatures must derive: `Clone, Eq, PartialEq, Hash, Debug`
- No function pointers, trait objects, or interior mutability (`Arc<Mutex<T>>`)
- Use `SharedRegistry<T>` pattern: build fully, then wrap in `Arc` (immutable)

## Memory Management

- **Expressions**: `ExprArena` + `ExprId`, not `Box<Expr>`
- **Identifiers**: `Name` (interned), not `String`
- **Shared values**: `Arc<T>` after construction, never `Arc<RwLock<T>>`

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
- Method dispatch: `sigilc/src/eval/methods.rs`

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

- Unit tests in `#[cfg(test)]` modules, run with `cargo test`
- Spec tests in `tests/spec/` validate language specification
- Target ~300 lines/file, max 500 (grammar files may exceed)

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
