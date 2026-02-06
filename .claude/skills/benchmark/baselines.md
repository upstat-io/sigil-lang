# Performance Baselines

Last updated: 2026-02-06

## Parser Raw Throughput

| Workload | Target (MiB/s) | Minimum | Notes |
|----------|----------------|---------|-------|
| 10 functions | 120 | 100 | Small file overhead |
| 50 functions | 140 | 120 | |
| 100 functions | 150 | 130 | |
| 500 functions | 165 | 140 | Steady state |
| 1000 functions | 160 | 140 | Steady state |

## Lexer Raw Throughput

| Workload | Target (MiB/s) | Minimum | Notes |
|----------|----------------|---------|-------|
| 10 functions | 230 | 200 | Small file overhead |
| 50 functions | 255 | 220 | |
| 100 functions | 264 | 230 | |
| 500 functions | 290 | 255 | Steady state |
| 1000 functions | 286 | 255 | Steady state |
| 5000 functions | 288 | 255 | Steady state |

## Salsa Query Overhead

Expected overhead when using Salsa queries vs raw:
- Lexer: ~10-15%
- Parser: ~30-40%

## Industry Comparison

| Parser | Throughput | Notes |
|--------|------------|-------|
| Ori parser | ~120-164 MiB/s | Hand-written recursive descent |
| Ori lexer | ~232-292 MiB/s | Logos DFA + tag array |
| Go | ~100-150 MiB/s | go/parser |
| Rust (syn) | ~50-100 MiB/s | Proc-macro parsing |
| TypeScript | ~200-400 MiB/s | Highly optimized |
| Zig | ~200-300 MiB/s | Hand-optimized |

## Regression Thresholds

- **Warning**: >5% slower than target
- **Failure**: >10% slower than minimum
- **Investigation needed**: >15% slower

## Memory Baselines

| Workload | Source Size | Lexer Peak | Parser Peak | Amplification |
|----------|-------------|------------|-------------|---------------|
| 10 funcs | 0.3 KB | 73 KB | 82 KB | 272x |
| 100 funcs | 3.2 KB | 120 KB | 200 KB | 62x |
| 500 funcs | 16.9 KB | 281 KB | 682 KB | 40x |
| 1000 funcs | 34.0 KB | 500 KB | 1301 KB | 38x |

### Memory Regression Thresholds

- **Warning**: >20% more peak memory
- **Failure**: >50% more peak memory
- **Allocation count**: >30% more allocations

### Memory Insights

- Small files have high amplification due to fixed overhead (interner, arena headers)
- Large files converge to ~38x amplification
- Parser uses ~2.5x more memory than lexer (AST nodes)

## Optimization History

| Date | Change | Impact |
|------|--------|--------|
| 2026-02-04 | TokenList Index inline | +25% parser |
| 2026-02-04 | Expression chain inlining | +20% parser |
| 2026-02-04 | Cursor optimizations | +13% parser |
| 2026-02-04 | Pre-allocation | +7% parser |
| 2026-02-04 | Added memory benchmarks | Baseline captured |
| 2026-02-06 | `#[cold]` split expect() | +5-8% parser |
| 2026-02-06 | Branchless advance() | +3-5% parser |
| 2026-02-06 | Tag-based dispatch (OPER_TABLE, tags Vec) | +10-20% parser, +7-14% lexer |
| 2026-02-06 | POSTFIX_BITSET fast-exit | +2-3% parser |
| 2026-02-06 | Direct dispatch in parse_primary() | +2-3% parser |
