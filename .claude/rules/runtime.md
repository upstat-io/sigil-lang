---
paths:
  - "**/ori_rt/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/lang_repos/`.

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

# Runtime Library (ori_rt)

C-ABI functions for LLVM-generated AOT code.

## Build Outputs
- **rlib**: Rust consumers (JIT)
- **staticlib**: AOT linking (`libori_rt.a`)

Both built with `cargo build -p ori_rt`.

## FFI Conventions
- All functions: `#[no_mangle] extern "C"`
- `#[repr(C)]` for FFI types
- Pointers from LLVM guaranteed valid

## Type Representations
- `str` → `{ len: i64, data: *const u8 }`
- `[T]` → `{ len: i64, cap: i64, data: *mut u8 }`
- `Option<T>` → `{ tag: i8, value: T }`

## Functions
- Memory: `ori_alloc`, `ori_free`
- RefCount: `ori_rc_new`, `ori_rc_inc`, `ori_rc_dec`
- Strings: `ori_str_concat`, `ori_str_eq`
- I/O: `ori_print`, `ori_print_int`
- Panic: `ori_panic`, `ori_assert`
