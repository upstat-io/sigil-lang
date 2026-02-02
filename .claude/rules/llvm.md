---
paths: **/llvm/**
---

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
| Build | `cargo build -p ori_llvm` |
| Clippy | `cargo clippy -p ori_llvm` |
| Tests | `./llvm-test` or `cargo test -p ori_llvm -p ori_rt` |
| Format | `cargo fmt -p ori_llvm` |
| All tests | `./test-all` |

## Building with LLVM Feature

The `ori build` command requires the `llvm` feature:

```bash
cargo build -p oric --features llvm          # debug
cargo build -p oric --features llvm --release # release
```

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

## Key Files

| File | Purpose |
|------|---------|
| `.cargo/config.toml` | LLVM path configuration |
| `compiler/ori_llvm/` | LLVM backend crate |
| `compiler/ori_rt/` | Runtime library for AOT |
