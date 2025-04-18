#!/bin/bash

set -e

###############################################################################
# Functions
###############################################################################

# Display usage/help
usage() {
  echo "Usage: $0 <smoketest|brief|full> [<jobs>] [--enable-sledgehammer]"
  echo ""
  echo "Mode descriptions:"
  echo "  smoketest  - Use 10 benchmarks (quick check)"
  echo "  brief      - Use 500 benchmarks (medium check)"
  echo "  full       - Use all benchmarks (comprehensive run)"
  echo ""
  echo "Optional arguments:"
  echo "  <jobs>                - Number of parallel jobs to run (default: 4)"
  echo "  --enable-sledgehammer - Run verit+sledgehammer benchmarks (disabled by default)"
  exit 1
}

# Run the 'Seventeen' benchmarks (fixed 60s timeout)
run_seventeen_benchmarks() {
  local smt2_file="$1"
  local fof_file="$2"
  local JOBS="$3"
  local SLEDGE="$4"

  # Always use 60 seconds for cvc5+leansmt
  python3 run_benchmarks.py "$smt2_file" cvc5+leansmt --jobs "$JOBS" --timeout 60 --memout 8192
  python3 collect_leansmt_stats.py /home/user/artifact/output/cvc5+leansmt/seventeen /home/user/artifact/data/seventeen/cvc5+leansmt.csv

  # Always use 60 seconds for duper
  python3 run_benchmarks.py "$fof_file" duper --jobs "$JOBS" --timeout 60 --memout 8192
  python3 collect_duper_stats.py /home/user/artifact/output/duper/seventeen /home/user/artifact/data/seventeen/duper.csv

  # Only run sledgehammer if enabled
  if [ "$SLEDGE" -eq 1 ]; then
    # Single job / bigger memout / bigger timeout for sledgehammer
    python3 run_benchmarks.py "$smt2_file" verit+sledgehammer --jobs 1 --timeout 1200 --memout 16384
    python3 collect_sledgehammer_stats.py /home/user/artifact/output/verit+sledgehammer/seventeen /home/user/artifact/data/seventeen/verit+sledgehammer.csv
  fi

  python3 tables.py /home/user/artifact/data/seventeen /home/user/artifact/tables/seventeen.tex
  python3 cactus.py /home/user/artifact/data/seventeen /home/user/artifact/figures/seventeen.pdf
}

# Run the SMT-LIB benchmarks (60s for smoketest; 20min = 1200s for brief/full)
run_smtlib_benchmarks() {
  local smt_file="$1"
  local JOBS="$2"
  local TIMEOUT="$3"

  python3 run_benchmarks.py "$smt_file" cvc5+leansmt --jobs "$JOBS" --timeout "$TIMEOUT" --memout 8192
  python3 collect_leansmt_stats.py /home/user/artifact/output/cvc5+leansmt/SMT-LIB /home/user/artifact/data/SMT-LIB/cvc5+leansmt.csv

  python3 run_benchmarks.py "$smt_file" cvc5+ethos --jobs "$JOBS" --timeout "$TIMEOUT" --memout 8192
  python3 collect_ethos_stats.py /home/user/artifact/output/cvc5+ethos/SMT-LIB /home/user/artifact/data/SMT-LIB/cvc5+ethos.csv

  python3 run_benchmarks.py "$smt_file" verit+smtcoq --jobs "$JOBS" --timeout "$TIMEOUT" --memout 8192
  python3 collect_smtcoq_stats.py /home/user/artifact/output/verit+smtcoq/SMT-LIB /home/user/artifact/data/SMT-LIB/verit+smtcoq.csv

  python3 tables.py /home/user/artifact/data/SMT-LIB /home/user/artifact/tables/SMT-LIB.tex
  python3 tables.py --benchmark_filter QF_ /home/user/artifact/data/SMT-LIB /home/user/artifact/tables/QF_SMT-LIB.tex
  python3 cactus.py /home/user/artifact/data/SMT-LIB /home/user/artifact/figures/SMT-LIB.pdf
  python3 cactus.py --benchmark_filter QF_ /home/user/artifact/data/SMT-LIB /home/user/artifact/figures/QF_SMT-LIB.pdf
  python3 scatter.py /home/user/artifact/data/SMT-LIB/cvc5+leansmt.csv /home/user/artifact/data/SMT-LIB/cvc5+ethos.csv /home/user/artifact/figures/scatter.pdf
}

###############################################################################
# Main Script Logic
###############################################################################

MODE=""
JOBS=4          # Default jobs
SLEDGEHAMMER=0  # Disabled by default

# If user gave no arguments, show usage
[ $# -lt 1 ] && usage

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    smoketest|brief|full)
      MODE="$1"
      shift
      ;;
    --enable-sledgehammer)
      SLEDGEHAMMER=1
      shift
      ;;
    [0-9]*)
      JOBS="$1"
      shift
      ;;
    *)
      usage
      ;;
  esac
done

# Validate MODE
if [ -z "$MODE" ]; then
  usage
fi

# Default files
SEVENTEEN_SMT2_FILE=""
SEVENTEEN_FOF_FILE=""
SMTLIB_FILE=""
TIMEOUT=0

case "$MODE" in
  smoketest)
    SEVENTEEN_SMT2_FILE="seventeen_smt2_10.txt"
    SEVENTEEN_FOF_FILE="seventeen_fof_10.txt"
    SMTLIB_FILE="smtlib_10.txt"
    TIMEOUT=60
    ;;
  brief)
    SEVENTEEN_SMT2_FILE="seventeen_smt2_500.txt"
    SEVENTEEN_FOF_FILE="seventeen_fof_500.txt"
    SMTLIB_FILE="smtlib_500.txt"
    TIMEOUT=1200
    ;;
  full)
    SEVENTEEN_SMT2_FILE="seventeen_smt2_full.txt"
    SEVENTEEN_FOF_FILE="seventeen_fof_full.txt"
    SMTLIB_FILE="smtlib_full.txt"
    TIMEOUT=1200
    ;;
  *)
    usage
    ;;
esac

# Clean up previous outputs
rm -rf /home/user/artifact/data \
       /home/user/artifact/figures \
       /home/user/artifact/output \
       /home/user/artifact/tables

# Set the stack size to unlimited
ulimit -s unlimited

# Run the benchmarks
run_seventeen_benchmarks "$SEVENTEEN_SMT2_FILE" "$SEVENTEEN_FOF_FILE" "$JOBS" "$SLEDGEHAMMER"
run_smtlib_benchmarks    "$SMTLIB_FILE"          "$JOBS" "$TIMEOUT"

echo "All benchmarks completed (mode: $MODE, jobs: $JOBS, sledgehammer enabled: $SLEDGEHAMMER)."
