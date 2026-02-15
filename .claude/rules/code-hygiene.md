---
paths:
  - "**/*.rs"
---

# Code Hygiene Rules

## File Organization (top to bottom)

1. `//!` module docs
2. `mod` declarations
3. Imports (see Import Rules)
4. Type aliases
5. Type definitions (structs, enums)
6. Inherent `impl` blocks (immediately after their type)
7. Trait `impl` blocks (immediately after inherent impls)
8. Free functions
9. `#[cfg(test)] mod tests;` at bottom (declaration only — test body lives in sibling `tests.rs`)

## Import Organization (3 groups, blank-line separated)

1. External crate imports (alphabetical)
2. Internal crate imports (`crate::`, grouped by module)
3. Relative imports (`super::`, local re-exports)

## Impl Block Method Ordering

1. **Constructors**: `new`, `with_*`, `from_*`, factory methods
2. **Accessors**: getters, `as_*` (cheap ref conversions)
3. **Predicates**: `is_*`, `has_*`, `can_*`, `contains`
4. **Public operations**: the main thing this type does
5. **Conversion/consumption**: `into_*`, `to_*`
6. **Private helpers**: in call-order grouping, not alphabetical

Within each group: pub before pub(crate) before private (loose, not strict).

## Naming

**Functions** — verb-based prefixes:
- Predicates: `is_*`, `has_*`, `can_*`
- Conversions: `into_*` (consuming), `to_*` (borrowing), `as_*` (cheap ref), `from_*` (construct)
- Processing: `cook_*` (lexer), `parse_*` (parser), `check_*` (typeck), `eval_*` (evaluator)
- Consumption: `eat_*` (advance past), `skip_*` (advance+discard)
- Factory: `new`, `with_*`

**Variables** — scope-scaled:
- 1 char in scopes <= 3 lines: `c`, `i`, `n`, `b`
- 2-4 chars in scopes <= 15 lines: `ch`, `tok`, `pos`, `len`, `src`, `buf`, `err`, `kw`
- Descriptive (5+ chars) in larger scopes: `token_span`, `base_offset`, `content_str`
- Standard abbreviations: `pos`, `len`, `ch`, `tok`, `src`, `buf`, `err`, `idx`, `kw`, `ctx`

## Struct/Enum Field Ordering

1. Primary data (the core state)
2. Secondary/derived data
3. Configuration/options
4. Flags/booleans last

Inline comments on struct fields when purpose isn't obvious from the name.

## Comments

**Always**:
- `//!` module doc on every file
- `///` on all `pub` items
- Comment WHY, not WHAT
- `debug_assert!` to document preconditions (executable > prose)

**Never**:
- Decorative banners (`// ───`, `// ===`, `// ***`, `// ---`)
- Comments restating what code does
- Commented-out code
- `// TODO` without actionable context

**Section labels** in large enums/matches: plain `// Section name` without decoration.

## Derive vs Manual

- **Derive** when impl is standard (field-by-field equality, hash, debug)
- **Manual** only when behavior differs from derive (custom Debug output, selective fields, etc.)
- If you can't articulate WHY the manual impl differs from derive, use derive

## Visibility

- Private by default; minimize pub surface
- `pub(crate)` for cross-module internal use
- No dead pub items (pub but unused outside crate)
- No dead code (functions, imports, enum variants never used)

## File Size

- **500 line recommended limit** for source files (excluding `tests.rs`)
- When adding code that would exceed 500 lines, **split first** — don't add then plan to split later
- When touching a file already over 500 lines, take the opportunity to split it
- Split by extracting logical groups into submodules: related methods, type groups, match arm handlers
- Tests always in sibling `tests.rs` (use `scripts/extract_tests.py` for extraction)

## Style

- No `#[allow(clippy)]` without `reason = "..."` (use `#[expect]` when possible)
- Functions target < 30 lines, max 50 (dispatch tables exempt)
- Consistent patterns across similar code within same file
- No dead/commented-out code
