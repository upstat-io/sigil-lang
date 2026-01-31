---
paths: **ori_types
---

# Type System

## Dual Representation

- **Type** (external): boxed, `Box<Type>` for recursive children
- **TypeData** (internal): `TypeId` refs, O(1) equality via interning

## Type Enum Variants

- Primitives: `Int`, `Float`, `Bool`, `Str`, `Char`, `Byte`, `Unit`, `Never`
- Special: `Duration`, `Size`
- Compound: `Function`, `Tuple`, `List`, `Map`, `Set`, `Option`, `Result`, `Range`, `Channel`
- Generic: `Named`, `Applied`, `Var`, `Projection`, `ModuleNamespace`
- Error: `Error`

## Type Interning

- **Sharded**: 16 shards, `FxHashMap<TypeData, u32>` + `Vec<TypeData>` per shard
- **Pre-interned**: shard 0 indices 0-10 (Int, Float, Bool, Str, Char, Byte, Unit, Never, Duration, Size, Error)
- **SharedTypeInterner**: `Arc<TypeInterner>` with per-shard `RwLock`
- **O(1) dedup**: map lookup before insert

## Inference Context

- `InferenceContext`: mutable state for unification
- `TypeVar` mapping: `HashMap<TypeVar, Type>`
- `fresh_var()`: counter-based generation
- Unification: structural with occurs check
- Generalization: free vars → quantified

## Size Assertions

- `static_assert_size!` macro prevents enum bloat
- `Type` ≤ 40 bytes, `TypeVar` = 4 bytes

## Salsa Compatibility

- All types: `Clone, Eq, PartialEq, Hash, Debug`
- No `Arc<Mutex<T>>` or function pointers

## Key Files

| File | Purpose |
|------|---------|
| `core.rs` | Type enum, variants |
| `data.rs` | TypeData (internal), TypeVar |
| `type_interner.rs` | Interning, sharding |
| `context.rs` | InferenceContext, unification |
