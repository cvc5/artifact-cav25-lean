# Artifact for lean-smt

## Structure

The artifact is comprised by the following items:

- The cvc5 SMT solver, under the folder `cvc5/`
- Lean's Duper plugin, under the folder `duper/`
- Our checker for CPC proofs, under the folder `lean-cpc-checker/`
- The seventeen provers benchmark, under the folder `benchmarks/seventeen/baseline_probs`
- The SMT-LIB benchmark, under the folder `benchmarks/SMT-LIB/non-incremental`
- The files `smtlib_*.txt` and `seventeen_*.txt` specifying which benchmarks to run, depending on the option given to `run_all_benchmarks.sh`.
- The script `run_all_benchmarks.sh`, which is the entry point for running the benchmark
- The scripts `cactus.py`, `collect_duper_stats.py`, `collect_ethos_stats.py`, `collect_leansmt_stats.py`, `scatter.py`A and `tables.py` that generate the plots used in our paper

## Run instructions

First, go to the root of the artifact. Then, build the docker image with:

```bash
docker build -t artifact .
```

Usually this is fast, but in some rare cases Zenodo's server is unusually slow, so it could take up to 2 hours.

Next, run the container with `docker run -it artifact`. There will be a script named `run_all_benchmarks.sh` for running all our benchmarks. For running it, it's necessary to provide one of the following options:

- `smoketest`, which runs just 10 samples of each benchmark.
- `brief`, which runs 500 tests from each benchmark.
- `full`, which runs the complete benchmark.

The benchmark is split into three categories: `seventeen_fof`, which comprises 5000 test cases; `seventeen_smt2`, which also comprises 5000 test cases and `smtlib`, which comprises 24817 test cases.

## Expected runtime

<!-- Abdal please fill here the time it takes to run each version of the script and which hardware you used -->

## Description of produced results

After running the `run_all_benchmarks.sh` script, a folder called `figures` should be created, with 4 plots:
- QF_SMT-LIB.pdf which compares the time for solving and checking the quantifier free fragment of the SMT-LIB benchmark using `cvc5` with `lean-smt` vs using `cvc5` with `ethos`.
- SMT-LIB.pdf, which compares the time for solving and checking the SMT-LIB benchmark using `cvc5` with `lean-smt` vs using `cvc5` with `ethos`.
- scatter.pdf, which compares the proof checking time of `ethos` and `lean-smt`
- seventeen.pdf, which compares the perfomances of `duper` and `lean-smt` in the seventeen provers benchmark

To be able to see them, you need to copy them outside the container to the host machine. This can be done,
for instance, by running `docker cp <image-id>:/home/user/artifact/figures/*.pdf $HOME`, where `<image-id>`
is the id corresponding to the docker image of the artifact, which can be obtained by running
`docker ps`, which will give the id in the first column of the line corresponding to the artifact's image.

<!-- Are all the claims of the paper replicable?  -->

<!-- Reference: https://conferences.i-cav.org/2025/artifact/ -->
