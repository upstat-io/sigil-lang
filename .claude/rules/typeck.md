---
paths: **typeck
---

# Type Checking

## Architecture (5 Components)

- **CheckContext**: immutable arena/interner refs
- **InferenceState**: mutable ctx, env, expr_types
- **Registries**: pattern, type, trait registries
- **DiagnosticState**: errors, queue, source
- **ScopeContext**: function sigs, impl Self, capabilities

## Registries

- **TypeRegistry**: `register_struct()`, `get_by_name()`, O(1) variant lookup
- **TraitRegistry**: coherence (E2010), assoc types, method cache (RefCell)
- Cache invalidation: clear on trait/impl registration

## Error Handling

- **Accumulate**: `push_error()` collects all, never bails early
- **E2009**: trait bound not satisfied
- **E2010**: coherence violation (duplicate impl)
- **E2015-E2018**: type param ordering, missing args, assoc types

## RAII Scope Guards

- `with_capability_scope(caps, |c| { ... })`
- `with_impl_scope(self_ty, |c| { ... })`
- `with_infer_env_scope(|c| { ... })`
- `with_infer_bindings(bindings, |c| { ... })`

## Key Files

| File | Purpose |
|------|---------|
| `checker/components.rs` | TypeChecker struct, 5 components |
| `registry/mod.rs` | TypeRegistry |
| `registry/trait_registry.rs` | TraitRegistry, coherence |
| `checker/trait_registration.rs` | Trait/impl validation |
| `checker/bound_checking.rs` | Trait bound verification |
