---
paths:
  - "**/eval/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/lang_repos/`.

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

**Expression-based — NO `return`**: Body result IS return value. Exit via `?`/`break`/`panic`.

# Interpreter

## Architecture
- Tree-walking, arena threading
- Use callee's arena for function calls
- Enum dispatch for fixed sets

## Method Dispatch Chain
- Priority 0: UserRegistryResolver — User impls + `#[derive]`
- Priority 1: CollectionMethodResolver — map/filter/fold
- Priority 2: BuiltinMethodResolver — Primitives

## Value Types
- Primitives: `Int`, `Float`, `Bool`, `Str`, `Char`, `Byte`, `Void`, `Duration`, `Size`
- Collections: `List`, `Map`, `Tuple` (all `Heap<T>`)
- Wrappers: `Some`, `None`, `Ok`, `Err`
- User: `Struct`, `Variant`, `Newtype`
- Functions: `Function`, `FunctionVal`

## Environment
- Scope stack with `LocalScope<T>` = `Rc<RefCell<T>>`
- `env.capture()` for closures

## RAII Scope Guards
- `scoped()` → `ScopedInterpreter`
- `with_env_scope(|s| { ... })`
- `with_binding(name, value, mutability, |s| { ... })`

## Key Files
- `lib.rs`: Interpreter, eval dispatch
- `interpreter/resolvers/`: MethodDispatcher
- `environment.rs`: Environment, scopes
