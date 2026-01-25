---
paths: **compiler**
---

# Compiler Development

Comprehensive guidance for working on the Sigil compiler (`sigilc`).

## Source of Truth Hierarchy

When implementing or modifying compiler behavior, consult sources in this order:

1. **Language Specification** (`docs/sigil_lang/0.1-alpha/spec/`)
   - Formal language definition (grammar, semantics, behavior)
   - If compiler differs from spec, the spec is correct

2. **Language Design** (`docs/sigil_lang/0.1-alpha/design/`)
   - Rationale and detailed explanations
   - Why decisions were made

3. **Compiler Design** (`docs/compiler/design/`)
   - Architecture and implementation details
   - How the compiler is structured

4. **Reference Repos** (`~/lang_repos/`)
   - Rust, Go, TypeScript, Zig, Gleam, Elm, Roc
   - Implementation patterns and best practices

## Salsa Compatibility Checklist

All types in Salsa query signatures or tracked structs must:

```rust
#[derive(Clone, Eq, PartialEq, Hash, Debug)]
pub struct MyType { ... }
```

Before adding a new type to queries:

- [ ] Derives Clone, Eq, PartialEq, Hash, Debug
- [ ] No function pointers
- [ ] No trait objects (Box<dyn Trait>)
- [ ] No interior mutability (Arc<Mutex<T>>)
- [ ] Comparison is efficient (for early cutoff)

## Memory Management Rules

### Arena Allocation

- Use `ExprArena` for expressions, not `Box<Expr>`
- Return `ExprId` indices, not references
- Pass arena explicitly to functions

### String Interning

- Use `Name` for all identifiers, not `String`
- Intern strings via `interner.intern()`
- Compare Names with `==` (O(1))

### Heap Values

- Use `Arc` for shared runtime values
- Use `Heap<T>` wrapper for consistency
- Prefer `Copy` types where possible (ExprId, Name, Span)

### Shared Registries (IMPORTANT)

**Never use `Arc<RwLock<T>>` or `Arc<Mutex<T>>` for registries.**

Why this matters:
- Interior mutability (`RwLock`, `Mutex`, `RefCell`) inside `Arc` creates hidden shared mutable state
- This leads to hard-to-debug issues where mutations "leak" across boundaries
- It violates Rust's principle of making shared mutability explicit and controlled

**Correct pattern** - build fully, then share immutably:
```rust
// 1. Build up the registry (owned, mutable)
let mut registry = UserMethodRegistry::new();
registry.register("str", "shout", method);

// 2. Wrap in Arc AFTER construction is complete
let shared = SharedRegistry::new(registry);  // Arc<T>, immutable

// 3. Clone the Arc to share (cheap, just increments refcount)
let child_registry = shared.clone();
```

**Wrong pattern** - interior mutability:
```rust
// DON'T DO THIS - creates hidden shared mutable state
let shared = Arc::new(RwLock::new(UserMethodRegistry::new()));
shared.write().unwrap().register(...);  // Mutation through Arc = bad
```

This pattern applies to all registries: `PatternRegistry`, `MethodRegistry`, `UserMethodRegistry`, etc. Use `SharedRegistry<T>` which enforces immutability after construction.

## Testing Requirements

### Unit Tests

- Every new function needs tests
- Tests go in `#[cfg(test)]` modules or separate files
- Run with `cargo test`

### Spec Tests

- Tests in `tests/spec/` validate language specification
- Each test references spec section it validates
- If test fails, implementation is wrong (not the test)

### Coverage

- Sigil requires tests for all public functions
- Use `sigil check` to verify coverage
- Private functions can use `::` import for testing

## File Size Guidelines

- **Target**: ~300 lines per file
- **Maximum**: 500 lines per file
- **Exception**: Grammar files may be larger

When files exceed limits, extract submodules.

---

## Change Categories

### Adding a New Pattern

1. Create pattern struct in `patterns/`
2. Implement `PatternDefinition` trait
3. Register in `PatternRegistry::with_builtins()`
4. Add type checking logic
5. Add evaluation logic
6. Write tests
7. Update `docs/sigil_lang/0.1-alpha/spec/10-patterns.md`
8. Update `CLAUDE.md` Patterns section

Files to modify:
- `compiler/sigilc/src/patterns/<name>.rs` (new)
- `compiler/sigilc/src/patterns/mod.rs`
- `compiler/sigilc/src/patterns/registry.rs`

### Adding New Control Flow

1. Add token(s) to lexer if needed
2. Add AST node to `ir/ast.rs`
3. Add parsing in `parser/grammar/expr.rs` or `control.rs`
4. Add type inference in `typeck/infer/control.rs`
5. Add evaluation in `eval/exec/control.rs`
6. Write tests
7. Update spec and design docs

Files to modify:
- `compiler/sigilc/src/lexer.rs` (if new keywords)
- `compiler/sigilc/src/ir/ast.rs`
- `compiler/sigilc/src/parser/grammar/expr.rs`
- `compiler/sigilc/src/typeck/infer/control.rs`
- `compiler/sigilc/src/eval/exec/control.rs`

### Adding a New Type Declaration

1. Add to `TypeDef` enum in `typeck/type_registry.rs`
2. Add parsing in `parser/grammar/item.rs`
3. Add type checking logic
4. Add evaluation support
5. Write tests
6. Update spec

Files to modify:
- `compiler/sigilc/src/typeck/type_registry.rs`
- `compiler/sigilc/src/parser/grammar/item.rs`
- `compiler/sigilc/src/parser/grammar/type.rs`

### Adding a New Trait

1. Add to trait registry
2. Add parsing for trait definition
3. Add impl parsing
4. Add trait bound checking
5. Add method dispatch in evaluator
6. Write tests
7. Update spec

Files to modify:
- `compiler/sigilc/src/typeck/type_registry.rs`
- `compiler/sigilc/src/parser/grammar/item.rs`
- `compiler/sigilc/src/eval/methods.rs`

### Adding a New Diagnostic/Error

1. Add error code to `ErrorCode` enum
2. Add to `Problem` enum
3. Implement `to_diagnostic()` conversion
4. Add suggested fix if applicable
5. Add to error code documentation
6. Write test that triggers the error

Files to modify:
- `compiler/sigilc/src/diagnostic/mod.rs`
- `compiler/sigilc/src/diagnostic/problem.rs`
- `compiler/sigilc/src/diagnostic/fixes/mod.rs`
- `docs/compiler/design/appendices/C-error-codes.md`

### Module Behavior Changes

1. Verify change aligns with spec
2. Update import resolution in `eval/module/import.rs`
3. Update module caching if needed
4. Write tests with multiple files
5. Update spec if behavior changed

Files to modify:
- `compiler/sigilc/src/eval/module/import.rs`
- `compiler/sigilc/src/eval/evaluator.rs`

### Standard Library Changes

1. Update stdlib files in `library/std/`
2. Update module documentation in `docs/sigil_lang/0.1-alpha/modules/`
3. Ensure backward compatibility
4. Write tests

### Testing Feature Changes

1. Update test discovery in `test/discovery.rs`
2. Update test runner in `test/runner.rs`
3. Update test attributes if needed
4. Write tests for the test system
5. Update spec

Files to modify:
- `compiler/sigilc/src/test/discovery.rs`
- `compiler/sigilc/src/test/runner.rs`

### Capability System Changes

1. Add capability to `Capability` enum
2. Add type checking for capability requirements
3. Add capability provision (`with...in`)
4. Write tests
5. Update spec

Files to modify:
- `compiler/sigilc/src/types.rs`
- `compiler/sigilc/src/typeck/checker.rs`
- `compiler/sigilc/src/eval/evaluator.rs`

### Async/Parallel Changes

1. Update `parallel` pattern implementation
2. Update capability tracking for `Async`
3. Ensure thread safety
4. Write concurrent tests
5. Update spec

Files to modify:
- `compiler/sigilc/src/patterns/parallel.rs`
- `compiler/sigilc/src/patterns/spawn.rs`
- `compiler/sigilc/src/eval/evaluator.rs`

### Tooling Enhancements

1. Update CLI in `main.rs`
2. Add new command/flag parsing
3. Implement feature
4. Write tests
5. Update CLI documentation

Files to modify:
- `compiler/sigilc/src/main.rs`

---

## Documentation Sync

When modifying compiler behavior:

1. Update spec if language semantics changed
2. Update design docs if rationale changed
3. Update `CLAUDE.md` if syntax/types/patterns changed
4. Update error code docs if new errors added
5. Update compiler design docs if architecture changed

---

## Debugging

Enable debug output:

```bash
SIGIL_DEBUG=tokens,ast,types,eval sigil run file.si
```

See `docs/compiler/design/appendices/D-debugging.md` for details.

---

## Quick Reference

| Task | Primary Files |
|------|---------------|
| New expression | `parser/grammar/expr.rs`, `typeck/infer/expr.rs`, `eval/exec/expr.rs` |
| New pattern | `patterns/<name>.rs`, `patterns/registry.rs` |
| New type | `types.rs`, `typeck/type_registry.rs` |
| New error | `diagnostic/mod.rs`, `diagnostic/problem.rs` |
| New test feature | `test/discovery.rs`, `test/runner.rs` |
