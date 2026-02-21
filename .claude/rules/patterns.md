---
paths:
  - "**/patterns/**"
---

**NO WORKAROUNDS/HACKS/SHORTCUTS.** Proper fixes only. When unsure, STOP and ask. Fact-check against spec. Consult `~/projects/reference_repos/lang_repos/` (includes Swift for ARC, Koka for effects, Lean 4 for RC).

**Ori tooling is under construction** — bugs are usually in compiler, not user code. This is one system: every piece must fit for any piece to work. Fix every issue you encounter — no "unrelated", no "out of scope", no "pre-existing." If it's broken, research why and fix it.

# Pattern System

## PatternDefinition Trait
**Required:**
- `name() -> &'static str`
- `required_props() -> &'static [&'static str]`
- `type_check(&mut TypeCheckContext) -> Type`
- `evaluate(&EvalContext, &mut dyn PatternExecutor) -> EvalResult`

**Optional:** `optional_props()`, `scoped_bindings()`, `can_fuse_with()`

## Registry
- Static ZST instances: `static RECURSE: RecursePattern = RecursePattern;`
- Enum dispatch on `FunctionExpKind`
- Patterns: Recurse, Parallel, Spawn, Timeout, Cache, With, Print, Panic, Catch

## PatternExecutor
- `eval(expr_id)` — evaluate expression
- `call(func, args)` — call function
- `lookup_capability(name)` — get capability
- `call_method(receiver, method, args)`

## Adding New Pattern
1. Create `ori_patterns/src/<name>.rs`
2. Implement `PatternDefinition`
3. Register in `registry.rs`
4. Add `FunctionExpKind` variant
5. Add parsing in `ori_parse`

## Debugging / Tracing

**Always use `ORI_LOG` first when debugging pattern issues.** Tracing target: `ori_patterns` (dependency declared, instrumentation in progress).

```bash
ORI_LOG=ori_eval=debug ori run file.ori             # See pattern evaluation in interpreter
ORI_LOG=ori_types=debug ori check file.ori          # See pattern type checking
ORI_LOG=debug ORI_LOG_TREE=1 ori run file.ori       # Full hierarchical trace across all phases
```

**Tips**:
- Pattern not matching? Use `ori_eval=debug` to see method dispatch during pattern execution
- Type error in pattern? Use `ori_types=debug` to see type checking of pattern expressions
- Add `#[tracing::instrument]` to `PatternDefinition::evaluate()` impls when debugging specific patterns

## Key Files
- `lib.rs`: PatternDefinition trait
- `registry/`: Pattern lookup dispatch
- `recurse/`: Recurse pattern impl
- `value/`: Value types, iterators, `IteratorValue`
- `errors/`: Error factories (`wrong_arg_type`, `wrong_arg_count`)
