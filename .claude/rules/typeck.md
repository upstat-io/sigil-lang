---
paths:
  - "**/typeck/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/lang_repos/`.

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

**Expression-based — NO `return`**: Body type IS return type. Exit via `?`/`break`/`panic`.

# Type Checking

## Architecture (5 Components)
- **CheckContext**: immutable arena/interner refs
- **InferenceState**: mutable ctx, env, expr_types
- **Registries**: pattern, type, trait
- **DiagnosticState**: errors, queue, source
- **ScopeContext**: function sigs, impl Self, capabilities

## Registries
- **TypeRegistry**: `register_struct()`, `get_by_name()`, O(1) variant lookup
- **TraitRegistry**: coherence (E2010), assoc types, method cache (RefCell)

## RAII Scope Guards
- `with_capability_scope(caps, |c| { ... })`
- `with_impl_scope(self_ty, |c| { ... })`
- `with_infer_env_scope(|c| { ... })`

## Type Inference
- Hindley-Milner with extensions
- Bidirectional: check mode vs infer mode
- Unification with occurs check
- Generalization: free vars → quantified

## Error Codes
- E2001: Type mismatch
- E2009: Trait bound not satisfied
- E2010: Coherence violation

## Key Files
- `checker/components.rs`: TypeChecker struct
- `checker/expressions/`: Expression checking
- `operators.rs`: Operator type rules
- `registry/trait_registry.rs`: TraitRegistry
