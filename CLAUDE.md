# Sigil

A general-purpose language built on declarative patterns and mandatory testing.

## Project Overview

Sigil treats common computational patterns as first-class language constructs:
- **Declarative patterns** - `recurse`, `map`, `filter`, `fold`, `parallel` with named parameters
- **Mandatory testing** - Every function must have tests or compilation fails
- **Explicit syntax** - `@` for functions, `$` for config, `.name:` for named parameters
- **Strict typing** - All types known at compile time, with inference for lambdas

## Language Syntax

### Functions
```
@function_name (param: type, ...) -> return_type = expression
```

### Config Variables
```
$config_name = value
```

### Tests
```
@test_name tests @target_function () -> void = run(
    assert(condition),
    assert_eq(a, b)
)
```

### Imports
```
use module_name { function1, function2 }
```

### Conditionals
```
if condition then value
else if condition then value
else value
```

### Line Continuation
Use `_` at end of line to continue expression on next line:
```
if a > 0 && _
   b > 0 then "both positive"
else "no"
```

## Project Structure

```
sigil/
├── compiler/
│   └── sigilc/            # The compiler (Rust crate)
│       └── src/
│           ├── lib.rs     # Library interface
│           ├── main.rs    # CLI entry point
│           ├── lexer/     # Tokenizer (logos-based)
│           ├── parser/    # Recursive descent parser
│           ├── ast/       # Abstract syntax tree definitions
│           ├── types/     # Type checker
│           ├── eval/      # Tree-walking interpreter
│           └── codegen/   # C code generator
├── library/               # Standard library (Sigil code)
│   └── std/
├── docs/                  # Documentation
├── examples/              # Example programs
├── tests/
│   ├── run-pass/          # Tests that should compile and run
│   │   └── rosetta/       # Rosetta Code implementations
│   └── compile-fail/      # Tests that should fail to compile
└── Cargo.toml             # Workspace root
```

## CLI Commands

```bash
# Run a program
sigil run file.si

# Compile to C
sigil build file.si

# Emit C code
sigil emit file.si

# Run all tests (parallel)
sigil test

# Run tests for specific file
sigil test file.test.si

# Check test coverage
sigil check file.si
```

## Test File Convention

- Test files live in `_test/` subdirectory
- Named `filename.test.si`
- Must explicitly import the module being tested
- Every function (except `@main`) requires at least one test

## Key Design Decisions

1. **Context-sensitive keywords** - Pattern keywords (`map`, `filter`, `fold`, `recurse`) are only special in pattern contexts; they can be used as function names
2. **@ prefix for functions** - Makes function definitions visually distinct
3. **$ prefix for config** - Distinguishes configuration from regular variables
4. **Explicit imports** - No implicit module loading
5. **Expression-based** - Everything is an expression that returns a value
6. **Dual syntax for patterns** - Both positional and named property syntax supported

## Pattern Syntax

Patterns support both positional and named property syntax:

### Positional (concise)
```
@factorial (n: int) -> int = recurse(n <= 1, 1, n * self(n - 1))
@sum (arr: [int]) -> int = fold(arr, 0, +)
```

### Named Properties (explicit)
```
@fibonacci (n: int) -> int = recurse(
    .cond: n <= 1,
    .base: n,
    .step: self(n - 1) + self(n - 2),
    .memo: true
)
```

### Available Patterns
- `recurse` - Recursive functions with optional `.memo` for memoization
- `fold` - Reduce/aggregate operations
- `map` - Transform each element
- `filter` - Select elements matching predicate
- `collect` - Build list from range
- `match` - Conditional pattern matching
- `run` - Sequential execution
- `parallel` - Concurrent execution (returns struct with named fields)

## Building

```bash
cargo build
cargo test
```

## Current Status

The language has a working:
- Lexer (tokenizer)
- Parser (AST generation)
- Type checker
- Tree-walking interpreter
- C code generator (basic)
- Test runner with mandatory coverage (parallel)
- Pattern system with named property syntax
- Memoization support for recursive functions
