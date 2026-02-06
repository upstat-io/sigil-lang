---
paths:
  - "**/Cargo.toml"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/` (includes Swift for ARC, Koka for effects, Lean 4 for RC).

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

# Cargo Configuration

**Do NOT edit Cargo.toml without explicit user permission.**

## Aliases (`.cargo/config.toml`)
- `cargo t`: `test --workspace`
- `cargo st`: `run -p oric -- test tests/`
- `cargo c`: `check --workspace`
- `cargo b`: `build --workspace`
- `cargo cl`: `clippy --workspace`
- `cargo bl`: `build -p oric -p ori_rt --features llvm`
- `cargo blr`: `build -p oric -p ori_rt --features llvm --release`
- `cargo cll`: `clippy -p ori_llvm -p ori_rt`

## Workspace Lints
- `unsafe_code = "deny"` (except `ori_rt`)
- `dead_code = "deny"`
- `clippy::unwrap_used = "deny"`
- `clippy::expect_used = "deny"`

## Key Files
- `Cargo.toml`: Workspace config
- `.cargo/config.toml`: Aliases, LLVM path
