---
paths:
  - "**/ori_ir/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/`.

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

# IR (AST)

## Arena Allocation
- `ExprId(u32)` indices, not `Box<Expr>`
- Flat `Vec` storage, child references use indices
- Pre-allocate: ~1 expr per 20 bytes source

## ID Newtypes
- `#[repr(transparent)]` wrapper around `u32`
- Derive: `Copy, Clone, Eq, PartialEq, Hash, Debug`
- Sentinel: `INVALID = u32::MAX`, `.is_valid()`

## TypeId Layout (aligned with ori_types::Idx)
- Flat u32 index (no sharding)
- Primitives 0-11 match Idx: INT=0..ORDERING=11
- Markers: INFER=12, SELF_TYPE=13 (not stored in type pool)
- VOID is alias for UNIT (index 6)
- Compounds start at FIRST_COMPOUND=64

## Range Types
- `ExprRange { start: u32, len: u16 }` = 8 bytes
- `define_range!` macro: `.new()`, `.is_empty()`, `.len()`, `EMPTY`

## Span
- 8 bytes: `start: u32, end: u32`
- `Span::DUMMY` for generated code

## Name Interning
- `Name(u32)` with sharded layout
- `Name::EMPTY` at (shard=0, local=0)

## Visitor
- `Visitor<'ast>` trait + `walk_*()` functions
- Visitor mutates own state; AST immutable

## Key Files
- `arena.rs`: ExprArena, ranges
- `type_id.rs`: TypeId (parser-level type index, aligned with Idx)
- `name.rs`: Name interning
- `visitor.rs`: Visitor trait
