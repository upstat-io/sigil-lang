---
paths:
  - "**/tests/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/`.

**Ori tooling is under construction** — bugs are usually in compiler, not user code. Fix every issue you encounter.

# Specification Tests

**Tests are source of truth.** Test fails → code is wrong, not the test.

## TDD for Bugs
1. STOP — don't jump to fixing
2. Consult spec for intended behavior
3. Write MULTIPLE tests: exact case, edges, variations, guards
4. Verify tests FAIL (proves understanding)
5. Fix the code
6. Tests pass WITHOUT modification

## Anti-patterns (NEVER)
- Remove test "because it doesn't work" — investigate WHY
- Change expected to match actual — fix the compiler
- Assume `#compile_fail`/`#fail` incorrect — compiler may be too permissive
- Delete "redundant" tests — may cover different phases
- Mark `#skip` without investigating — find root cause

## Investigation Order
1. Lexer fully implements this?
2. Parser fully implements this?
3. Type checker handles this?
4. Evaluator implements this?
5. Test runner interprets attributes correctly?
6. ONLY THEN consider test is wrong

## Quality
- Test behavior, not implementation
- Edge cases: empty, boundary, error
- No flaky: no timing, shared state, order deps
- `#[ignore]` needs tracking issue
- Inline < 200 lines
- Clear naming: `test_parses_nested_generics`
- AAA structure

## Directories
- `tests/spec/`: Conformance
- `tests/compile-fail/`: Expected failures
- `tests/run-pass/`: Expected success
- `tests/fmt/`: Formatting

## Running
```bash
cargo st                           # all spec tests
cargo st tests/spec/types/         # specific category
./test-all.sh                      # full suite
./llvm-test.sh                     # LLVM unit tests
cargo blr && ./target/release/ori test --backend=llvm tests/
```

## Attributes
- `#skip("reason")`: Skip with explanation
- `#compile_fail("error")`: Expect compile failure
- `#fail("error")`: Expect runtime failure
- `#timeout(5s)`: Set timeout

## Debugging / Tracing

**Always use `ORI_LOG` first when debugging test failures.** The test runner (`oric`) and all compiler phases support structured tracing.

```bash
ORI_LOG=debug cargo st tests/spec/types/            # Debug all phases for specific tests
ORI_LOG=ori_types=debug cargo st tests/spec/types/   # Type checker only
ORI_LOG=ori_eval=debug cargo st tests/spec/eval/     # Evaluator only
ORI_LOG=debug ORI_LOG_TREE=1 cargo st tests/spec/patterns/  # Hierarchical trace
ORI_LOG=oric=debug cargo st tests/spec/              # Salsa query execution + cache hits
```

**Tips**:
- Test crashes/hangs? Use `timeout 10 ORI_LOG=debug cargo st path/to/test.ori`
- Wrong result? Use `ORI_LOG=ori_eval=trace ORI_LOG_TREE=1` on the specific test file
- Type error in test? Use `ORI_LOG=ori_types=debug` to see which check fails
- Salsa caching issue? Use `ORI_LOG=oric=debug` to see `WillExecute` vs `DidValidateMemoizedValue`

## Coverage
`cargo tarpaulin -p CRATE --lib --out Stdout` — target 60-80%
