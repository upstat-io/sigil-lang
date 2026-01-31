---
paths: **/ori_ir/**
---

**Fix issues encountered in code you touch. No "pre-existing" exceptions.**

**Do it properly, not just simply. Correct architecture over quick hacks; no shortcuts or "good enough" solutions.**

# IR (AST)

## Arena Allocation

- `ExprId(u32)` indices, not `Box<Expr>` (50% memory savings)
- Flat `Vec` storage, child references use indices
- Pre-allocate: ~1 expr per 20 bytes source

## ID Newtypes

- `#[repr(transparent)]` wrapper around `u32`
- Derive: `Copy, Clone, Eq, PartialEq, Hash, Debug`
- Sentinel: `INVALID = u32::MAX`, `.is_valid()` predicate
- Methods: `.index()` → `usize`, `.raw()` → `u32`

## TypeId Sharding

- Bits 31-28: shard (16 shards)
- Bits 27-0: local index (268M per shard)
- Pre-interned (shard 0): INT=0, FLOAT=1, BOOL=2, STR=3, CHAR=4, BYTE=5, VOID=6, NEVER=7

## Range Types

- `ExprRange { start: u32, len: u16 }` = 8 bytes (not `Vec`)
- `define_range!` macro generates: `.new()`, `.is_empty()`, `.len()`, `EMPTY`
- Types: `ParamRange`, `GenericParamRange`, `ArmRange`, `MapEntryRange`

## Span

- 8 bytes: `start: u32, end: u32` (byte offsets)
- `Span::DUMMY` for generated code
- `try_from_range()` fallible, `from_range()` panics

## Name Interning

- `Name(u32)` with sharded layout (4-bit shard + 28-bit local)
- `Name::EMPTY` at (shard=0, local=0)

## Expression Pattern

- `Expr { kind: ExprKind, span: Span }`
- All children use `ExprId`, not boxed
- `#[cold]` on panic helpers for overflow

## Visitor

- `Visitor<'ast>` trait + `walk_*()` functions
- Visitor mutates own state; AST immutable

## Key Files

| File | Purpose |
|------|---------|
| `arena.rs` | ExprArena, capacity, ranges |
| `expr_id.rs` | ExprId newtype |
| `type_id.rs` | TypeId sharding, pre-interned |
| `name.rs` | Name interning |
| `span.rs` | Span, DUMMY, error handling |
| `visitor.rs` | Visitor trait, walk functions |
