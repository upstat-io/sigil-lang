---
paths: **compiler**
---

# Compiler Development

## Crate Structure

- `sigil_ir` - Core IR (tokens, spans, AST, arena, interning) - no deps
- `sigil_diagnostic` - Errors, suggestions, emitters
- `sigil_lexer` - Tokenization (logos)
- `sigil_types` - Type definitions
- `sigil_parse` - Parser (recursive descent)
- `sigil-macros` - Diagnostic derives
- `sigilc` - CLI, Salsa queries, typeck, eval, patterns

**Principle**: Pure functions in library crates; Salsa queries in `sigilc`.

## Source of Truth

1. Language Spec (`docs/sigil_lang/0.1-alpha/spec/`) - authoritative
2. Language Design (`docs/sigil_lang/0.1-alpha/design/`) - rationale
3. Compiler Design (`docs/compiler/design/`) - implementation
4. Reference Repos (`~/lang_repos/`) - patterns

## Salsa Types

Must derive: `Clone, Eq, PartialEq, Hash, Debug`. No function pointers, trait objects, or interior mutability.

## Memory Rules

- Arena: `ExprArena` + `ExprId`, not `Box<Expr>`
- Interning: `Name` not `String`, compare with `==`
- Registries: Build fully, then wrap in `Arc` (never `Arc<RwLock<T>>`)

## Testing

- `cargo t` - Rust tests
- `cargo st` - Sigil language tests
- `cargo stv` - Verbose Sigil tests

## File Paths by Task

| Task | Files |
|------|-------|
| New token | `sigil_ir/src/token.rs`, `sigil_lexer/src/lib.rs` |
| New AST node | `sigil_ir/src/ast/expr.rs` |
| New expression | `sigil_parse/src/grammar/expr/`, `sigilc/src/typeck/infer/`, `sigilc/src/eval/exec/` |
| New pattern | `sigilc/src/patterns/<name>.rs`, `sigilc/src/patterns/registry.rs` |
| New type | `sigil_types/src/lib.rs`, `sigilc/src/typeck/type_registry/` |
| New error | `sigil_diagnostic/src/lib.rs`, `sigilc/src/problem/` |
| New test feature | `sigilc/src/test/discovery.rs`, `sigilc/src/test/runner.rs` |

## Guidelines

- Target ~300 lines/file, max 500
- Update spec/design docs when changing behavior
- Debug: `SIGIL_DEBUG=tokens,ast,types,eval sigil run file.si`
