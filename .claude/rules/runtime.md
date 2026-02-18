---
paths:
  - "**/ori_rt/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/` (includes Swift for ARC, Koka for effects, Lean 4 for RC).

**Ori tooling is under construction** — bugs are usually in compiler, not user code. This is one system: every piece must fit for any piece to work. Fix every issue you encounter — no "unrelated", no "out of scope", no "pre-existing." If it's broken, research why and fix it.

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
- Memory: `ori_alloc`, `ori_free`, `ori_realloc`
- RefCount (V2): `ori_rc_alloc(size, align)`, `ori_rc_inc(data_ptr)`, `ori_rc_dec(data_ptr, drop_fn)`, `ori_rc_free(data_ptr, size, align)`
  - 8-byte header: `strong_count` at `data_ptr - 8`, data pointer returned directly
  - `drop_fn`: type-specialized, handles child Dec + calls `ori_rc_free`
- Strings: `ori_str_concat`, `ori_str_eq`
- I/O: `ori_print`, `ori_print_int`
- Panic: `ori_panic`, `ori_assert`
