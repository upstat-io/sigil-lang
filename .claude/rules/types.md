---
paths:
  - "**/ori_types/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/`.

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

# Type System

## Dual Representation
- **Type** (external): boxed, `Box<Type>` for recursive
- **TypeData** (internal): `TypeId` refs, O(1) equality via interning

## Type Variants
- Primitives: `Int`, `Float`, `Bool`, `Str`, `Char`, `Byte`, `Unit`, `Never`
- Special: `Duration`, `Size`
- Compound: `Function`, `Tuple`, `List`, `Map`, `Option`, `Result`, `Range`
- Generic: `Named`, `Applied`, `Var`, `Projection`

## Type Interning
- 16 shards, `FxHashMap<TypeData, u32>` + `Vec<TypeData>` per shard
- Pre-interned in shard 0: primitives
- O(1) dedup via map lookup

## Inference
- `InferenceContext`: mutable state
- `fresh_var()`: counter-based
- Unification with occurs check
- Generalization: free vars → quantified

## Salsa Compatibility
- All types: `Clone, Eq, PartialEq, Hash, Debug`
- No `Arc<Mutex<T>>` or fn pointers

## Key Files
- `core.rs`: Type enum
- `data.rs`: TypeData, TypeVar
- `type_interner.rs`: Interning
- `context.rs`: InferenceContext
