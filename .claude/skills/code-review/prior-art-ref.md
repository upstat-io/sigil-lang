# Prior Art Reference

Last updated: 2026-02-09
Repos: rust, golang, zig, gleam, elm, roc, typescript, swift, koka, lean4
Base path: `~/projects/reference_repos/lang_repos/`

---

## 1. Error Messages & Diagnostics

### Elm — Narrative Clarity
- Three-part structure: problem statement → context (where/why) → hint (how to fix)
- Context types as ADT: `Expected tipe = NoExpectation | FromContext Region Context | FromAnnotation Name Int SubContext`
- Context enum: `ListEntry | Negate | OpLeft Name | OpRight Name | IfCondition | CaseBranch | CallArg | RecordAccess | Destructure`
- Separate `Expected` vs `PExpected` for expression vs pattern contexts (exhaustive analysis)
- Operator-specific handlers: `opLeftToDocs`/`opRightToDocs`, `badListAdd`, `badStringAdd` — direction-aware guidance
- Problem classification (20+ variants): `IntFloat | StringFromInt | FieldsMissing | FieldTypo | BadFlexSuper | BadRigidVar | ArityMismatch`
- Doc algebra: `D.reflow`, `D.stack`, `D.indent` compose output; rendered to ANSI or plain
- Suggestion engine (`Reporting.Suggest`): Damerau-Levenshtein edit distance, case-insensitive fallback
- Ordinal helpers: `D.ordinal` → "1st", "2nd" for positional error messages
- **Key files:** `compiler/src/Reporting/Error/Type.hs` (1612L), `compiler/src/Reporting/Doc.hs`, `compiler/src/Reporting/Suggest.hs`, `compiler/src/Reporting/Error/Syntax.hs` (200+ patterns)

### Rust — Production-Grade Toolability
- `Applicability` enum: MachineApplicable | MaybeIncorrect | HasPlaceholders | Unspecified — tools auto-fix only MachineApplicable
- `EmissionGuarantee` trait: type-level proof that error was reported (prevents silent failures)
- Drop bomb: `Diag` panics if dropped without `.emit()`/`.cancel()` — catches bugs at compile time
- `with_*` macro pattern: methods accepting `&mut self` auto-generate consuming `.with_*()` variants for chaining
- Multi-span `CodeSuggestion`: multiple alternatives per suggestion (`Vec<Substitution>`)
- `SuggestionStyle` (5 variants): ShowCode | HideCodeInline | HideCodeAlways | CompletelyHidden | ShowAlways
- Stashing & stealing: errors can be "stashed" early, stolen/improved at later phases via `StashKey` enum
- Deduplication via `StableHasher` → `Hash128` prevents duplicate emission
- Delayed bugs: `DelayedBug` level buffers errors; emits as ICE if no hard errors occurred
- Level hierarchy (15 variants): Bug > Fatal > Error > DelayedBug > ForceWarning > Warning > Note > OnceNote > Help > OnceHelp > ...
- JSON serialization for IDE/LSP consumption: `DiagnosticSpan` with source text, highlighting, macro backtrace
- Side effect replay: diagnostics cached per query node, replayed on green cache hit
- Lint system: `Lint` static struct, `LintId` pointer equality, `FutureIncompatibleInfo` for staged deprecation
- **Key files:** `compiler/rustc_errors/src/diagnostic.rs`, `compiler/rustc_errors/src/lib.rs`, `compiler/rustc_errors/src/json.rs`, `compiler/rustc_lint_defs/src/lib.rs`

### Roc — Render Target Abstraction
- `RenderTarget` enum: ColorTerminal | Generic | LanguageServer — same doc tree, different output
- `Palette` struct maps semantic elements (keyword, error, variable, typo) to style codes; swappable themes
- Arena-based doc allocator (`RocDocAllocator`) wraps `ven_pretty::BoxAllocator` + metadata (src_lines, home module, interns)
- Annotation system (20+ variants): Emphasized, Keyword, Error, Symbol, TypeVariable, Alias, Opaque, CodeBlock, TypeBlock, InlineTypeBlock, LineNumber, GutterBar
- Type blocks suppress inner annotations (prevents nested backticks)
- Platform-aware Unicode (Windows: ASCII fallback, Unix: box-drawing)
- Phase-specific entry points: `parse_problem()`, `can_problem()`, `type_problem()`
- Region subregion highlighting: `alloc.region_with_subregion()` — shows containing region + inner error, truncates to 60-line viewport
- Record field polarity (5-state): Demanded | Required | Optional | RigidRequired | RigidOptional
- **Key files:** `crates/reporting/src/report.rs` (1821L), `crates/reporting/src/error/{type,parse,canonicalize}.rs`

### Gleam — Simplicity + Stratification
- Error stratified by phase: `Error::Parse` | `Error::Type` | `Error::BadImports` (40+ top-level variants)
- Type errors separate (90+ variants): `UnknownVariable`, `CouldNotUnify`, `UnknownField`
- `Problems` accumulator: `{ errors: Vec<Error>, warnings: Vec<Warning> }` — no early exit
- `Vec1<T>` guarantees non-empty error vectors (compile-time assertion)
- `did_you_mean()`: Levenshtein distance with adaptive threshold (1/3 name length, min 1)
- Staged matching: single-option auto-suggest → case-insensitive → edit distance
- `ModuleSuggestion` enum distinguishes importable vs already-imported
- Uses `codespan-reporting` crate for formatted output
- **Key files:** `compiler-core/src/error.rs` (193KB), `compiler-core/src/type_/error.rs` (2019L), `compiler-core/src/diagnostic.rs`

### Swift — Macro-Driven Scalability
- Diagnostics defined in `.def` files: `GROUPED_ERROR(ID, Group, Options, Text, Signature)` → compile-time arrays
- `StoredDiagnosticInfo`: 7 bitfields packed (kind, pointsToFirstBadToken, isFatal, isDeprecation, isNoUsage, groupID)
- DiagGroupID hierarchies with per-group suppression (Ignored | Warning | Error)
- PointsToFirstBadToken: parser errors adjusted to end of previous token for better UX
- Zero runtime lookup cost: `storedDiagnosticInfos[]` compile-time constant table
- Fix-it strings also macro-generated from `.def` files
- **Key files:** `lib/AST/DiagnosticEngine.cpp`, `include/swift/AST/DiagnosticEngine.h`, `include/swift/AST/DiagnosticsAll.def`

### Go — Structured Error Codes
- Enum-based error codes: `internal/types/errors/codes.go` — fine-grained, not implementation-detail dependent
- Error deduplication per line: prevents duplicate same-line errors
- Error suppression: follow-on errors filtered (e.g., "invalid operand" after earlier error)
- `base.FatalfAt()` for compiler bugs; user errors go through diagnostics
- **Key files:** `internal/types/errors/codes.go`, `go/types/errors.go`, `cmd/compile/internal/base/print.go`

### TypeScript — Immutable Diagnostic Registry
- `diagnosticMessages.json`: 8600+ pre-defined error templates with `{0}`, `{1}` placeholders
- Categories: "Error" | "Warning" | "Suggestion"; sparse codes for organization
- `DiagnosticMessageChain`: linked list for multi-line errors (`next?: DiagnosticMessageChain[]`)
- Marker pattern: empty object `{}` for `reportsUnnecessary` / `reportsDeprecated` (metadata without storage cost)
- `ReusableDiagnostic`: separates tree structure from computed state for incremental build caching
- **Key files:** `src/compiler/diagnosticMessages.json`, `src/compiler/types.ts` (Diagnostic interfaces)

### Cross-Cutting Patterns
- **Emission guarantee**: Rust `EmissionGuarantee` — compile-time proof errors are consumed
- **Phase-specific errors**: Elm/Gleam/Roc separate error types per compiler phase
- **Error accumulation**: All compilers collect errors without early exit
- **Contextual rendering**: Elm/Roc carry expression context through inference for "why expected X" messages
- **Applicability levels**: Rust 4-level; essential for auto-fix vs user-review distinction
- **Stashing for improvement**: Rust stashes early errors, improves at later phases

---

## 2. Type Systems

### Elm — HM with Constraint-Based Solver
- Two-phase: **Constraining** (walk AST, emit `Constraint`) → **Solving** (unify, generalize)
- Constraint AST: `CTrue | CEqual Region Category Type Expected | CAnd [Constraint] | CLet { rigidVars, flexVars, header, headerCon, bodyCon }`
- Dual type representation: `Variable = UF.Point Descriptor` (mutable, union-find) vs `Type` (immutable, for reporting)
- Descriptor: `{ content :: Content, rank :: Int, mark :: Mark, copy :: Maybe Variable }`
- Content enum: `FlexVar | FlexSuper SuperType | RigidVar | RigidSuper | Structure FlatType | Alias | Error`
- SuperType constraints: `Number | Comparable | Appendable | CompAppend`
- CPS unification monad: early exit on mismatch while tracking collected variables for error context
- Rank polymorphism: rank tracks let-nesting depth; generalization at let boundaries
- Mark-based cycle detection: `noMark = Mark 2`, `occursMark = Mark 1` — avoids revisiting in multiple passes
- Problem extraction: after unification failure, classify into `IntFloat | StringFromInt | ArityMismatch | BadFlexSuper | FieldsMissing | FieldTypo`
- Extension tracking (records): `Extension = Closed | FlexOpen Name | RigidOpen Name`
- **Key files:** `compiler/src/Type/Type.hs`, `compiler/src/Type/Unify.hs` (200L), `compiler/src/Type/Solve.hs`, `compiler/src/Type/Constrain/Expression.hs`, `compiler/src/Type/UnionFind.hs` (156L)

### Rust — TyCtxt Centralization
- `TyCtxt<'tcx>` owns all type metadata: pool, interner, caches, registries
- `TyKind` enum for type representation; `Interned<T>` for deduplication
- Separate trait solver (`rustc_trait_selection`) from type representation
- Query-cached inference with memoization via `rustc_query_system`
- **Key files:** `compiler/rustc_middle/src/ty/mod.rs`, `compiler/rustc_infer/src/infer/mod.rs`

### Zig — InternPool (Ori's Primary Influence)
- Unified pool: types AND values are 32-bit indices into same pool
- Thread-local shards: each shard locks independently (reduces contention)
- TID encoded in upper bits of indices via `tid_shift` for single u32 value
- `AnalUnit` (packed u64): granular tracking per function/type/nav, not per-file
- Dependency maps: `src_hash_deps`, `nav_val_deps`, `nav_ty_deps`, `interned_deps`, `namespace_deps` — precise invalidation
- `TrackedInst`: stable references across ZIR regeneration; `.lost` sentinel for disappearing instructions
- Sema.Block: hierarchical blocks with parent chains; `RuntimeIndex` prevents comptime store violations
- InstMap: sparse ZIR→AIR mapping — linear array indexed by `Zir.Inst.Index - start`, not a hashmap
- InferredErrorSet: accumulates errors during function analysis; references other inferred sets (composition)
- MultiArrayList: SoA layout for AIR instructions (better cache behavior)
- Arena per phase: AstGen, Sema, Codegen each get own arena; wholesale deallocation
- **Key files:** `src/InternPool.zig` (13K), `src/Sema.zig` (37.7K), `src/Type.zig`, `src/Value.zig`

### Gleam — Multi-Phase Environment + Variant Inference
- Phase-split: `Hydrator` (annotations) ≠ `Environment` (inference) ≠ `ExprTyper` (expressions)
- Type representation: `Type::Named | Type::Fn | Type::Var { Arc<RefCell<TypeVar>> } | Type::Tuple`
- TypeVar: `Unbound { id, level } | Link { type_ } | Generic { id, name }`
- `inferred_variant: Option<u16>` on Named types — pattern matching refines which constructor variant
- `im::HashMap` for fast cloning during backtracking
- Purity tracking: `Pure | TrustedPure | Impure | Unknown` — NOT part of type system, used for warnings
- Reference tracker: `ReferenceTracker` tracks entity use for LSP + dead code analysis
- Target-aware: `can_run_on_erlang` vs `can_run_on_javascript`
- **Key files:** `compiler-core/src/type_.rs`, `compiler-core/src/type_/expression.rs`, `compiler-core/src/type_/environment.rs`, `compiler-core/src/type_/pattern.rs`

### Koka — Effect Rows as First-Class Types
- Effects are `Tau` types (not separate): `effectExtend :: Tau -> Tau -> Tau` builds rows
- `extractEffectExtend :: Tau -> ([Tau], Tau)` decomposes effect row into labels + tail
- Three type variable flavours: `Meta` (unifiable) | `Skolem` (rigid) | `Bound` (quantified)
- Kind system: `kindStar` (values) | `kindEffect` (rows) | `kindLabel` (labels) | `kindHandled` (handlers)
- `TypeSyn { synonymRank :: Int }` prevents infinite expansion loops during unification
- `Inf` monad: all type transformations monadic (error + state + unique ID generation)
- Implicit constraint evidence: `ImplicitConstraint { icName, icType, icEvidence, icSolve }` — evidence as implicit local vars
- Effect row normalization: `orderEffect` sorts labels by name for canonical form
- Handled effects (`handled<Lab>` vs `handled1<Lab>`) vs open effects (`<lab | e>`)
- ParamInfo: `Own | Borrow` — parameter ownership tracked at type level
- **Key files:** `src/Type/Type.hs` (1017L), `src/Type/Infer.hs` (2711L), `src/Type/Unify.hs` (545L), `src/Type/Operations.hs`, `src/Type/InferMonad.hs` (2328L)

### Roc — Substitution-Based Unification
- `Subs` struct: arena-like slices for type constructors; variable → content mapping with compaction
- SOA constraint storage: `constraints: Vec<Constraint>`, `type_slices: Vec<TypeOrVar>`, `variables: Vec<Variable>`, `categories: Vec<Category>`
- Record field polarity: Demanded | Required | Optional | RigidRequired | RigidOptional
- AliasKind: `Structural` vs `Opaque` controls user visibility
- Type variable naming: `find_names_needed()` — single=wildcard, multiple=letter (α, β, ...)
- Obligation caching: `ObligationCache<Key, Result>` avoids re-checking ability implementations
- `FxCall`, `FxSuffixConstraint` for effect (capability) constraint system
- **Key files:** `crates/compiler/types/src/types.rs`, `crates/compiler/types/src/subs.rs`, `crates/compiler/solve/src/solve.rs` (106K)

### TypeScript — Flag-Based Type Hierarchy
- `TypeFlags` (27+ flags, composed via bitwise OR): `Any | Unknown | String | Number | Boolean | Union | Intersection | Conditional | Substitution`
- No polymorphism in hot paths: `if (type.flags & TypeFlags.Union)` avoids vtable lookup
- `ObjectFlags` (28+ flags): secondary classification (Class | Interface | Reference | Tuple | Mapped)
- `TypeMapper` pattern: composable transformations (Simple | Array | Deferred | Function | Composite)
- Lazy caching: `resolvedReturnType?`, `resolvedProperties?`, `permissiveInstantiation?` populated on demand
- Symbol + SymbolLinks split: `Symbol` (identity) vs `SymbolLinks` (context-dependent metadata)
- Phantom type `__String`: escaped identifiers prevent accidental unescaped string usage
- Variance tracking: `VarianceFlags` (covariant, contravariant, bivariant, independent, unmeasurable)
- checker.ts monolith (3M lines): deliberate — mutual recursion between inference + checking
- **Key files:** `src/compiler/types.ts` (10.6K), `src/compiler/checker.ts` (53.9K)

### Go — White-Grey-Black Type Checking
- Two-phase: White (untyped) → Grey (pending/cycle detection) → Black (complete)
- Cycle detection via `objPathIdx` map (object path stack)
- Delayed action queue: deferred `func()` for processing after current declaration
- Untyped constants: delay type assignment until assignment context
- Separate `go/types` (AST-aware API) vs internal `types` (compiler)
- Method sets on named types; interface implicit methods
- **Key files:** `go/types/check.go`, `go/types/decl.go`, `go/types/cycles.go`

### Cross-Cutting Patterns
- **Unified type handle**: Rust `Ty<'tcx>`, Zig `Index`, Ori `Idx(u32)` — equality is identity
- **Pool as gravity well**: all type operations route through pool; pool owns interning + metadata
- **Bidirectional checking**: both infer (bottom-up) and check (top-down) needed
- **Unification**: path-compressed union-find with occurs check; rank-based generalization
- **Error accumulation**: collect all errors in one pass; never bail on first error
- **Environment with scoping**: nested scopes, parent chain for lookups; immutable snapshots for backtracking

---

## 3. Incremental Compilation

### Rust — Query-Based (Salsa-like)
- Dependency graph: every computation = node with 128-bit fingerprint
- Red/green marking: compare fingerprints across sessions; green = reusable
- `QuerySideEffect::Diagnostic(DiagInner)`: emitted diagnostics cached per query, replayed on green hit
- `FingerprintStyle`: DefPathHash | HirId | Unit | Opaque — controls reconstructibility
- `CycleErrorHandling`: Error | Fatal | DelayedBug | Stash — per-query cycle policy
- `DefaultCache` (sharded hashmap), `SingleCache`, `DefIdCache` (dense vector for local defs)
- Dependency tracking via implicit thread-local context: `with_deps()` records all reads/writes
- `DEP_KIND_NULL`, `DEP_KIND_RED`, `DEP_KIND_SIDE_EFFECT` pseudo-nodes
- **Key files:** `compiler/rustc_query_system/src/dep_graph/`, `compiler/rustc_query_system/src/query/`

### Zig — Work Queue Pipeline + Granular Invalidation
- Staged jobs: AstGen → Sema → Codegen → Link; jobs advance only when prior stage complete
- `AnalUnit` (packed u64): per-function/type granular tracking (not per-file)
- Three invalidation states: `potentially_outdated` → `outdated` (PO count=0) → `outdated_ready`
- Postponement ordering (PO): AnalUnit not ready until all PO deps analyzed
- Multiple dependency maps: `src_hash_deps`, `nav_val_deps`, `nav_ty_deps`, `interned_deps`, `namespace_deps`, `namespace_name_deps`
- `DepEntry` linked lists with `free_dep_entries` freelist for O(1) reuse
- TrackedInst: stable ZIR references across incremental updates; `.lost` sentinel for disappearing instructions
- Path canonicalization: `Compilation.Path` (root enum + sub_path) for import deduplication
- **Key files:** `src/Compilation.zig` (8.1K), `src/Zcu.zig` (4.8K), `src/InternPool.zig`

### TypeScript — Signature-Based Caching
- File signature = `.d.ts` hash; unchanged signature = dependents unaffected
- `ManyToManyPathMap`: bidirectional multimap (forward: file→imports, reverse: file←importers) with O(1) lookups
- `BuilderFileEmit` flags (bitwise): Js | JsMap | JsInlineMap | DtsErrors | DtsEmit | DtsMap
- `.tsbuildinfo`: serialized `ReusableBuilderProgramState` for cache persistence
- `EmitSignature`: string or [string] for `.d.ts` change detection
- `ReusableDiagnosticMessageChain`: separates structure from computed state; repopulation deferred until display
- SolutionBuilder orchestrates multi-project builds via project references
- **Key files:** `src/compiler/builder.ts` (115KB), `src/compiler/builderState.ts` (26KB)

### Lean 4 — Phase-Locked Pipeline
- Three phases: `base` (polymorphic) → `mono` (monomorphic) → `impure` (side effects explicit)
- Type-indexed IR: `Decl (pu : Purity)` — compiler catches phase violations at compile time
- PassManager: array of passes per phase; validates phase correctness
- PassInstaller DSL: `installAfter`, `installBefore`, `replacePass` for extensibility
- Savepoint passes (`saveBase`, `saveMono`) mark explicit phase boundaries
- SCC splitting before impure phase for deterministic compilation
- Per-phase transparency extensions: tracks which declarations can be inlined
- **Key files:** `src/Lean/Compiler/LCNF/Main.lean`, `src/Lean/Compiler/LCNF/PassManager.lean` (223L), `src/Lean/Compiler/LCNF/PhaseExt.lean`

### Cross-Cutting Patterns
- **Session-invariant fingerprints**: use stable hash (not pointers) for cross-session caching
- **Dependency propagation**: change file → find importers → mark stale → recheck
- **Phase-locked caching**: parse cache → type cache → eval cache; only reuse if input phase unchanged
- **Coarse-grained reuse units**: per-module or per-declaration, not per-expression
- **Side effect replay**: Rust/TS store diagnostics per query/file; replay on cache hit

---

## 4. Code Fixes & Suggestions

### Rust — Structured Suggestions
- `CodeSuggestion`: message + style + applicability + multiple substitution variants
- `Applicability` (4 levels): MachineApplicable → MaybeIncorrect → HasPlaceholders → Unspecified
- Subdiagnostics: composable labels/notes attached to parent diagnostic
- Builder pattern with must-use type (diagnostic consumed or panics on drop)
- **Key files:** `compiler/rustc_errors/src/diagnostic.rs`

### TypeScript — Code Action Registration
- Registry: `errorCodeToFixes = MultiMap<errorCode, CodeFixRegistration>` — 1 error → N fixes
- `getCodeActions` (single error) vs `getAllCodeActions` (batch)
- `ChangeTracker`: stateful builder, accumulates edits, defers text manipulation until commit
- Trivia-aware: `LeadingTriviaOption`, `TrailingTriviaOption` enums for fine-grained control
- AST-aware operations: `replaceNode()`, `insertModifierAt()`, `replaceNodeWithNodes()`
- `CodeFixContext` (dependency injection): program, sourceFile, span, errorCode — avoids threading
- 73 codefix files (~15.7K LOC), each ~150-200 LOC, consistent structure
- **Key files:** `src/services/codeFixProvider.ts`, `src/services/codefixes/` (73 files), `src/services/textChanges.ts`

### Gleam — Embedded Suggestions
- `did_you_mean()`: Levenshtein + case-insensitive fallback
- Adaptive threshold: 1/3 name length (min 1) prevents spurious suggestions
- Single-option auto-accepts; suggestions embedded in error message (not separate actions)
- **Key files:** `compiler-core/src/error.rs`

### Elm — Operator-Aware Suggestions
- Operator-specific handlers: `(+)` with strings → "Use (++) instead"
- `badListAdd`, `badListMul`, `badCast` — fine-grained error types by operator
- `addCategory`/`addPatternCategory`: customize messages based on type/context
- **Key files:** `compiler/src/Reporting/Error/Type.hs`

### Cross-Cutting Patterns
- **Applicability levels**: essential for automation (auto-fix vs user-review)
- **Registry pattern**: TypeScript enables dynamic fix discovery; error code → fix mapping
- **Batch vs single**: TypeScript separates single-fix from fix-all paths
- **Context preservation**: carry expression context through for "why expected X" suggestions

---

## 5. Compiler Architecture

### Rust — Query-Based Driver
- Wrapper/impl split: `rustc_driver` (thin) wraps `rustc_driver_impl` for isolation
- Query-based incremental with automatic dependency tracking
- `DiagCtxt`: global singleton, thread-safe behind `Lock`; `DiagCtxtHandle<'a>` borrowed handle
- Error counting: `Option<ErrorGuaranteed>` token — zero-cost checking
- **Key files:** `compiler/rustc_driver/src/lib.rs`

### Zig — Monolithic Compilation Unit
- Zcu holds all state: AST cache, ZIR cache, intern pool, analysis tracking
- Three IR levels: Zir (source-close) → Air (semantic) → LLVM
- Error accumulation: `failed_analysis`, `failed_codegen`, `failed_types` all separate maps
- Single Mutex covers all Compilation updates
- Progress nodes for parallel codegen with atomic counters
- Config struct pattern: >3 parameters → single `Compilation.Config`
- **Key files:** `src/main.zig` (7.5K), `src/Zcu.zig` (4.8K), `src/Compilation.zig` (8.1K)

### Go — Simple Multi-Pass
- Sequential pass pipeline with clear dependencies (devirtualize → inline → escape → SSA)
- Concurrent compilation: work queue with semaphore, longest functions first
- Three-level IR: AST → typed IR → SSA; one-way lowering
- Race detection mode: randomized compilation order to shake out data races
- SSA `Config` struct: readonly compilation info (arch, registers, PtrSize, optimization flags)
- Generated rewrite rules: 420K lines SSA rewrite per architecture (machine-generated)
- `ir.CurFunc = nil` after walk to enforce no further uses
- **Key files:** `cmd/compile/internal/gc/main.go`, `cmd/compile/internal/gc/compile.go`, `cmd/compile/internal/ssa/config.go`

### Gleam — Pure Library
- Pure library (`compiler-core`) with strong visibility discipline; no global state
- Phase pipeline: parse → analyse → type → codegen (Erlang/JavaScript)
- Module interface caching: `ModuleInterface` serialized (Cap'n Proto) for downstream modules
- Graph-based analysis: `call_graph` for dead code detection, `dep_tree` for build order
- Unified Error type across compiler (not phase-specific at top level)
- Document-based codegen: `pretty` crate for width-aware formatting; same tree → different languages
- **Key files:** `compiler-core/src/lib.rs`, `compiler-core/src/analyse.rs` (75KB), `compiler-core/src/build/`

### Koka — Effect-Aware Pipeline
- Phases: Parse → Kind Inference → Type Inference → Unreturn → FBIP Check → Simplify → FunLift → Optimize → Codegen
- CorePhase computation: `StateT Core (ErrorT Error (Unique IO))` — monadic pipeline
- DefGroups: `DefNonRec | DefRec [Def]` — recomputed per phase using SCC analysis
- Core IR has explicit effect annotation on lambdas: `Lam pars eff body`
- Borrowed tracking: `Borrowed = Map Name ([ParamInfo], Fip)` — per-function borrow info
- FBIP (Functional But In-Place): `Core/CheckFBIP.hs` (32KB), `Backend/C/Parc.hs` (44KB), `Backend/C/ParcReuse.hs`
- **Key files:** `src/Compile/Build.hs`, `src/Core/Borrowed.hs`, `src/Core/CheckFBIP.hs`

### Swift — ARC Optimizer (Ori's ARC Influence)
- Dual dataflow: top-down (retains from sources) + bottom-up (releases from sinks); pairing happens after both complete
- State machine lattices (RefCountState): `None → Decremented → MightBeUsed → MightBeDecremented` (bottom-up), complement for top-down
- RC Identity normalization: `RCIdentityFunctionInfo` — all operations track canonical root value whose refcount is affected
- "Known Safe" flag: if outer retain prevents deallocation, inner retain/release pair is redundant
- Blotting pattern: `BlotMapVector` — O(1) erasure via poisoning without rehashing, preserves iteration order
- `SmallBlotMapVector<T, 4>`: inline storage for first N entries (most functions ≤4 RC identities per BB)
- Loop summarization: processes bottom-up through loop tree; state summarized before parent loop
- `ARCMatchingSet`: decouples dataflow from pairing; separate pass walks inc/dec lists finding matches
- ImmutablePointerSetFactory: hash-consed sets for O(1) merge in dataflow
- SIL ownership: `@owned` (consume once) | `@guaranteed` (borrowed) | `@unowned` (checked weak)
- ARC optimizer: 5.7K lines across 21 files (11 .cpp + 10 .h)
- **Key files:** `lib/SILOptimizer/ARC/ARCSequenceOpts.cpp`, `lib/SILOptimizer/ARC/RefCountState.{h,cpp}` (1454L), `lib/SILOptimizer/ARC/GlobalARCSequenceDataflow.cpp`, `lib/SILOptimizer/ARC/ARCMatchingSet.cpp`

### Lean 4 — RC & Borrow Inference (Ori's ARC Influence)
- Two-phase: ExplicitRC (full RC graph with `inc`/`dec`) → BorrowInference (optimize away unnecessary ops)
- LiveVars: `{ vars: VarIdSet, borrows: VarIdSet }` — distinguishes direct use from borrow use
- DerivedValue tracking: parent-child projection chains; `addDescendants` walks to mark all derived values
- VarInfo: `isPossibleRef`, `isDefiniteRef`, `persistent` — refines based on actual expression
- Borrow inference: fixpoint iteration on `OwnedSet` — mark params as owned if used with reset/reuse or packed in constructor
- ParamMap with join points: `Key = decl(FunId) | jp(FunId, JoinPointId)` — separate analysis per join point
- IRType: `object | tobject | tagged` — object=heap ptr, tobject=maybe tagged, tagged=small scalar as ptr
- FnBody: `vdecl | jdecl | inc x n checkTag persistent body | dec | del | case | jmp | ret`
- Three-phase LCNF: base (polymorphic) → mono → impure; type-indexed IR catches phase violations
- Lowering: LCNF.Code → IR.FnBody via `ToIR.lowerCode` (explicit box/unbox insertion)
- **Key files:** `src/Lean/Compiler/IR/RC.lean` (480L), `src/Lean/Compiler/IR/Borrow.lean` (326L), `src/Lean/Compiler/IR/Basic.lean` (565L), `src/Lean/Compiler/IR/Boxing.lean`, `src/Lean/Compiler/IR/ExpandResetReuse.lean`

---

## 6. Test Infrastructure

### Rust — UI Test Framework
- `tests/ui/` organized by category (1000+ subdirectories)
- Convention: `.rs` (source) + `.stderr` (expected error output) + optional `.fixed` (auto-fix result)
- Annotations in source: `//~^ERROR message`, `//~| help: suggestion`
- Path normalization: `$DIR`, `$SRC_DIR` replace absolute paths for portability
- `//@ run-pass` / `//@ compile-fail` directives control expected outcome
- `--explain E0369` links error codes to documentation
- **Key files:** `tests/ui/` (1000+ subdirs)

### Zig — Multi-Backend Behavior Tests
- `test/behavior/` (100+ files): each file is standalone Zig program with `test` blocks
- Aggregated via `test { _ = @import("behavior/xyz.zig"); }` in `behavior.zig`
- `test/compile_errors.zig`: programmatic error case generation via `ctx.obj()` / `case.addError()`
- Multi-backend: same test runs on different codegen backends; skip if unsupported
- `@compileError("message")` annotations for compile-time error tests
- Conditional skip: `if (builtin.zig_backend == .stage2_spirv) return error.SkipZigTest`
- **Key files:** `test/behavior/`, `test/compile_errors.zig`, `test/cases/`

### Gleam — Snapshot Testing with Macros
- `insta` crate for snapshot testing (auto-update on intentional changes)
- Macros: `assert_module_error!($src)`, `assert_infer!($src, $type_)`
- Helper functions: `infer()`, `infer_module()`, `module_error()` — wrap behavior extraction
- Feature-per-module: `type_/tests/{accessors,assignments,custom_types,exhaustiveness,functions,...}.rs` (20+ modules)
- ~150+ test cases per module on average
- **Key files:** `compiler-core/src/type_/tests.rs`, `compiler-core/src/type_/tests/*.rs`

### Roc — File-Based Snapshot Testing
- Directory structure: `snapshots/{pass,fail,malformed}/{test_name}.{expr,full,moduledefs}.roc`
- Macro auto-registers new test files; env var `ROC_SNAPSHOT_TEST_OVERWRITE` for updates
- Orphaned snapshot detection: framework detects unused snapshot files
- `pretty_assertions` crate for colored diffs; `indoc!` macro for readable multiline test strings
- Expression promotion: tests automatically wrap expressions in valid modules for type-checking
- **Key files:** `crates/compiler/test_syntax/tests/test_snapshots.rs`, `crates/compiler/load/tests/test_reporting.rs`

### Go — Concurrent Compile Testing
- Race detection mode: randomized compilation order to expose data races
- `errorcheck` test framework: `Warnl()` writes compiler messages in expected format
- Test-generated SSA rewrite rules validated per architecture
- **Key files:** `test/` directory, `src/go/types/testdata/`

### Cross-Cutting Patterns
- **Blessed output**: Rust `.stderr` / Gleam snapshot / Roc file-based — expected output committed to repo
- **Source annotations**: Rust `//~^ERROR` — expected errors marked inline in test source
- **Category organization**: tests grouped by feature/concept, not by test type
- **Three test layers**: unit (inline `#[test]`), integration (separate files), conformance (spec-driven)
- **Compile-fail tests**: Ori uses `#[compile_fail("expected message")]` — closest to Rust's model
- **Snapshot management**: Gleam `insta`, Roc auto-register — low-maintenance test infrastructure

---

## 7. Memory Management (ARC/RC)

### Swift — Production ARC (5.7K lines)
- Dual-pass dataflow: top-down (retains) + bottom-up (releases); pairing in separate pass
- Lattice states proven safe: `None → Decremented → MightBeUsed → MightBeDecremented`
- RC identity normalization: track canonical root through field projections
- BlotMapVector: O(1) erasure without rehashing; SmallBlotMapVector<T, 4> inline storage
- ImmutablePointerSet: hash-consed sets for O(1) merge in dataflow
- Loop-aware: `GlobalLoopARCSequenceDataflow` summarizes loop bodies before parent analysis
- Nesting detection: restart analysis if new retain/release pair found after code motion
- **Key files:** `lib/SILOptimizer/ARC/` (21 files, 5.7K total)

### Lean 4 — RC + Borrow Inference
- Phase 1 (ExplicitRC): insert `inc`/`dec` based on live variable analysis
- Phase 2 (BorrowInference): fixpoint iteration to determine borrowed vs owned params
- `persistent` flag: statically known immutable objects skip RC overhead
- `ExpandResetReuse`: optimize destructor-constructor sequences (reuse allocation)
- Boxing pass: explicit `box`/`unbox` for scalar↔object conversion
- Join point discipline: separate borrow analysis per join point
- **Key files:** `src/Lean/Compiler/IR/{RC,Borrow,ExpandResetReuse,Boxing}.lean`

### Koka — FBIP (Functional But In-Place)
- `Core/CheckFBIP.hs` (32KB): validates functional-but-in-place invariants
- `Backend/C/Parc.hs` (44KB): precise ARC insertion for C backend
- `Backend/C/ParcReuse.hs`: allocation reuse analysis
- ParamInfo: `Own | Borrow` tracked per function parameter
- Borrowed map: `Map Name ([ParamInfo], Fip)` — per-function ownership info
- **Key files:** `src/Core/CheckFBIP.hs`, `src/Backend/C/Parc.hs`, `src/Backend/C/ParcReuse.hs`, `src/Core/Borrowed.hs`

---

## Quick Reference: Ori's Primary Influences

| Domain | Primary Source | Secondary | Ori Pattern |
|--------|---------------|-----------|-------------|
| Type interning | Zig InternPool | Rust TyCtxt | `Idx(u32)` + `Pool` |
| Error messages | Elm (structure) | Rust (applicability) | Three-part + suggestions |
| ARC optimization | Swift SIL | Lean 4 RC/Borrow | `ori_arc` crate |
| ARC reuse | Lean 4 ExpandResetReuse | Koka FBIP | Reset/reuse optimization |
| Effect system | Koka (rows) | — | Capabilities |
| Incremental | Rust (Salsa) | TS (signatures) | Salsa queries |
| Testing | Rust UI tests | Gleam snapshots | `#[compile_fail]` + spec tests |
| Architecture | Gleam (pure lib) | Zig (monolithic) | Crate hierarchy |
| Code fixes | TypeScript (registry) | Rust (applicability) | Error code → fix mapping |
| Constraint solving | Elm (CPS unify) | Roc (SOA storage) | Two-phase gen/solve |
| Diagnostics infra | Swift (.def files) | TS (JSON registry) | Centralized error catalog |
