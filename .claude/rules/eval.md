---
paths:
  - "**/eval/**"
---

**Ori is under construction.** Rust tooling is trusted. Ori tooling (lexer, parser, type checker, evaluator, test runner) is NOT. When something fails, investigate Ori infrastructure first—the bug is often in the compiler/tooling, not user code or tests.

**Fix issues encountered in code you touch. No "pre-existing" exceptions.**

**Do it properly, not just simply. Correct architecture over quick hacks; no shortcuts or "good enough" solutions.**

**⚠️ Ori is EXPRESSION-BASED — NO `return`**: Functions evaluate their body expression; the result IS the return value. No `ExprKind::Return` exists. Control flow: `?` (error propagation), `break` (loops), `panic`.

# Interpreter

## Architecture

- Tree-walking interpreter, arena threading
- Use callee's arena when calling functions, not caller's
- Direct enum dispatch for fixed sets (not `dyn Trait`)

## Method Dispatch Chain

| Priority | Resolver | Handles |
|----------|----------|---------|
| 0 | UserRegistryResolver | User impls + `#[derive]` |
| 1 | CollectionMethodResolver | map/filter/fold (need evaluator) |
| 2 | BuiltinMethodResolver | Primitive methods |

- `MethodDispatcher` chains resolvers, tries in priority order
- `MethodResolverKind` enum (not `Box<dyn>`)

## Value Representation

- Primitives: `Int`, `Float`, `Bool`, `Str`, `Char`, `Byte`, `Void`, `Duration`, `Size`
- Collections: `List(Heap<Vec>)`, `Map(Heap<BTreeMap>)`, `Tuple(Heap<Vec>)`
- Wrappers: `Some(Heap<Box>)`, `None`, `Ok(Heap<Box>)`, `Err(Heap<Box>)`
- User types: `Struct`, `Variant`, `VariantConstructor`, `Newtype`, `NewtypeConstructor`
- Functions: `Function`, `MemoizedFunction`, `FunctionVal`
- Other: `Range`, `ModuleNamespace`, `TypeRef`, `Error`
- `Heap<T>` wrapper enforces factory methods, `Arc<T>` internally

## Environment

- Scope stack with `LocalScope<T>` = `Rc<RefCell<T>>`
- Lexical scoping, shadowing allowed
- `env.capture()` for closure environments

## RAII Scope Guards

- `scoped()` → `ScopedInterpreter` (Drop pops scope)
- `with_env_scope(|s| { ... })`
- `with_binding(name, value, mutability, |s| { ... })`
- `with_bindings(vec![...], |s| { ... })`

## Key Files

| File | Purpose |
|------|---------|
| `lib.rs` | Interpreter struct, evaluate dispatch |
| `interpreter/resolvers/mod.rs` | MethodDispatcher, resolver chain |
| `environment.rs` | Environment, LocalScope |
| `interpreter/scope_guard.rs` | ScopedInterpreter, RAII |

## Backends

| Backend | Crate | Usage |
|---------|-------|-------|
| Interpreter | `ori_eval` | Default, tree-walking |
| LLVM JIT | `ori_llvm` | `--backend=llvm` flag |
| LLVM AOT | `ori_llvm` | `ori build` command |

The interpreter is the reference implementation. LLVM backends must produce identical results.
