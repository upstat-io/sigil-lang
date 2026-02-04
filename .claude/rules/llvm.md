---
paths:
  - "**/llvm/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/lang_repos/`.

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

# LLVM Development

LLVM 17 required. Path in `.cargo/config.toml`.

## Commands
- Build: `cargo bl` (debug), `cargo blr` (release)
- Clippy: `cargo cll`
- Tests: `./llvm-test`
- All: `./test-all`

## Building with LLVM
```bash
cargo bl   # debug: oric + ori_rt with LLVM
cargo blr  # release
```
**Always build both `oric` AND `ori_rt`** — Cargo only builds rlib; staticlib must be explicit.

## Runtime Discovery
1. Same directory as compiler
2. Installed layout: `<exe>/../lib/libori_rt.a`
3. Workspace: `$ORI_WORKSPACE_DIR/target/`

## Key Files
- `.cargo/config.toml`: LLVM path, aliases
- `compiler/ori_llvm/`: LLVM backend
- `compiler/ori_rt/`: Runtime library
- `aot/runtime.rs`: Runtime discovery
