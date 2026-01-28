---
paths: **/llvm**
---

# LLVM Development - Docker Required

**MANDATORY: All LLVM-related compilation and execution MUST run inside a Docker container.**

LLVM version mismatches and linking issues can cause catastrophic failures to the host development environment.

## Rules

1. **NEVER** run cargo commands for ori_llvm on the host
2. **ALWAYS** use `./docker/llvm/run.sh` for any cargo command involving ori_llvm

When editing LLVM code, you MUST test your changes using:
```bash
./docker/llvm/run.sh cargo test
```

**Do not skip this step. Do not run LLVM tests any other way.**

## Container Commands

```bash
# First time: build the container image (slow, do once)
./docker/llvm/build.sh

# Build ori_llvm crate
./docker/llvm/run.sh cargo build

# Run ori_llvm tests
./docker/llvm/run.sh cargo test

# Run clippy on ori_llvm
./docker/llvm/run.sh cargo clippy

# Interactive shell in container
./docker/llvm/run.sh
```

Note: The run script automatically adds `--manifest-path compiler/ori_llvm/Cargo.toml`
for cargo commands since ori_llvm is excluded from the main workspace.

## Resource Limits

The container is constrained to protect the host (defaults: 4GB RAM, 2 CPUs):

```bash
# Override memory limit
LLVM_MEMORY=8g ./docker/llvm/run.sh cargo build -p ori_llvm

# Override CPU limit
LLVM_CPUS=4 ./docker/llvm/run.sh cargo build -p ori_llvm

# Both
LLVM_MEMORY=8g LLVM_CPUS=4 ./docker/llvm/run.sh cargo build -p ori_llvm
```

## What Requires the Container

- `cargo build -p ori_llvm`
- `cargo test -p ori_llvm`
- `cargo clippy -p ori_llvm`
- Test runs with `--backend=llvm` flag
- Building the compiler with the `llvm` feature enabled
- Any command that compiles or links against LLVM

## Safe on Host (no container needed)

- Reading/editing `ori_llvm` source files
- `cargo c` / `cargo cl` (LLVM is excluded from workspace by default)
- Running interpreter-based tests (`cargo t`, `cargo st`)
