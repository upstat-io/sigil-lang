---
paths:
  - "**/typeck/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/` (includes Swift for ARC, Koka for effects, Lean 4 for RC).

**Ori tooling is under construction** — bugs are usually in compiler, not user code. This is one system: every piece must fit for any piece to work. Fix every issue you encounter — no "unrelated", no "out of scope", no "pre-existing." If it's broken, research why and fix it.

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

## Derived Trait Registration (Sync Point)

`check/registration/mod.rs` registers trait definitions and derived impl signatures. This is a **sync point** — every `DerivedTrait` variant from `ori_ir` must be registered here with correct method signatures.

**DO NOT** modify derived trait registration without checking that the evaluator (`ori_eval/interpreter/derived_methods.rs`) and codegen (`ori_llvm/codegen/derive_codegen.rs`) agree on method signatures. See CLAUDE.md "Adding a New Derived Trait" checklist.

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

## Debugging / Tracing

**Always use `ORI_LOG` first when debugging type checking issues.** Tracing target: `ori_types` (typeck lives in the same crate).

```bash
ORI_LOG=ori_types=debug ori check file.ori          # Module-level checking phases
ORI_LOG=ori_types=trace ori check file.ori          # Per-expression inference/checking
ORI_LOG=ori_types=trace ORI_LOG_TREE=1 ori check file.ori  # Full call tree with nesting
```

**What each level shows**:
- `debug`: Module check start/end, signature collection, body checking phases, type errors
- `trace`: Every `infer_expr()` and `check_expr()` call — very verbose, use for specific files

**Tips**:
- Unification failure? Trace shows both sides before unify
- Wrong type inferred? Use tree output to see bidirectional check/infer flow
- Salsa cache issues? Add `oric=debug` to see query re-execution

## Key Files
- `checker/components.rs`: TypeChecker struct
- `checker/expressions/`: Expression checking
- `operators.rs`: Operator type rules
- `registry/trait_registry.rs`: TraitRegistry
