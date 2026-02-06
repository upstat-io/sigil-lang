---
paths:
  - "**/aot/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/` (includes Swift for ARC, Koka for effects, Lean 4 for RC).

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

# AOT Compilation

## Pipeline
Parse → TypeCheck → LLVM IR → Object → Link → Executable

## Building
```bash
cargo bl   # debug
cargo blr  # release
```
**Always build `ori_rt` alongside `oric`.**

## Runtime Discovery
1. Same directory as compiler
2. `<exe>/../lib/libori_rt.a`
3. `$ORI_WORKSPACE_DIR/target/`

## Symbol Mangling
Format: `_ori_<module>$<function>[<suffix>]`
- `@main` → `_ori_main`
- `math.@add` → `_ori_math$add`

## Linker Drivers
- Linux/macOS: `GccLinker`
- Windows: `MsvcLinker`
- WASM: `WasmLinker`

## Optimization
- `OptimizationLevel`: None, Less, Default, Aggressive
- `LtoMode`: None, ThinLocal, Thin, Full

## Key Files
- `target.rs`: Target triple
- `object.rs`: Object emission
- `mangle.rs`: Symbol mangling
- `runtime.rs`: Runtime discovery
- `linker/`: Linker drivers
