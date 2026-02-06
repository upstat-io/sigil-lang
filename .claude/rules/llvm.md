---
paths:
  - "**/llvm/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/` (includes Swift for ARC, Koka for effects, Lean 4 for RC).

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

# LLVM Development

LLVM 17 required. Path in `.cargo/config.toml`.

## Commands
- Build: `cargo bl` (debug), `cargo blr` (release)
- Clippy: `cargo cll`
- Tests: `./llvm-test.sh`
- All: `./test-all.sh`

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

## LLVM Test Execution
LLVM backend tests run **sequentially** (not parallel) due to `Context::create()` global lock contention. This matches Roc (`Threading::Single`) and rustc patterns.

## Debugging LLVM Hangs

**Use aggressive timeouts** — never wait more than a few seconds for what should be fast:
```bash
timeout 5 ./target/release/ori test --backend=llvm path/to/file.ori
```

**Isolation strategy** (find the culprit fast):
1. Single file first: `timeout 3 ori test --backend=llvm file.ori`
2. If hangs, use `--filter=test_name` to isolate specific test
3. Binary search with filter patterns if needed

**Common hang patterns:**
- "Parallel slowdown" often = runtime infinite loop, not compile-time issue
- For-loop `continue` bugs: if `continue` skips index increment → infinite loop
- Check if hang is at compile time (IR gen) or runtime (JIT execution)

## Loop Codegen Architecture

For-loops use a **latch block** pattern:
```
entry → header → body → latch → header (or exit)
              ↑___________|
```

- `header`: condition check, branch to body or exit
- `body`: loop body execution
- `latch`: increment index, branch back to header
- `exit`: post-loop code

**Critical**: `continue` must jump to `latch` (not `header`) to ensure index increments. Jumping directly to header skips increment → infinite loop.

**Break** jumps to `exit` block (correct as-is).

## Tracing / Debugging

**Always use `ORI_LOG` first when debugging LLVM codegen issues.** Tracing target: `ori_llvm`.

```bash
ORI_LOG=ori_llvm=debug ori build file.ori           # LLVM codegen debug events
ORI_LOG=ori_llvm=debug,ori_types=debug ori build file.ori  # Codegen + type checking
ORI_LOG=debug ori build file.ori                    # All phases including LLVM
timeout 5 ORI_LOG=ori_llvm=debug ori test --backend=llvm file.ori  # Debug with timeout
```

**Instrumented areas**: Pattern matching (`matching.rs`), control flow (`control_flow.rs`), function calls (`functions/calls.rs`), expression codegen (`functions/expressions.rs`)

**Tips**:
- Codegen crash? Use `ORI_LOG=ori_llvm=debug` to see last successful codegen step
- Runtime hang? Combine `timeout` with tracing to distinguish compile-time vs runtime issues
- Unimplemented pattern? Debug output includes "not yet implemented" messages for catch/concurrency patterns
