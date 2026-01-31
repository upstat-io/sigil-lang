---
paths: **llvm**
---

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
