# Performance Baselines

Last updated: 2026-02-08

## Lexer Core (Raw Scanner) Throughput

Pure `ori_lexer_core::RawScanner` — no keyword resolution, no literal parsing,
no interning, no diagnostics. This is the apples-to-apples comparison with
published lexer benchmarks from other compilers.

| Workload | Target (MiB/s) | Minimum | Notes |
|----------|----------------|---------|-------|
| 10 functions | 720 | 650 | Small file overhead |
| 50 functions | 890 | 800 | |
| 100 functions | 910 | 820 | |
| 500 functions | 960 | 870 | Steady state |
| 1000 functions | 965 | 870 | Steady state |
| 5000 functions | 1020 | 920 | Steady state, ~1 GiB/s |

## Parser Raw Throughput

| Workload | Target (MiB/s) | Minimum | Notes |
|----------|----------------|---------|-------|
| 10 functions | 95 | 80 | Small file overhead |
| 50 functions | 113 | 95 | |
| 100 functions | 118 | 100 | |
| 500 functions | 126 | 105 | Steady state |
| 1000 functions | 128 | 108 | Steady state |

## Lexer (Cooked) Raw Throughput

Full `ori_lexer::lex()` — includes keyword resolution, literal parsing, string
interning, escape processing, and flag computation on top of raw scanning.

| Workload | Target (MiB/s) | Minimum | Notes |
|----------|----------------|---------|-------|
| 10 functions | 208 | 180 | Small file overhead |
| 50 functions | 227 | 195 | |
| 100 functions | 232 | 200 | |
| 500 functions | 235 | 200 | Steady state |
| 1000 functions | 238 | 205 | Steady state |
| 5000 functions | 240 | 205 | Steady state |

## Salsa Query Overhead

Expected overhead when using Salsa queries vs raw:
- Lexer: ~10-15%
- Parser: ~30-40%

## Industry Comparison

| Component | Throughput | Notes |
|-----------|------------|-------|
| Ori raw scanner | ~720–1020 MiB/s | Hand-written, sentinel-terminated |
| Ori cooked lexer | ~208–240 MiB/s | + keywords, literals, interning |
| Ori parser | ~95–128 MiB/s | Hand-written recursive descent |
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
| 2026-02-08 | Added lexer_core benchmark, rebased cooked lexer baselines | New tier |
