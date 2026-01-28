# Update Compiler Design Docs

Update the compiler design documentation at `docs/compiler/design/` to accurately describe the current implementation.

## Path

**IMPORTANT:** The compiler design docs are located at:
```
docs/compiler/design/
```

NOT at `docs/ori_lang/` (that's the language spec, not compiler design).

## Directory Structure

```
docs/compiler/design/
├── index.md                    # Overview and navigation
├── 01-architecture/            # Compiler architecture
│   ├── index.md
│   ├── pipeline.md
│   ├── data-flow.md
│   └── salsa-integration.md
├── 03-lexer/                   # Lexer design
│   ├── index.md
│   └── token-design.md
├── 04-parser/                  # Parser design
│   ├── index.md
│   ├── recursive-descent.md
│   ├── grammar-modules.md
│   └── error-recovery.md
├── 05-type-system/             # Type system design
│   ├── index.md
│   └── ...
├── 06-pattern-system/          # Pattern matching design
│   ├── index.md
│   ├── pattern-trait.md
│   └── ...
├── 07-evaluator/               # Interpreter/evaluator design
│   ├── index.md
│   ├── tree-walking.md
│   ├── environment.md
│   ├── value-system.md
│   └── module-loading.md
├── 08-diagnostics/             # Error reporting design
│   ├── index.md
│   ├── problem-types.md
│   ├── emitters.md
│   └── code-fixes.md
├── 09-testing/                 # Test infrastructure design
│   ├── index.md
│   ├── test-discovery.md
│   └── test-runner.md
└── appendices/
    ├── A-salsa-patterns.md
    ├── B-memory-management.md
    ├── C-error-codes.md
    ├── D-debugging.md
    └── E-coding-guidelines.md
```

## When to Update

Update design docs when:
- Adding new compiler features (new AST nodes, new patterns, new type constructs)
- Changing compiler architecture (new crates, reorganized modules)
- Modifying key data structures (Value, Type, MatchPattern, etc.)
- Adding new resolution/dispatch mechanisms
- Changing the compilation pipeline

## Update Process

1. **Identify affected docs** based on what changed:
   - AST changes → `04-parser/`, `06-pattern-system/`
   - Type system changes → `05-type-system/`
   - Evaluator changes → `07-evaluator/`
   - New patterns → `06-pattern-system/`
   - Error handling → `08-diagnostics/`

2. **Read the relevant source files** to understand current implementation:
   - `compiler/ori_ir/src/ast/` - AST definitions
   - `compiler/ori_parse/src/grammar/` - Parser
   - `compiler/ori_typeck/src/` - Type checker
   - `compiler/ori_eval/src/` - Evaluator
   - `compiler/ori_patterns/src/` - Pattern definitions

3. **Update the design docs** to accurately describe:
   - Data structures and their purpose
   - Algorithms and approaches
   - Interfaces and APIs
   - Examples showing current syntax/behavior

4. **Cross-reference with roadmap** (`plans/roadmap/priority-and-tracking.md`):
   - Note which phase the feature relates to
   - Update completion status if design doc completion was tracked

## Writing Style

### Document the Current Design, Not Changes

**CRITICAL:** Design docs describe **what IS**, not what changed or was fixed.

**DO NOT write:**
- "This was changed to..."
- "Previously X, now Y..."
- "The problem was... the solution is..."
- "This fix enables..."
- Progress updates or completion notes

**DO write:**
- "The lexer produces X tokens"
- "The parser synthesizes Y from Z"
- "This design enables..."
- Present tense, factual descriptions

Write as if documenting a fresh codebase for someone who has never seen previous versions. The reader doesn't care what it used to be — they need to understand what it is now.

### Content Guidelines

Design docs explain **WHY** and **HOW**, not just what:
- Explain design decisions and trade-offs
- Document the reasoning behind choices
- Include diagrams or ASCII art where helpful
- Reference the spec (`docs/ori_lang/0.1-alpha/spec/`) for normative definitions

## Example Update

If the codebase now supports multi-field variant patterns:

1. Update `docs/compiler/design/06-pattern-system/index.md`:
   - Document `MatchPattern::Variant { inner: Vec<MatchPattern> }` structure
   - Explain why Vec is used (supports 0, 1, or N fields)

2. Update `docs/compiler/design/04-parser/grammar-modules.md`:
   - Document `parse_variant_inner_patterns()` helper
   - Show grammar for comma-separated patterns

3. Update `docs/compiler/design/07-evaluator/tree-walking.md`:
   - Document how `try_match()` handles multi-field variants
   - Explain binding extraction for each field

**Good example text:**
> "Variant patterns use `Vec<MatchPattern>` for inner patterns, supporting unit variants (`None`), single-field variants (`Some(x)`), and multi-field variants (`Point(x, y)`)."

**Bad example text:**
> "The variant pattern was changed from `Option<Box<MatchPattern>>` to `Vec<MatchPattern>` to support multi-field variants."

## Output

Report what was updated:
- Which design doc files were modified
- Summary of changes made
- Any new sections added
- Cross-references updated
