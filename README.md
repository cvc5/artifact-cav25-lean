# Artifact for *Lean-SMT*  
**Paper submission number:** 305  
**Claimed badges:** Available, Functional, Reusable

---

## Artifact Requirements

The artifact is provided as a Docker image. We recommend using a machine with the following specifications:

- **CPU**: 16-core (32-thread) processor for `brief` experiments
- **RAM**: 128 GB for `brief` experiments
- **Storage**: At least 60 GB free disk space (image size ~48.5 GB uncompressed)
- **Operating System**: Linux, macOS, or Windows with Docker support  
- **Internet Connection**: Required if building the Docker image manually

Estimated runtimes for the benchmark categories:

| Benchmark Set | Configuration                                   | Time (approx.) |
|---------------|-------------------------------------------------|----------------|
| Seventeen     | cvc5+leansmt±compiler, duper                    | ~1 hour        |
| Seventeen     | verit+sledgehammer                              | ~8 hours       |
| SMT-LIB       | cvc5+leansmt±compiler, cvc5+ethos, verit+smtcoq | ~4 hours       |

Evaluation was performed on a cluster of 48 nodes with:
- AMD Ryzen 9 7950X @ 4.50GHz
- 128 GB RAM

The `smoke`, `minimal`, and `brief` subsets can be run in significantly less time with recommended specifications:
- `smoke`: ~10 minutes
- `minimal`: ~2 hours
- `brief`: ~8 hours

---

## Structure and Content

The artifact includes:

- **Source Code:**
  - `lean-smt/`: Lean-SMT tactic
  - `lean-cpc-checker/`: SMT-LIB v2 frontend (CPC checker)
- **Benchmarking & Evaluation Scripts:**
  - `run_all_benchmarks.sh`: main script for evaluation
  - `generate_figures_and_tables.sh`: generates figures and tables from data in `data` directory
  - `cvc5+ethos.sh`, `cvc5+leansmt±compiler.sh`, `duper.sh`, `verit+sledgehammer.sh`, `verit+smtcoq.sh`: wrappers for each configuration
  - `run_benchmarks.py`: runs a solver over benchmark sets
  - `collect_*_stats.py`: parses logs into CSVs
  - `cactus.py`, `scatter±compiler.py`, `tables.py`: visualization tools
  - `data/all/seventeen`, `data/all/SMT-LIB`: data from paper evaluation (slightly modified for artifact scripts)
**Docker Image Contents (`abdoo8080/lean-smt-artifact:v4`):**
- Precompiled versions of all tools
- Benchmark datasets (`benchmarks/seventeen`, `benchmarks/SMT-LIB`)
- Isabelle/AFP versions as used in the Seventeen Provers under the Hammer paper

---

## Getting Started

Pull the Docker image (available for x86 architecture):

```bash
docker pull abdoo8080/lean-smt-artifact:v4
```

Or, build it from source (estimated time: 2-3 hours on recommended hardware):

```bash
docker build -t abdoo8080/lean-smt-artifact:v4 .
```

Then run the container:

```bash
docker run -it abdoo8080/lean-smt-artifact:v4
```

Within the container, use:

```bash
./run_all_benchmarks.sh --mode <mode> [--jobs <J>] [--enable-sledgehammer]
```

Where `<mode>` is one of:
- `smoke`: quick verification (10 samples per category)
- `minimal`: minimal verification (100 samples per category)
- `brief`: substantial verification (500 samples per category)
- `all`: complete benchmark set (5000 baseline, 24817 SMT-LIB)

**Note on Modes and Hardware Requirements:**
`minimal` mode is recommended for hardware with specifications that are significantly lower than our suggested configuration. It uses fewer benchmarks and smaller timeouts to accommodate such environments. You can customize the number of benchmarks, the number of parallel jobs (ideally up to the number of physical CPU cores), and the per-benchmark timeout/memory limit using the script's command-line options.

**About Isabelle Sledgehammer:**
The `verit+sledgehammer` solver is excluded by default due to its high requirements. You can run it by invoking the script with `--enable-sledgehammer` argument. The higher requirements are due to `verit+sledgehammer` not directly running on the `seventeen` benchmark set. Instead, it locates the original Isabelle goals that produced the benchmarks and builds all the Isabelle sessions required for that before running sledgehammer on the goal. Building sessions uses all CPU cores and the time it takes highly depends on the sessions needed, hence the higher requirements below:
- 16 GB memory per job
- Single-threaded mode
- Extended timeouts (up to 20 minutes per benchmark)

**Visualizing Original Data:**
The directories `data/all/seventeen` and `data/all/SMT-LIB` contain data collected from evaluating `all` benchmarks for comparison. You can visualize this data by running:
```bash
./generate_figures_and_tables.sh all
```
This script scans the `data/all` directory, then produces the figures and tables in `/home/user/artifact/figures/all` and `/home/user/artifact/tables/all`.

---

## Functional Badge

This artifact reproduces all experimental results shown in the paper, including:

- Figures: `seventeen.pdf`, `QF_SMT-LIB.pdf`, `SMT-LIB.pdf`, `scatter±compiler.pdf`
- Tables: `seventeen.tex`, `QF_SMT-LIB.tex`, `SMT-LIB.tex`

These are generated after running the `run_all_benchmarks.sh` script and are placed in the `figures/<mode>` and `tables/<mode>` directories.

To copy them to the host machine:

```bash
docker ps        # Get <container-id>
docker cp <container-id>:/home/user/artifact/figures .
```

Correctness is ensured by Lean's kernel checking the proofs:
- For CPC checker: see `lean-cpc-checker/Checker.lean`, lines 111–119
- For tactic-based checking, Lean's frontend automatically invokes the kernel after proof generation

---

## Reusable Badge

The artifact, encompassing the Lean-SMT tactic, its SMT-LIB frontend, and the associated benchmarking scripts, is open source and distributed under the **Apache 2.0 License**:

- [Lean-SMT GitHub Repository (link)](https://github.com/ufmg-smite/lean-smt)
- [CPC Checker GitHub Repository (link)](https://github.com/abdoo8080/lean-cpc-checker)

### Portability & Compatibility

- Works with Lean v4.20.0-rc5 (June 2025 toolchain release candidate)
- Compatible with Linux and macOS (both x86 and ARM) and Windows (only x86 as Lean does not currently support ARM on Windows)

To use Lean-SMT in another Lean project:
1. Add it as a dependency in `lakefile.toml` similar to how it is included in `lean-cpc-checker/lakefile.toml`
2. Run `lake update` and `lake build` to compile

All dependencies are explicitly listed and version-pinned in the `Dockerfile`.
