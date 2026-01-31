---
paths: **patterns
---

# Pattern System

## PatternDefinition Trait

**Required:**
- `name() -> &'static str`
- `required_props() -> &'static [&'static str]`
- `type_check(&mut TypeCheckContext) -> Type`
- `evaluate(&EvalContext, &mut dyn PatternExecutor) -> EvalResult`

**Optional (with defaults):**
- `optional_props()`, `optional_args()`, `scoped_bindings()`
- `allows_arbitrary_props()`, `signature()`, `can_fuse_with()`

## Registry

- Static ZST instances: `static RECURSE: RecursePattern = RecursePattern;`
- Enum dispatch on `FunctionExpKind` (not HashMap)
- 9 patterns: Recurse, Parallel, Spawn, Timeout, Cache, With, Print, Panic, Catch

## PatternExecutor Abstraction

- `eval(expr_id)` — evaluate expression
- `call(func, args)` — call function value
- `lookup_capability(name)` — get capability
- `call_method(receiver, method, args)` — call method
- `lookup_var(name)`, `bind_var(name, value)`

## Context Types

- **EvalContext**: `get_prop()`, `eval_prop()`, `prop_span()`, `error_with_prop_span()`
- **TypeCheckContext**: `get_prop_type()`, `fresh_var()`, `list_of()`, `option_of()`

## Adding New Pattern

1. Create `ori_patterns/src/<name>.rs`
2. Implement `PatternDefinition` trait
3. Register in `registry.rs`
4. Add `FunctionExpKind` variant in `ori_ir`
5. Add parsing in `ori_parse`

## Key Files

| File | Purpose |
|------|---------|
| `lib.rs` | PatternDefinition trait, contexts |
| `registry.rs` | Pattern lookup, static instances |
| `recurse.rs` | Example implementation |
