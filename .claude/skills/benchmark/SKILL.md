---
name: benchmark
description: Run parser/lexer benchmarks with configurable duration (short, medium, long, memory)
argument-hint: <duration>
disable-model-invocation: true
allowed-tools: Bash, Read
---

# Ori Compiler Benchmarks

Run performance benchmarks for the Ori compiler with duration level: **$ARGUMENTS**

## Duration Levels

| Level | Samples | Use Case |
|-------|---------|----------|
| `short` | ~50 samples, 2s warmup | Quick sanity check (~30s) |
| `medium` | ~100 samples (default) | Standard benchmarking (~2min) |
| `long` | ~300 samples, extended | Release validation (~5min) |
| `memory` | Single iteration | Heap allocation profiling |

## Benchmark Suites

### Throughput Benchmarks
- `parser/raw/throughput/*` — Raw parser throughput (MiB/s)
- `lexer/raw/throughput/*` — Raw lexer throughput (MiB/s)

### Memory Benchmarks
- `memory/lexer/*` — Lexer heap allocations
- `memory/parser/*` — Parser heap allocations
- `memory/summary` — Memory amplification report

## Instructions

1. Build release profile first
2. Run benchmarks based on duration level
3. Report throughput numbers with comparison to baseline
4. Highlight any regressions (>5% slower or >20% more memory)

## Benchmark Commands

For **short** duration:
```bash
cargo bench -p oric --bench parser -- "raw/throughput" --noplot --warm-up-time 2 --sample-size 50
cargo bench -p oric --bench lexer -- "raw/throughput" --noplot --warm-up-time 2 --sample-size 50
```

For **medium** duration:
```bash
cargo bench -p oric --bench parser -- "raw/throughput" --noplot
cargo bench -p oric --bench lexer -- "raw/throughput" --noplot
```

For **long** duration:
```bash
cargo bench -p oric --bench parser -- "raw" --noplot --sample-size 300
cargo bench -p oric --bench lexer -- "raw" --noplot --sample-size 300
```

For **memory** profiling:
```bash
cargo bench -p oric --bench memory -- "memory/summary" --noplot
```

## Expected Baselines

See [baselines.md](baselines.md) for current performance targets.

## Output Format

For throughput benchmarks, report as:

```
## Benchmark Results ($ARGUMENTS)

### Parser Throughput
| Workload | Throughput | vs Baseline |
|----------|------------|-------------|
| 10 funcs | XX MiB/s   | +X% / -X%   |
| ...      | ...        | ...         |

### Lexer Throughput
| Workload | Throughput | vs Baseline |
|----------|------------|-------------|
| ...      | ...        | ...         |

### Summary
- Parser: XX MiB/s average
- Lexer: XX MiB/s average
- Status: OK / REGRESSION DETECTED
```

For memory benchmarks, report the summary table and note any significant changes in allocation count or peak memory.
