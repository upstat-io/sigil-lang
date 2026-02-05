---
paths:
  - "**/eval/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/`.

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

## Debugging / Tracing

**Always use `ORI_LOG` first when debugging evaluation issues.** Tracing target: `ori_eval`.

```bash
ORI_LOG=ori_eval=debug ori run file.ori             # Method dispatch, function calls
ORI_LOG=ori_eval=trace ori run file.ori             # Every eval() call (very verbose)
ORI_LOG=ori_eval=debug ORI_LOG_TREE=1 ori run file.ori  # Hierarchical eval tree
ORI_LOG=ori_eval=debug,ori_types=debug ori run file.ori  # Eval + type checking together
```

**Instrumented functions**:
- `eval()` — trace level (hot path, per-expression)
- `eval_method_call()` — debug level (method dispatch chain)
- `eval_call()` — debug level (function calls)

**Tips**:
- Wrong value? Use `ORI_LOG=ori_eval=trace ORI_LOG_TREE=1` to trace evaluation step by step
- Method not found? Use `debug` to see which resolver in the dispatch chain is checked
- Infinite loop? Use `timeout 5 ORI_LOG=ori_eval=trace ori run file.ori` to see last eval before hang

## Key Files
- `lib.rs`: Interpreter, eval dispatch
- `interpreter/resolvers/`: MethodDispatcher
- `environment.rs`: Environment, scopes
