---
paths: **llvm**
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

## Docker Commands

Docker provides a controlled environment with LLVM 17 properly installed and linked. This is needed for:
- Running tests that actually execute LLVM codegen
- Running clippy (requires LLVM headers for `llvm-sys` crate)
- Building the compiler with the `llvm` feature enabled
- Test runs with `--backend=llvm` flag

Use the convenience scripts:

```bash
./llvm-test      # Run LLVM unit tests (Docker)
./llvm-clippy    # Run clippy on ori_llvm (Docker)
./llvm-build     # Build ori_llvm crate (Docker)
./fmt-all        # formats workspace + LLVM crate (no Docker needed)
```

## Standard Cargo Commands (No Docker)

Formatting doesn't require LLVM libraries:

```bash
# Format ori_llvm code
cargo fmt --manifest-path compiler/ori_llvm/Cargo.toml
```

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
| Build | Yes | `./llvm-build` |
| Clippy | Yes | `./llvm-clippy` |
| Format | No | `cargo fmt --manifest-path compiler/ori_llvm/Cargo.toml` |
| Tests | Yes | `./llvm-test` |
| Edit source | No | Direct file editing |
