---
name: regen-prior-art-ref
description: Regenerate prior-art-ref.md by studying all 10 reference compiler repos
allowed-tools: Read, Grep, Glob, Task, Bash, Write
---

# Regenerate Prior Art Reference

Regenerate `.claude/skills/design-pattern-review/prior-art-ref.md` by studying design patterns from all 10 reference compiler repos.

## Step 1: Validate Reference Repos

Run this validation first. If ANY repo is missing, FAIL immediately with a clear error.

```bash
REPOS_DIR=~/projects/reference_repos/lang_repos
MISSING=""
for repo in rust golang zig gleam elm roc typescript swift koka lean4; do
  if [ ! -d "$REPOS_DIR/$repo" ]; then
    MISSING="$MISSING  - $REPOS_DIR/$repo\n"
  fi
done
if [ -n "$MISSING" ]; then
  echo "ERROR: Missing reference repos:"
  echo -e "$MISSING"
  echo "All 10 repos must be present. Cannot regenerate prior-art-ref.md."
  exit 1
else
  echo "All 10 reference repos present."
fi
```

If the validation fails, stop and report the missing repos to the user. Do NOT proceed.

## Step 2: Launch 6 Parallel Explore Agents

Launch **6 parallel Explore agents** (one per domain). Send a **single message with 6 Task tool calls**.

### Agent A: Error Messages

```
Task(
  subagent_type: "Explore",
  description: "Prior Art: Error Messages",
  prompt: "Study error message design patterns from established compilers.

EXAMINE:
- ~/projects/reference_repos/lang_repos/elm/compiler/src/Reporting/Error/Type.hs
- ~/projects/reference_repos/lang_repos/elm/compiler/src/Reporting/Doc.hs
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_errors/src/diagnostic.rs
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_errors/src/lib.rs
- ~/projects/reference_repos/lang_repos/roc/crates/reporting/src/report.rs
- ~/projects/reference_repos/lang_repos/gleam/compiler-core/src/error.rs
- ~/projects/reference_repos/lang_repos/swift/lib/AST/DiagnosticEngine.cpp

For each compiler extract in telegraphic bullet-point style:
1. KEY PATTERNS (core design patterns)
2. WHAT MAKES IT UNIQUE (1-2 sentences)
3. KEY FILE PATHS (relative to repo root)
4. RELEVANCE TO ORI"
)
```

### Agent B: Type Systems

```
Task(
  subagent_type: "Explore",
  description: "Prior Art: Type Systems",
  prompt: "Study type system implementation approaches.

EXAMINE:
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_middle/src/ty/mod.rs
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_infer/src/infer/mod.rs
- ~/projects/reference_repos/lang_repos/zig/src/InternPool.zig (first ~200 lines)
- ~/projects/reference_repos/lang_repos/zig/src/Sema.zig (first ~200 lines)
- ~/projects/reference_repos/lang_repos/gleam/compiler-core/src/analyse/infer.rs
- ~/projects/reference_repos/lang_repos/koka/src/Type/Infer.hs
- ~/projects/reference_repos/lang_repos/koka/src/Type/Operations.hs

For each compiler extract in telegraphic bullet-point style:
1. KEY PATTERNS
2. WHAT MAKES IT UNIQUE
3. KEY FILE PATHS
4. RELEVANCE TO ORI"
)
```

### Agent C: Incremental Compilation

```
Task(
  subagent_type: "Explore",
  description: "Prior Art: Incremental",
  prompt: "Study incremental compilation approaches.

EXAMINE:
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_query_system/src/
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_middle/src/dep_graph/
- ~/projects/reference_repos/lang_repos/zig/src/Compilation.zig (first ~300 lines)
- ~/projects/reference_repos/lang_repos/typescript/src/compiler/builder.ts
- ~/projects/reference_repos/lang_repos/lean4/src/Lean/Compiler/LCNF/

For each compiler extract in telegraphic bullet-point style:
1. KEY PATTERNS
2. WHAT MAKES IT UNIQUE
3. KEY FILE PATHS
4. RELEVANCE TO ORI"
)
```

### Agent D: Code Fixes

```
Task(
  subagent_type: "Explore",
  description: "Prior Art: Code Fixes",
  prompt: "Study code fix and suggestion approaches.

EXAMINE:
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_errors/src/diagnostic.rs
- ~/projects/reference_repos/lang_repos/typescript/src/services/codeFixProvider.ts
- ~/projects/reference_repos/lang_repos/typescript/src/services/textChanges.ts
- ~/projects/reference_repos/lang_repos/gleam/compiler-core/src/error.rs

For each compiler extract in telegraphic bullet-point style:
1. KEY PATTERNS
2. WHAT MAKES IT UNIQUE
3. KEY FILE PATHS
4. RELEVANCE TO ORI"
)
```

### Agent E: Compiler Architecture

```
Task(
  subagent_type: "Explore",
  description: "Prior Art: Architecture",
  prompt: "Study compiler architecture approaches.

EXAMINE:
- ~/projects/reference_repos/lang_repos/rust/compiler/rustc_driver/src/lib.rs
- ~/projects/reference_repos/lang_repos/zig/src/main.zig (first ~200 lines)
- ~/projects/reference_repos/lang_repos/zig/src/Zcu.zig (first ~200 lines)
- ~/projects/reference_repos/lang_repos/golang/src/cmd/compile/internal/gc/main.go
- ~/projects/reference_repos/lang_repos/gleam/compiler-core/src/lib.rs
- ~/projects/reference_repos/lang_repos/swift/lib/SILOptimizer/ARC/ (list + read key files)
- ~/projects/reference_repos/lang_repos/lean4/src/Lean/Compiler/IR/RC.lean
- ~/projects/reference_repos/lang_repos/lean4/src/Lean/Compiler/IR/Borrow.lean

For each compiler extract in telegraphic bullet-point style:
1. KEY PATTERNS
2. WHAT MAKES IT UNIQUE
3. KEY FILE PATHS
4. RELEVANCE TO ORI"
)
```

### Agent F: Test Infrastructure

```
Task(
  subagent_type: "Explore",
  description: "Prior Art: Testing",
  prompt: "Study compiler testing approaches.

EXAMINE:
- ~/projects/reference_repos/lang_repos/rust/tests/ui/ (structure + sample files)
- ~/projects/reference_repos/lang_repos/zig/test/ (structure + sample files)
- ~/projects/reference_repos/lang_repos/gleam/compiler-core/src/ (inline tests)
- ~/projects/reference_repos/lang_repos/elm/tests/ (structure + sample files)

For each compiler extract in telegraphic bullet-point style:
1. KEY PATTERNS
2. WHAT MAKES IT UNIQUE
3. KEY FILE PATHS
4. RELEVANCE TO ORI"
)
```

## Step 3: Synthesize Results

Take all 6 agent results and compress into ~200-250 lines in `.claude/skills/design-pattern-review/prior-art-ref.md`.

Format:

```markdown
# Prior Art Reference
Last updated: {YYYY-MM-DD}
Repos: rust, golang, zig, gleam, elm, roc, typescript, swift, koka, lean4

## 1. Error Messages
**Sources:** Elm, Rust, Roc, Gleam, Swift
{condensed patterns from Agent A}

## 2. Type Systems
**Sources:** Rust, Zig, Gleam, Koka
{condensed patterns from Agent B}

## 3. Incremental Compilation
**Sources:** Rust, Zig, TypeScript, Lean 4
{condensed patterns from Agent C}

## 4. Code Fixes & Suggestions
**Sources:** Rust, TypeScript, Gleam
{condensed patterns from Agent D}

## 5. Compiler Architecture
**Sources:** Rust, Zig, Go, Gleam, Swift, Lean 4
{condensed patterns from Agent E}

## 6. Test Infrastructure
**Sources:** Rust, Zig, Gleam, Elm
{condensed patterns from Agent F}
```

Rules:
- Bullet points only, no prose paragraphs
- Pattern name + 1-line description
- File paths as `repo/path` (reader knows base dir is `~/projects/reference_repos/lang_repos/`)
- No code samples (those live in the repos)
- Match CLAUDE.md density and telegraphic style

## Step 4: Write and Report

Write the synthesized file to `.claude/skills/design-pattern-review/prior-art-ref.md`.

Report to user:
```
Prior art reference regenerated.
  File: .claude/skills/design-pattern-review/prior-art-ref.md
  Date: {YYYY-MM-DD}
  Domains: 6 (errors, types, incremental, fixes, architecture, testing)
  Sources: 10 repos studied
```
