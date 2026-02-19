---
paths:
  - "**/ori_llvm/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/` (includes Swift for ARC, Koka for effects, Lean 4 for RC).

**Ori tooling is under construction** — bugs are usually in compiler, not user code. This is one system: every piece must fit for any piece to work. Fix every issue you encounter — no "unrelated", no "out of scope", no "pre-existing." If it's broken, research why and fix it.

# LLVM Development

LLVM 17 required. Path in `.cargo/config.toml`.

## Commands
- Build: `cargo bl` (debug), `cargo blr` (release)
- Clippy: `cargo cll`
- Tests: `./llvm-test.sh`
- All: `./test-all.sh`

## MANDATORY: Always Test with Release Binary

**When making ANY changes to `ori_llvm` or `ori_rt`, you MUST test with the release binary.** Debug and release builds can behave differently due to runtime function optimization differences (see §8 in Common Bug Categories). A test that passes in debug may SIGSEGV in release.

**Workflow after LLVM changes:**
1. `cargo blr` — build release
2. `timeout 15 ./target/release/ori test --verbose --backend=llvm tests/spec/path/to/affected.ori` — test specific files
3. `./test-all.sh` — full suite (includes release LLVM tests)

**Never consider LLVM work done after testing only with `cargo bl` (debug).** The release binary is the one users run.

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

---

# Debugging LLVM Issues

## The Debugging Mindset

LLVM crashes are normal during compiler development. The evaluator operates at a high abstraction level (Rust `Value` enums, automatic memory management), while LLVM codegen operates at the instruction level — manual memory layout, calling conventions, SSA form, and type-exact IR. A mismatch anywhere produces crashes that are often far from their root cause. **This is expected.** The key is having a systematic process.

## First Response: Triage

When something crashes or produces wrong results, determine WHICH layer is failing:

| Symptom | Layer | Tool |
|---------|-------|------|
| Crash during IR generation | Codegen (our code) | `ORI_LOG=ori_llvm=debug` |
| "Broken function found" / verification failure | Codegen (our code) | `ORI_DEBUG_LLVM=1` + `opt -verify` |
| Crash during optimization | LLVM pass bug or latent bad IR | `opt -verify-each` + `-opt-bisect-limit` |
| Wrong results at runtime | Codegen logic error or ABI mismatch | `ORI_DEBUG_LLVM=1` + sanitizers |
| Segfault at runtime | Memory layout, GEP, or calling convention | ASan + `lli -force-interpreter` |
| Hang at runtime | Infinite loop in generated code | `timeout 5` + check latch pattern |
| Debug works, release crashes | Optimization exposes latent bad IR | `opt -O0` vs `opt -O2 -verify-each` |

## Step-by-Step Debugging Workflow

### Step 1: Get the IR

```bash
# Dump the generated LLVM IR before JIT/AOT compilation
ORI_DEBUG_LLVM=1 cargo test -p ori_llvm -- test_name 2> ir_output.ll

# Or for AOT
ORI_DEBUG_LLVM=1 ori build file.ori 2> ir_output.ll

# Tracing gives you the codegen event log
ORI_LOG=ori_llvm=debug ori build file.ori
ORI_LOG=ori_llvm=trace ORI_LOG_TREE=1 ori build file.ori  # Per-instruction detail
```

The `ORI_DEBUG_LLVM=1` env var triggers `module.print_to_string()` in `evaluator.rs`, dumping the full module IR to stderr before verification and JIT execution.

### Step 2: Verify the IR

```bash
# Check if the IR is well-formed
opt -verify -S ir_output.ll

# If verification passes but optimized code crashes:
opt -O2 -verify-each -S ir_output.ll    # Verify after EVERY pass
```

If `opt -verify` fails, the bug is in **our codegen**. Read the error message — it tells you exactly which LLVM invariant was violated. Common messages:

| Error Message | Meaning | Likely Cause |
|---------------|---------|--------------|
| `Block does not end with a terminator` | Missing `ret`/`br`/`unreachable` | Forgot to terminate a basic block |
| `Instruction does not dominate all uses` | SSA violation | Using a value defined in a branch without a phi node |
| `PHI node entries do not match predecessors` | Wrong phi node | Missing or extra incoming values |
| `Call parameter type does not match` | Type mismatch in call | Wrong type in function call argument |
| `Invalid GetElementPtrInst indices` | Bad GEP | Wrong struct field index or missing pointer deref |
| `Broken function found, compilation aborted` | General verification failure | Any of the above |

### Step 3: Isolate the Problem

**If it's a codegen bug (verification fails):**
1. Minimize the Ori source to the smallest program that reproduces
2. Dump IR with `ORI_DEBUG_LLVM=1`
3. Find the malformed function in the `.ll` output
4. Compare with what correct IR should look like (use `clang -emit-llvm -S` on equivalent C)

**If it's an optimization bug (verification passes, optimization crashes):**
```bash
# Find which pass breaks it via binary search
opt -O2 -opt-bisect-limit=-1 -S ir_output.ll 2>&1 | tail -5   # Get pass count
opt -O2 -opt-bisect-limit=50 -S ir_output.ll                   # First 50 passes
opt -O2 -opt-bisect-limit=25 -S ir_output.ll                   # Narrow down...

# Extract just the problem function
llvm-extract -func='_ori_function_name' -S < ir_output.ll > small.ll

# Auto-minimize the crashing IR
echo '#!/bin/bash' > crash.sh
echo '! opt -disable-output -O2 < $1 2>&1' >> crash.sh
chmod +x crash.sh
llvm-reduce --test crash.sh small.ll    # Output: reduced.ll

# Clean up names for readability
opt -S -passes=metarenamer < reduced.ll > clean.ll
```

**If it's a runtime bug (wrong results/segfault):**
```bash
# Compile the IR with sanitizers
clang -fsanitize=address,undefined -g ir_output.ll -o program -lori_rt
./program    # ASan/UBSan will catch memory issues

# Or run through LLVM's interpreter (no optimization, faithful to IR semantics)
lli -force-interpreter ir_output.ll

# Valgrind (alternative to ASan, 20-30x slower)
valgrind --tool=memcheck --leak-check=full ./compiled_program
```

### Step 4: Compare with Known Good

When you can't figure out what the IR should look like, write equivalent C and compare:

```bash
# Write minimal C that does the same thing
cat > equivalent.c << 'EOF'
#include <stdint.h>
struct Point { int64_t x; int64_t y; };
int64_t point_eq(struct Point a, struct Point b) {
    return a.x == b.x && a.y == b.y;
}
EOF

# Get Clang's LLVM IR for comparison
clang -emit-llvm -S -O0 equivalent.c -o reference.ll

# Compare structure, types, and calling convention with our IR
diff -u reference.ll our_output.ll
```

This is especially useful for:
- Struct layout and field access patterns (GEP indices)
- Calling conventions (`sret`, parameter passing)
- String operations and memory layout

## LLVM Tools Reference

### Core Tools

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `opt` | Run optimization passes on IR | `-verify`, `-verify-each`, `-O2`, `-opt-bisect-limit=N` |
| `llc` | Compile IR to native assembly/object | `-filetype=obj`, `-O2` |
| `lli` | Interpret/JIT execute IR directly | `-force-interpreter` |
| `llvm-dis` | Bitcode (.bc) to text IR (.ll) | `-o output.ll` |
| `llvm-as` | Text IR (.ll) to bitcode (.bc) | `-o output.bc` |
| `llvm-extract` | Extract single function from module | `-func='name' -S` |
| `llvm-reduce` | Auto-minimize crashing IR | `--test crash.sh input.ll` |
| `bugpoint` | Legacy auto-minimizer | `-compile-custom -compile-command=./crash.sh` |

### Useful `opt` Flags

```bash
opt -verify -S input.ll                        # Verify IR well-formedness
opt -O2 -verify-each -S input.ll               # Verify after EVERY pass
opt -O2 -opt-bisect-limit=N -S input.ll        # Run only first N passes
opt -O2 -opt-bisect-limit=-1 -S input.ll       # List all passes with indices
opt -O2 -print-after-all -S input.ll 2> t.txt  # Print IR after each pass
opt -O2 -print-changed -S input.ll 2> t.txt    # Print IR only when it changes (less noise)
opt -O2 -print-after=gvn -S input.ll           # Print after specific pass
opt -O2 -print-after-all -filter-print-funcs=my_func -S input.ll  # Filter to one function
opt -O2 -time-passes -S input.ll               # Measure pass execution time
```

**Note**: `-print-after-all` prints only the function a pass operates on, not the full module. Use `--print-module-scope` for full module output.

### Using `lli` for Quick Testing

```bash
# Execute IR via JIT (fast, applies some optimization)
lli ir_output.ll

# Execute via interpreter (slower, but faithful to exact IR semantics — no optimization artifacts)
lli -force-interpreter ir_output.ll
```

`lli` is invaluable for testing whether generated IR produces correct results before worrying about the full AOT pipeline.

## Common Bug Categories and Fixes

### 1. Missing Block Terminators

Every basic block MUST end with exactly one terminator (`ret`, `br`, `switch`, `unreachable`).

**Symptom**: `"Block does not end with a terminator instruction"`

**Debug pattern**: In inkwell, check `basic_block.get_terminator().is_some()` after generating each block. Our `IrBuilder` should verify this in debug builds.

**Common causes**:
- Forgetting `br` after an `if` branch
- Early return logic that skips the merge block
- `match` arms that don't all branch to the exit

### 2. Type Mismatches

LLVM IR is strongly typed. `i32` is NOT `i64`; `ptr` is NOT `i64`.

**Symptom**: `"Call parameter type does not match function signature"` or silent wrong results

**Debug pattern**: When calling functions, verify each argument type matches the declared parameter type. Use `zext`/`sext` for integer width changes, `ptrtoint`/`inttoptr` for pointer-integer conversions.

**Our safeguard**: `IrBuilder::record_codegen_error()` counts type mismatches. Check `has_codegen_errors()` before JIT execution.

### 3. Bad GEP (GetElementPtr) Indices

GEP computes addresses — it does NOT access memory. The first index offsets the base pointer; subsequent indices index into aggregate types.

**Symptom**: Segfaults, silent memory corruption, or `"Invalid GetElementPtrInst indices"`

**The classic mistake**:
```llvm
; WRONG — accesses the SECOND struct in memory, not field 1
%field = getelementptr %MyStruct, ptr %obj, i32 1

; CORRECT — index 0 dereferences the pointer, index 1 gets field 1
%field = getelementptr %MyStruct, ptr %obj, i32 0, i32 1
```

**References**: [The Often Misunderstood GEP Instruction](https://llvm.org/docs/GetElementPtr.html)

### 4. Phi Node Issues

Phi nodes must be the FIRST instructions in a block and must have exactly one entry per predecessor.

**Symptom**: `"PHI node entries do not match predecessors!"` or `"Instruction does not dominate all uses!"`

**Debug pattern**: When generating phi nodes, iterate all predecessor blocks and verify each has an entry. Missing predecessors are the #1 cause.

### 5. Calling Convention Mismatches

Caller and callee must agree on calling convention. Mixing `ccc` and `fastcc` is undefined behavior.

**Symptom**: Corrupted arguments, wrong return values, crashes in call frames

**Our pattern**: `FunctionAbi` computes the calling convention. Verify `call fastcc` matches `define fastcc`.

### 6. Sret (Struct Return) Bugs

Large return types use `sret` — an implicit first parameter pointing to caller-allocated return space.

**Symptom**: Garbage in returned structs, or return values silently lost

**Our pattern**: `FunctionCompiler::emit_return()` handles `ReturnPassing::Sret` vs `Direct` vs `Void`. When adding new return paths, always check which passing mode is active.

### 7. Debug vs Release Differences

Code that works at `-O0` but crashes at `-O2` usually means **latent bad IR** that optimization exposes:
- Uninitialized values that happened to be zero in debug
- Type mismatches that the optimizer tries to exploit
- UB that debug mode happens not to trigger

**Fix**: Always verify IR (`opt -verify`) before blaming optimization passes.

**Exception — JIT debug-vs-release**: When the *compiler binary* is built debug vs release but the *JIT code* is always O0, crashes that only appear in release mode are **not** latent bad IR. The generated LLVM IR is identical in both cases. The difference is that release-optimized runtime functions (`ori_str_concat`, `ori_str_from_bool`, etc.) use different register allocation/spill patterns than their debug counterparts. This can expose FastISel weaknesses in the JIT code that don't manifest when calling debug-compiled runtime functions. See §8 below.

### 8. Large Aggregate Loads in JIT (FastISel)

**CRITICAL RULE**: Never use `load %LargeStruct, ptr` for structs >16 bytes in JIT-compiled code. Use per-field `struct_gep` + `load` + `insert_value` instead.

**Symptom**: SIGSEGV only in release-compiled binary, specifically for Indirect (>16 byte) struct parameters. Debug builds work fine. The generated IR is identical between debug and release.

**Root cause**: LLVM's FastISel (used at JIT O0) mishandles large aggregate SSA values. When loading a >16-byte struct as a single value, FastISel must spill it to the stack. The spill slot can overlap with alloca space used by subsequent function calls (e.g., `ori_str_concat` argument allocas). Release-optimized runtime callees use different register pressure patterns, exposing the overlap.

**The fix** (`FunctionCompiler::load_indirect_param`):
```llvm
; BAD — single large aggregate load, FastISel-hostile
%param = load %BigStruct, ptr %arg_ptr

; GOOD — per-field GEP+load, each ≤8 bytes
%f0.ptr = getelementptr %BigStruct, ptr %arg_ptr, i32 0, i32 0
%f0 = load { i64, ptr }, ptr %f0.ptr
%s0 = insertvalue %BigStruct undef, { i64, ptr } %f0, 0
%f1.ptr = getelementptr %BigStruct, ptr %arg_ptr, i32 0, i32 1
%f1 = load i1, ptr %f1.ptr
%s1 = insertvalue %BigStruct %s0, i1 %f1, 1
```

**This matches Clang's behavior**: `clang -emit-llvm -S -O0` always emits per-field access for struct parameters, never a single aggregate load.

**Diagnostic checklist** for JIT-only SIGSEGV:
1. Dump IR (`ORI_DEBUG_LLVM=1`) — if IR is identical debug vs release, it's a JIT/runtime interaction issue
2. Check if crash is specific to Indirect (>16 byte) params — try forcing Direct (raise ABI threshold)
3. Look for `load %BigStruct, ptr` in the IR — replace with per-field GEP pattern
4. Entry-block allocas alone do NOT fix this — the problematic spill is LLVM-internal, not our allocas
5. `noredzone` and calling convention changes do NOT fix this — it's a FastISel aggregate issue

## Debugging Hangs

**Use aggressive timeouts** — never wait more than a few seconds for what should be fast:
```bash
timeout 5 ./target/release/ori test --backend=llvm path/to/file.ori
```

**Isolation strategy** (find the culprit fast):
1. Single file first: `timeout 3 ori test --backend=llvm file.ori`
2. If hangs, use `--filter=test_name` to isolate specific test
3. Binary search with filter patterns if needed

**Common hang patterns**:
- "Parallel slowdown" often = runtime infinite loop, not compile-time issue
- For-loop `continue` bugs: if `continue` skips index increment, infinite loop
- Check if hang is at compile time (IR gen) or runtime (JIT execution)

## Loop Codegen Architecture

For-loops use a **latch block** pattern:
```
entry → header → body → latch → header (or exit)
              |___________|
```

- `header`: condition check, branch to body or exit
- `body`: loop body execution
- `latch`: increment index, branch back to header
- `exit`: post-loop code

**Critical**: `continue` must jump to `latch` (not `header`) to ensure index increments. Jumping directly to header skips increment and causes an infinite loop.

**Break** jumps to `exit` block (correct as-is).

## Verification Strategy (Roc-Inspired)

Verify at **multiple points**, not just at the end:

1. **Per-function**: After generating each function body, verify just that function in debug builds (`fn_val.verify(true)`)
2. **Pre-optimization**: `module.verify()` before running any optimization passes
3. **Post-optimization**: `module.verify()` again after optimization (catches LLVM pass bugs)

On verification failure, **always dump the full module IR to a file** and include the path in the error message. This ensures you can inspect the failing IR even in CI.

Our current verification lives in `evaluator.rs`:
```rust
if std::env::var("ORI_DEBUG_LLVM").is_ok() {
    eprintln!("=== LLVM IR ===");
    eprintln!("{}", scx.llmod.print_to_string().to_string());
}
if let Err(msg) = scx.llmod.verify() {
    return Err(LLVMEvalError::new(format!("LLVM verification failed: {msg}")));
}
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `ORI_DEBUG_LLVM=1` | Dump full LLVM IR to stderr before verification |
| `ORI_LOG=ori_llvm=debug` | Codegen event log (phase boundaries, function-level) |
| `ORI_LOG=ori_llvm=trace` | Per-instruction codegen detail (very verbose) |
| `ORI_LOG_TREE=1` | Hierarchical indented trace output |
| `ASAN_SYMBOLIZER_PATH` | Path to `llvm-symbolizer` for readable ASan traces |

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

---

# Codegen Architecture

## FunctionCompiler (Central Abstraction)

Two-pass architecture:
1. **Declare phase**: Walk all functions, compute `FunctionAbi`, declare LLVM functions with correct calling conventions and attributes (`sret`, `noalias`)
2. **Define phase**: Walk again, create `ExprLowerer` for each, bind parameters, lower body

Key methods: `declare_all()` → `define_all()` → `compile_tests()` → `compile_impls()` → `compile_derives()` → `generate_main_wrapper()`

## IrBuilder (Instruction Emission)

ID-based wrapper around inkwell's Builder. All LLVM values stored in `ValueArena` behind opaque IDs (`ValueId`, `BlockId`, `FunctionId`). Hides `'ctx` lifetime from callers.

**Error tracking**: `codegen_errors` counter. If `has_codegen_errors()` is true after compilation, the module is malformed — do NOT JIT-execute it.

## Derive Codegen

`codegen/derive_codegen/` generates synthetic LLVM functions for `#[derive(...)]`. This is a **sync point** — it must handle every `DerivedTrait` variant that the evaluator handles.

**All 7 derived traits supported** via strategy-driven dispatch from `DerivedTrait::strategy()` in `ori_ir`:
- `ForEachField` → Eq, Comparable, Hashable
- `FormatFields` → Printable, Debug
- `CloneFields` → Clone
- `DefaultConstruct` → Default

**DO NOT** add derive codegen for a trait without first verifying the evaluator and type checker support it. See CLAUDE.md "Adding a New Derived Trait" checklist.

## Type-Qualified Method Mangling

Same method name on different types → different LLVM symbols:
- `Point.distance` → `_ori_Point$distance`
- `Line.distance` → `_ori_Line$distance`

## ABI-Driven Compilation

`FunctionAbi` computed from type-checked `FunctionSig`:
- Parameter types and passing modes (Direct, Indirect, Reference, Void)
- Return type and passing mode (Direct, Sret, Void)
- Calling convention (Fast, C)

Used at **declare time** (parameter types) and **call time** (argument layout).

---

# Inkwell Patterns and Pitfalls

## Builder Positioning

All `build_*` methods fail with `BuilderError::UnsetPosition` if the builder has no position. Always call `position_at_end(block)` before emitting instructions.

## Context Lifetime

All LLVM values, types, and blocks are tied to the `Context` lifetime. The context MUST outlive everything created from it. Our `SimpleCx` wrapper manages this.

## Unsafe GEP

`build_gep` is `unsafe` — incorrect indices cause segfaults. The first index dereferences the pointer (almost always `0`); subsequent indices navigate aggregate structure.

## Struct Return via JIT

Returning structs by value from JIT-compiled functions can produce garbage in the last field (known inkwell issue). Our `Sret` return passing works around this by returning via pointer parameter.

## Module Inspection

```rust
// Print entire module IR (for debugging)
module.print_to_stderr();
module.print_to_file("debug.ll").unwrap();
let ir = module.print_to_string().to_string();

// Verify (ALWAYS before JIT or optimization)
match module.verify() {
    Ok(()) => { /* valid */ }
    Err(msg) => { /* msg contains the verification error */ }
}

// Per-function verification (use in debug builds)
if !fn_val.verify(true) {  // true = print errors to stderr
    fn_val.print_to_stderr();
    panic!("Invalid function: {}", name);
}
```
