---
paths: **/llvm/**
---

**Fix issues encountered in code you touch. No "pre-existing" exceptions.**

**Do it properly, not just simply. Correct architecture over quick hacks; no shortcuts or "good enough" solutions.**

# LLVM Development

The `ori_llvm` crate is excluded from main workspace to avoid LLVM linking overhead.

## Docker Required For

- Running LLVM unit tests
- Running clippy (needs LLVM headers)
- Building with `llvm` feature
- Test runs with `--backend=llvm`

## Commands

| Command | Docker | Script |
|---------|--------|--------|
| Build | Yes | `./llvm-build` |
| Clippy | Yes | `./llvm-clippy` |
| Tests | Yes | `./llvm-test` |
| Format | No | `cargo fmt --manifest-path compiler/ori_llvm/Cargo.toml` |

## First Time Setup

```bash
./docker/llvm/build.sh  # build container image (slow, once)
```

## Resource Limits

```bash
LLVM_MEMORY=8g ./llvm-test  # override memory (default 4GB)
LLVM_CPUS=4 ./llvm-test     # override CPUs (default 2)
```

## Test Coverage

**Always use `./docker/llvm/run.sh` for coverage** - the crate requires LLVM to compile.

```bash
# Full crate coverage
./docker/llvm/run.sh "cargo tarpaulin --manifest-path compiler/ori_llvm/Cargo.toml --lib --out Stdout"

# Coverage for specific module (filter tests by name)
./docker/llvm/run.sh "cargo tarpaulin --manifest-path compiler/ori_llvm/Cargo.toml --lib --out Stdout -- linker"

# Coverage with HTML report
./docker/llvm/run.sh "cargo tarpaulin --manifest-path compiler/ori_llvm/Cargo.toml --lib --out Html"
```

**DO NOT**:
- Try to install coverage tools inside docker (read-only cargo registry)
- Run tarpaulin outside docker (ori_llvm requires LLVM headers)
- Use cargo-llvm-cov (installation fails in container)
