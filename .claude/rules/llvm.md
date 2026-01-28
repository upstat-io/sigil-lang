---
paths: **/llvm**
---

# LLVM Development

The ori_llvm crate is excluded from the main workspace to avoid LLVM linking overhead during normal development.

## Docker: Only for Unit Tests

**Docker is ONLY required for running LLVM unit tests.** Everything else uses normal cargo commands.

```bash
# Run LLVM unit tests (requires Docker)
./llvm-test

# First time: build the container image (slow, do once)
./docker/llvm/build.sh
```

## Standard Cargo Commands (No Docker)

All other LLVM development uses normal cargo commands with the manifest path:

```bash
# Build ori_llvm crate
cargo build --manifest-path compiler/ori_llvm/Cargo.toml

# Run clippy on ori_llvm
cargo clippy --manifest-path compiler/ori_llvm/Cargo.toml

# Format ori_llvm code
cargo fmt --manifest-path compiler/ori_llvm/Cargo.toml

# Check ori_llvm (fast compile check)
cargo check --manifest-path compiler/ori_llvm/Cargo.toml
```

Or use the convenience scripts:

```bash
./llvm-build     # cargo build
./llvm-clippy    # cargo clippy
./fmt-all        # formats workspace + LLVM crate
```

## Why Docker for Tests Only

Docker provides a controlled environment with LLVM 17 properly installed and linked. This is needed for:
- Running tests that actually execute LLVM codegen
- Test runs with `--backend=llvm` flag
- Building the compiler with the `llvm` feature enabled

Building and static analysis (clippy, check) work on the host because they don't require linking against LLVM libraries at runtime.

## Container Resource Limits

When running tests, the container is constrained (defaults: 4GB RAM, 2 CPUs):

```bash
# Override memory limit
LLVM_MEMORY=8g ./llvm-test

# Override CPU limit
LLVM_CPUS=4 ./llvm-test
```

## Summary

| Command | Docker? | How |
|---------|---------|-----|
| Build | No | `cargo build --manifest-path compiler/ori_llvm/Cargo.toml` |
| Clippy | No | `cargo clippy --manifest-path compiler/ori_llvm/Cargo.toml` |
| Format | No | `cargo fmt --manifest-path compiler/ori_llvm/Cargo.toml` |
| Check | No | `cargo check --manifest-path compiler/ori_llvm/Cargo.toml` |
| **Tests** | **Yes** | `./llvm-test` |
| Edit source | No | Direct file editing |
