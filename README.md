# Artifact for *Lean-SMT*  
**Paper submission number:** 305
**Claimed badges:** Available, Functional, Reusable  

---

## Artifact Requirements

The artifact is provided as a Docker image. We recommend using a machine with the following specifications:

- **CPU**: 16-core (32-thread) processor or higher  
- **RAM**: 32 GB minimum; 128 GB recommended for full experiments  
- **Storage**: At least 100 GB free disk space (image size ~48.5 GB uncompressed)  
- **Operating System**: Linux, macOS, or Windows with Docker support  
- **Internet Connection**: Required if building the Docker image manually

Estimated runtimes for the benchmark categories:

| Benchmark Set | Configuration                          | Time (approx.) |
|---------------|----------------------------------------|----------------|
| Seventeen     | cvc5+leansmt, duper                    | ~1 hour        |
| Seventeen     | verit+sledgehammer                     | ~8 hours       |
| SMT-LIB       | cvc5+leansmt, cvc5+ethos, verit+smtcoq | ~4 hours       |

The `smoketest` and `brief` subsets can be run in significantly less time:
- `smoketest`: ~10 minutes  
- `brief`: ~5 hour  

Evaluation was performed on a cluster of 48 nodes with:
- AMD Ryzen 9 7950X @ 4.50GHz
- 128 GB RAM

---

## Structure and Content

The artifact includes:

- **Source Code:**
  - `lean-smt/`: Lean-SMT tactic
  - `lean-cpc-checker/`: SMT-LIB v2 frontend (CPC checker)
- **Benchmarking & Evaluation Scripts:**
  - `run_all_benchmarks.sh`: main script for evaluation
  - `cvc5+ethos.sh`, `cvc5+leansmt.sh`, `duper.sh`, `verit+sledgehammer.sh`, `verit+smtcoq.sh`: wrappers for each configuration
  - `run_benchmarks.py`: runs a solver over benchmark sets
  - `collect_*_stats.py`: parses logs into CSVs
  - `cactus.py`, `scatter.py`, `tables.py`: visualization tools
  - `benchmarks/seventeen`, `benchmarks/SMT-LIB`: previous benchmark output (with slight changes for cluster runs)
**Docker Image Contents (`abdoo8080/lean-smt-artifact:v1`):**
- Precompiled versions of all tools
- Benchmark datasets (`benchmarks/seventeen`, `benchmarks/SMT-LIB`)
- Isabelle/AFP versions as used in the Seventeen Provers under the Hammer paper
- Benchmark index files: `smtlib_*.txt`, `seventeen_*.txt`

---

## Getting Started

Pull the Docker image:

```bash
docker pull abdoo8080/lean-smt-artifact:v1
```

Or, build it from source (estimated time: 2-3 hours):

```bash
docker build -t artifact .
```

Then run the container:

```bash
docker run -it artifact
```

Within the container, use:

```bash
./run_all_benchmarks.sh <mode> [<jobs>] [--enable-sledgehammer]
```

Where `<mode>` is one of:
- `smoketest`: quick verification (10 samples per category)
- `brief`: substantial verification (500 samples per category)
- `full`: complete benchmark set (5000 baseline, 24817 SMT-LIB)

**Note:** The `verit+sledgehammer` configuration is excluded by default due to high memory and runtime requirements. You can run it separately by invoking `verit+sledgehammer.sh` with appropriate arguments. It requires:
- 16 GB memory per job
- Single-threaded mode
- Extended timeouts (up to 20 minutes per benchmark)

---

## Functional Badge

This artifact reproduces all experimental results shown in the paper, including:

- Figures: `seventeen.pdf`, `QF_SMT-LIB.pdf`, `SMT-LIB.pdf`, `scatter.pdf`
- Tables: `seventeen.tex`, `QF_SMT-LIB.tex`, `SMT-LIB.tex`

These are generated after running the `run_all_benchmarks.sh` script and are placed in the `figures/` and `tables/` directories.

To copy them to the host machine:

```bash
docker ps        # Get <container-id>
docker cp <container-id>:/home/user/artifact/figures/<figure>.pdf ./output/
```

Correctness is ensured by Lean's kernel checking the proofs:
- For CPC checker: see `lean-cpc-checker/Checker.lean`, lines 111–119
- For tactic-based checking, Lean's frontend automatically invokes the kernel after proof generation

---

## Reusable Badge

The Lean-SMT tactic and its SMT-LIB frontend are open source, licensed under **Apache 2.0**:

- [Lean-SMT GitHub Repository (link)](https://github.com/ufmg-smite/lean-smt)
- [CPC Checker GitHub Repository (link)](https://github.com/abdoo8080/lean-cpc-checker)

### Portability & Compatibility

- Works with Lean v4.15.0 (Jan 2025 toolchain)
- Compatible with Linux and macOS (both x86 and ARM)
- Planned support for Windows

To use Lean-SMT in another Lean project:
1. Add it as a dependency in `lakefile.toml` similar to how it is included in `lean-cpc-checker/lakefile.toml`
2. Run `lake update` and `lake build` to compile

All dependencies are explicitly listed and version-pinned in the `Dockerfile`. Additional instructions for standalone installation outside Docker can be provided if needed.
