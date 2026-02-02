---
paths: **/aot/**
---

**Ori is under construction.** Rust tooling is trusted. Ori tooling (lexer, parser, type checker, evaluator, test runner) is NOT. When something fails, investigate Ori infrastructure first—the bug is often in the compiler/tooling, not user code or tests.

**Fix issues encountered in code you touch. No "pre-existing" exceptions.**

**Do it properly, not just simply. Correct architecture over quick hacks; no shortcuts or "good enough" solutions.**

# AOT Compilation

## Architecture

- Pipeline: Parse → TypeCheck → LLVM IR → Object → Link → Executable
- Extends JIT infrastructure with target config, object emission, linking
- Platform-agnostic design; linker drivers handle platform specifics

## Building

```bash
cargo bl   # debug: builds oric + ori_rt with LLVM
cargo blr  # release: builds oric + ori_rt with LLVM
```

**Critical**: Always build `ori_rt` alongside `oric`. Cargo only builds `rlib` as dependency; the `staticlib` (`libori_rt.a`) must be explicitly requested.

## Runtime Discovery

Discovery order (like rustc's sysroot):

1. Same directory as compiler (`target/release/libori_rt.a`)
2. Installed layout (`<exe>/../lib/libori_rt.a`)
3. Workspace fallback (`$ORI_WORKSPACE_DIR/target/{release,debug}/`)

If not found, error lists searched paths. See `runtime.rs`.

## Symbol Mangling

Format: `_ori_<module>$<function>[<suffix>]`

| Ori Symbol | Mangled |
|------------|---------|
| `@main` | `_ori_main` |
| `math.@add` | `_ori_math$add` |
| `int::Eq.@equals` | `_ori_int$$Eq$equals` |
| `Option.@some<int>` | `_ori_Option$A$some$Gint` |

Use `Mangler` struct; `demangle()` for reverse.

## Linker Drivers

| Platform | Driver | Backend |
|----------|--------|---------|
| Linux/macOS | `GccLinker` | gcc/clang |
| Windows | `MsvcLinker` | link.exe |
| WebAssembly | `WasmLinker` | wasm-ld |

- `LinkerDriver::new(&target)` auto-detects
- `LinkInput` configures objects, libraries, output
- Always link `ori_rt` for runtime functions

## Optimization

- Uses LLVM new pass manager
- `OptimizationLevel`: None, Less, Default, Aggressive
- `LtoMode`: None, ThinLocal, Thin, Full
- Configure via `OptimizationConfig`

## Key Files

| File | Purpose |
|------|---------|
| `target.rs` | Target triple, CPU features |
| `object.rs` | Object file emission |
| `mangle.rs` | Symbol mangling/demangling |
| `runtime.rs` | Runtime library discovery |
| `linker/mod.rs` | Linker driver abstraction |
| `linker/gcc.rs` | GCC/Clang linker |
| `linker/msvc.rs` | MSVC linker |
| `linker/wasm.rs` | WebAssembly linker |
| `passes.rs` | Optimization passes |
| `debug.rs` | DWARF/CodeView debug info |
| `multi_file.rs` | Multi-file compilation |
| `incremental/` | Incremental compilation |
| `wasm.rs` | WASM-specific config |
