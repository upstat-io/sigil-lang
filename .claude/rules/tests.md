---
paths: **/tests/**
---

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
ori test tests/spec/             # all spec tests
ori test tests/spec/types/       # specific category
ori test tests/spec/expressions/ # another category
```

## Adding Tests

1. Identify spec section being tested
2. Create file in appropriate directory
3. Add comment: `// Spec: 03-lexical-elements.md § Literals`
4. Write tests validating spec, not current behavior

## Test Coverage

Use `cargo tarpaulin` for Rust code coverage.

```bash
# Standard crates (no LLVM)
cargo tarpaulin -p ori_parse --lib --out Stdout

# LLVM crate - MUST use docker
./docker/llvm/run.sh "cargo tarpaulin --manifest-path compiler/ori_llvm/Cargo.toml --lib --out Stdout"

# Filter to specific module
./docker/llvm/run.sh "cargo tarpaulin --manifest-path compiler/ori_llvm/Cargo.toml --lib --out Stdout -- linker"
```

**Target: 60-80% coverage** for new modules.
