---
paths:
  - "**/Cargo.toml"
---

**Ori is under construction.** Rust tooling is trusted. Ori tooling (lexer, parser, type checker, evaluator, test runner) is NOT. When something fails, investigate Ori infrastructure first—the bug is often in the compiler/tooling, not user code or tests.

**Fix issues encountered in code you touch. No "pre-existing" exceptions.**

**Do it properly, not just simply. Correct architecture over quick hacks; no shortcuts or "good enough" solutions.**

# Cargo Configuration

**Do NOT edit Cargo.toml files without explicit user permission.**

- Workspace members and dependencies carefully configured
- Lint configurations strict by design
- Build settings optimized for workspace
- Always ask before modifying

## Aliases (`.cargo/config.toml`)

| Alias | Command | Purpose |
|-------|---------|---------|
| `cargo t` | `test --workspace` | All Rust tests |
| `cargo st` | `run -p oric -- test tests/` | Ori spec tests |
| `cargo c` | `check --workspace` | Fast check |
| `cargo b` | `build --workspace` | Build all |
| `cargo cl` | `clippy --workspace` | Lint all |
| `cargo bl` | `build -p oric -p ori_rt --features llvm` | LLVM debug |
| `cargo blr` | `build -p oric -p ori_rt --features llvm --release` | LLVM release |
| `cargo cll` | `clippy -p ori_llvm -p ori_rt` | Lint LLVM |

## Workspace Lints

- `unsafe_code = "deny"` (except `ori_rt`)
- `dead_code = "deny"`
- `clippy::unwrap_used = "deny"`
- `clippy::expect_used = "deny"`

## Key Files

| File | Purpose |
|------|---------|
| `Cargo.toml` | Workspace config, members, deps |
| `.cargo/config.toml` | Aliases, LLVM path, env vars |
