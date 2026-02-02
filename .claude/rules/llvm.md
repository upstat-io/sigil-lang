---
paths: **/llvm/**
---

**Ori is under construction.** Rust tooling is trusted. Ori tooling (lexer, parser, type checker, evaluator, test runner) is NOT. When something fails, investigate Ori infrastructure first—the bug is often in the compiler/tooling, not user code or tests.

**Fix issues encountered in code you touch. No "pre-existing" exceptions.**

**Do it properly, not just simply. Correct architecture over quick hacks; no shortcuts or "good enough" solutions.**

# LLVM Development

The `ori_llvm` and `ori_rt` crates are part of the main workspace. LLVM 17 path is configured in `.cargo/config.toml`.

## Requirements

- **LLVM 17** installed at `/usr/lib/llvm-17` (Ubuntu/Debian: `apt install llvm-17-dev`)
- Path configured via `LLVM_SYS_170_PREFIX` in `.cargo/config.toml`

## Commands

| Command | Script |
|---------|--------|
| Build (LLVM) | `cargo build -p ori_llvm -p ori_rt` |
| Build (oric + AOT) | `cargo bl` or `cargo blr` (release) |
| Clippy | `cargo cll` or `cargo clippy -p ori_llvm -p ori_rt` |
| Tests | `./llvm-test` or `cargo test -p ori_llvm -p ori_rt` |
| Format | `cargo fmt -p ori_llvm` |
| All tests | `./test-all` |

## Building with LLVM Feature

The `ori build` command requires both the `llvm` feature AND the `ori_rt` staticlib:

```bash
# IMPORTANT: Always build both oric AND ori_rt for AOT compilation
cargo build -p oric -p ori_rt --features llvm          # debug
cargo build -p oric -p ori_rt --features llvm --release # release

# Or use the cargo aliases:
cargo bl   # debug
cargo blr  # release
```

**Why both?** Cargo only builds `ori_rt.rlib` (Rust library) as a dependency. The `libori_rt.a` staticlib for AOT linking is a separate artifact that must be explicitly requested. If you only build `oric`, `ori build` will fail with "libori_rt.a not found".

## Docker (Fallback)

Docker is still available for environments without local LLVM:

```bash
./docker/llvm/build.sh                    # build container (once)
./docker/llvm/run.sh cargo test           # run tests in container
./docker/llvm/run.sh ori test --backend=llvm tests/  # Ori tests
```

## Test Coverage

```bash
# Full crate coverage
cargo tarpaulin -p ori_llvm --lib --out Stdout

# Coverage for specific module
cargo tarpaulin -p ori_llvm --lib --out Stdout -- linker

# Coverage with HTML report
cargo tarpaulin -p ori_llvm --lib --out Html
```

## Runtime Library Discovery

AOT compilation requires `libori_rt.a`. The compiler discovers it via:

1. **Same directory as compiler** (dev builds): `target/release/libori_rt.a`
2. **Installed layout**: `<exe>/../lib/libori_rt.a` (e.g., `/usr/local/lib/`)
3. **Workspace fallback**: `$ORI_WORKSPACE_DIR/target/{release,debug}/`

If not found, error shows searched paths and instructions. See `compiler/ori_llvm/src/aot/runtime.rs`.

## Key Files

| File | Purpose |
|------|---------|
| `.cargo/config.toml` | LLVM path configuration, cargo aliases |
| `compiler/ori_llvm/` | LLVM backend crate |
| `compiler/ori_rt/` | Runtime library for AOT |
| `compiler/ori_llvm/src/aot/runtime.rs` | Runtime discovery logic |
