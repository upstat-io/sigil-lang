---
paths:
  - "**/patterns/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/`.

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

# Pattern System

## PatternDefinition Trait
**Required:**
- `name() -> &'static str`
- `required_props() -> &'static [&'static str]`
- `type_check(&mut TypeCheckContext) -> Type`
- `evaluate(&EvalContext, &mut dyn PatternExecutor) -> EvalResult`

**Optional:** `optional_props()`, `scoped_bindings()`, `can_fuse_with()`

## Registry
- Static ZST instances: `static RECURSE: RecursePattern = RecursePattern;`
- Enum dispatch on `FunctionExpKind`
- Patterns: Recurse, Parallel, Spawn, Timeout, Cache, With, Print, Panic, Catch

## PatternExecutor
- `eval(expr_id)` — evaluate expression
- `call(func, args)` — call function
- `lookup_capability(name)` — get capability
- `call_method(receiver, method, args)`

## Adding New Pattern
1. Create `ori_patterns/src/<name>.rs`
2. Implement `PatternDefinition`
3. Register in `registry.rs`
4. Add `FunctionExpKind` variant
5. Add parsing in `ori_parse`

## Key Files
- `lib.rs`: PatternDefinition trait
- `registry.rs`: Pattern lookup
- `recurse.rs`: Example impl
