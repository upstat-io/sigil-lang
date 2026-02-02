---
paths:
  - "**/tests/**"
---

**Ori is under construction.** Rust tooling is trusted. Ori tooling (lexer, parser, type checker, evaluator, test runner) is NOT. When something fails, investigate Ori infrastructure first—the bug is often in the compiler/tooling, not user code or tests.

**Fix issues encountered in code you touch. No "pre-existing" exceptions.**

**Do it properly, not just simply. Correct architecture over quick hacks; no shortcuts or "good enough" solutions.**

# Specification Tests

**Tests are the source of truth.** Read local README.md for details.

## Philosophy

- Tests derived from spec, not implementation
- Test fails → **code is wrong**, not the test
- Never modify tests to match broken behavior
- Each test references spec section it validates
- **TDD for bugs**: failing test first → fix → test passes unchanged

## Anti-patterns (NEVER do these)

- **Removing a test because it "doesn't work"** — investigate WHY first; the test runner, evaluator, or type checker may have the bug
- **Changing expected output to match actual output** — understand the discrepancy first; if actual output is wrong, fix the compiler
- **Assuming `#compile_fail` or `#fail` attributes are incorrect** — these are deliberate; if the test passes unexpectedly, the compiler may be too permissive
- **Deleting tests that "seem redundant"** — they may cover edge cases in different compiler phases
- **Marking tests `#skip` without investigating** — skipping hides bugs; find the root cause in Ori tooling

## When Tests Fail — Investigation Order

1. Is this syntax/feature fully implemented in the **lexer**?
2. Is this syntax/feature fully implemented in the **parser**?
3. Does the **type checker** handle this case correctly?
4. Does the **evaluator** implement this behavior?
5. Is the **test runner** correctly interpreting test attributes?
6. ONLY THEN consider if the test itself is wrong

## Test References (Required)

- Comment linking to spec file and section (not line number)
- Comment linking to design file and section (not line number)

## Quality Guidelines

- **Behavior, not implementation**: test what it does, not how
- **Edge cases**: empty, boundary, error conditions
- **No flaky tests**: no timing, shared state, order dependencies
- **`#[ignore]`** must have tracking issue comment
- **Inline < 200 lines**; longer → `tests/` subdirectory
- **Clear naming**: `test_parses_nested_generics`, not `test_1`
- **AAA structure**: Arrange-Act-Assert clearly separated
- **Snapshot testing** for complex output
- **Data-driven**: fixture + expected output
- **5+ mocks** → suggests SRP violation; refactor first

## Test Directories

- `tests/spec/` — specification conformance tests
- `tests/compile-fail/` — expected compilation failures
- `tests/run-pass/` — expected to compile and run
- `tests/fmt/` — formatting tests

## Running

```bash
cargo st                         # all spec tests (interpreter)
cargo st tests/spec/types/       # specific category
./test-all                       # full suite: Rust + interpreter + LLVM
./llvm-test                      # LLVM crate unit tests
```

### LLVM Backend Tests

```bash
# Run spec tests with LLVM backend
./target/release/ori test --backend=llvm tests/

# Build first if needed
cargo blr && ./target/release/ori test --backend=llvm tests/
```

## Adding Tests

1. Identify spec section being tested
2. Create file in appropriate directory
3. Add comment: `// Spec: 03-lexical-elements.md § Literals`
4. Write tests validating spec, not current behavior

## Test Coverage

Use `cargo tarpaulin` for Rust code coverage.

```bash
# Standard crates
cargo tarpaulin -p ori_parse --lib --out Stdout

# LLVM crate (requires LLVM 17 installed)
cargo tarpaulin -p ori_llvm --lib --out Stdout

# Filter to specific module
cargo tarpaulin -p ori_llvm --lib --out Stdout -- linker
```

**Target: 60-80% coverage** for new modules.

## Test Attributes

| Attribute | Purpose |
|-----------|---------|
| `#skip("reason")` | Skip test with explanation |
| `#compile_fail("error")` | Expect compilation to fail |
| `#fail("error")` | Expect runtime failure |
| `#timeout(5s)` | Set test timeout |
