---
paths: **eval
---

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
