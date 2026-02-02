---
paths: **/ori_rt/**
---

**Fix issues encountered in code you touch. No "pre-existing" exceptions.**

**Do it properly, not just simply. Correct architecture over quick hacks; no shortcuts or "good enough" solutions.**

# Runtime Library (ori_rt)

## Purpose

Provides C-ABI functions called by LLVM-generated code for AOT-compiled programs.

## Build Outputs

- **rlib**: For Rust consumers (JIT via `ori_llvm`)
- **staticlib**: For AOT linking (`libori_rt.a`)

Both built with `cargo build -p ori_rt`. The staticlib is required for `ori build`.

## FFI Conventions

- All functions: `#[no_mangle] extern "C"`
- Pointers from LLVM code are guaranteed valid
- Use `#[repr(C)]` for all types passed across FFI boundary
- Parameter order matches LLVM codegen expectations

## Type Representations

| Ori Type | C Representation |
|----------|------------------|
| `str` | `OriStr { len: i64, data: *const u8 }` |
| `[T]` | `OriList { len: i64, cap: i64, data: *mut u8 }` |
| `Option<T>` | `OriOption<T> { tag: i8, value: T }` |

## Function Categories

| Category | Functions |
|----------|-----------|
| Memory | `ori_alloc`, `ori_free`, `ori_realloc` |
| Reference Counting | `ori_rc_new`, `ori_rc_inc`, `ori_rc_dec` |
| Strings | `ori_str_concat`, `ori_str_eq`, `ori_str_len` |
| Collections | `ori_list_new`, `ori_list_free`, `ori_list_push` |
| I/O | `ori_print`, `ori_print_int`, `ori_print_float` |
| Panic | `ori_panic`, `ori_assert` |

## Allowed Clippy Lints

These are intentionally allowed for FFI code:

- `cast_possible_truncation` - ABI uses i64, casts are safe
- `not_unsafe_ptr_arg_deref` - extern "C" entry points, not Rust API
- `cast_sign_loss`, `cast_possible_wrap` - controlled FFI conversions

## Key Files

| File | Purpose |
|------|---------|
| `lib.rs` | All runtime functions and types |
| `Cargo.toml` | Dual crate-type: rlib + staticlib |
