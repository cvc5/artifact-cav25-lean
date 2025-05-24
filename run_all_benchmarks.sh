#!/bin/bash

set -e

###############################################################################
# Default Settings
###############################################################################
MODE=""                # A label for known subsets: smoke, minimal, brief, all
N=0                    # Number of benchmarks (0 = unknown yet)
JOBS=4                 # Parallel jobs
TIMEOUT=60             # Default timeout (seconds)
MEMOUT=8192            # Default memory limit (MB)
SLEDGEHAMMER=0         # Disabled by default

# “All” benchmark files:
SMTLIB_ALL="/home/user/artifact/smtlib_all.txt"
SEVENTEEN_SMT2_ALL="/home/user/artifact/seventeen_smt2_all.txt"
SEVENTEEN_FOF_ALL="/home/user/artifact/seventeen_fof_all.txt"

###############################################################################
# Help/Usage
###############################################################################
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --mode <smoke|minimal|brief|all>       Shortcut for N, TIMEOUT, MEMOUT."
  echo "  --count <N>                            Number of benchmarks to run."
  echo "  --jobs <J>                             Number of parallel jobs (default: 4)."
  echo "  --timeout <T>                          Per-benchmark timeout (seconds)."
  echo "  --memout <M>                           Per-benchmark memory limit (MB)."
  echo "  --enable-sledgehammer                  Enable verit+sledgehammer (default: off)."
  echo "  -h, --help                             Show this message."
  echo ""
  echo "Examples:"
  echo "  $0 --mode smoke"
  echo "  $0 --mode brief --enable-sledgehammer --jobs 8"
  echo "  $0 --count 50 --timeout 120 --memout 10000"
  exit 1
}

###############################################################################
# Parse Command-Line Arguments
###############################################################################
while [ $# -gt 0 ]; do
  case "$1" in
    --mode)
      shift
      MODE="$1"
      ;;
    --count)
      shift
      N="$1"
      ;;
    --jobs)
      shift
      JOBS="$1"
      ;;
    --timeout)
      shift
      TIMEOUT="$1"
      ;;
    --memout)
      shift
      MEMOUT="$1"
      ;;
    --enable-sledgehammer)
      SLEDGEHAMMER=1
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unrecognized option: $1"
      usage
      ;;
  esac
  shift
done

###############################################################################
# Mode-based Defaults (can be overridden by explicit flags)
###############################################################################
case "$MODE" in
  smoke)
    # 10 benchmarks, 60s timeout, 8192 MB
    [ "$N" -eq 0 ] && N=10
    [ "$TIMEOUT" -eq 60 ] && TIMEOUT=60
    [ "$MEMOUT" -eq 8192 ] && MEMOUT=8192
    ;;
  minimal)
    # 100 benchmarks, 1200s timeout, 8192 MB
    [ "$N" -eq 0 ] && N=100
    [ "$TIMEOUT" -eq 60 ] && TIMEOUT=300
    [ "$MEMOUT" -eq 8192 ] && MEMOUT=8192
    ;;
  brief)
    # 500 benchmarks, 1200s timeout, 8192 MB
    [ "$N" -eq 0 ] && N=500
    [ "$TIMEOUT" -eq 60 ] && TIMEOUT=1200
    [ "$MEMOUT" -eq 8192 ] && MEMOUT=8192
    ;;
  all)
    # “All” uses separate files: smtlib_all.txt, seventeen_smt2_all.txt, etc.
    [ "$N" -eq 0 ] && N=-1  # Not strictly used for 'all', but set a default
    [ "$TIMEOUT" -eq 60 ] && TIMEOUT=1200
    [ "$MEMOUT" -eq 8192 ] && MEMOUT=8192
    ;;
  "")
    # No mode => user sets N, TIMEOUT, MEMOUT manually
    ;;
  *)
    echo "Unknown mode: $MODE"
    usage
    ;;
esac

# If user never sets count or mode => default to 10
[ "$N" -eq 0 ] && N=10

###############################################################################
# Construct Filenames for Benchmarks
###############################################################################
# If mode=all, use the “*_all.txt” files directly (no subsetting).
# If we have a named mode (smoke, minimal, brief), create e.g. “seventeen_smt2_brief.txt” from head -n N.
# If no mode, create e.g. “seventeen_smt2_50.txt” (where 50 is the chosen count).
###############################################################################
if [ "$MODE" = "all" ]; then
  SEVENTEEN_SMT2_FILE="$SEVENTEEN_SMT2_ALL"
  SEVENTEEN_FOF_FILE="$SEVENTEEN_FOF_ALL"
  SMTLIB_FILE="$SMTLIB_ALL"
else
  if [ -n "$MODE" ]; then
    # e.g. “smoke”, “minimal”, “brief”
    SEVENTEEN_SMT2_FILE="/home/user/artifact/seventeen_smt2_${MODE}.txt"
    SEVENTEEN_FOF_FILE="/home/user/artifact/seventeen_fof_${MODE}.txt"
    SMTLIB_FILE="/home/user/artifact/smtlib_${MODE}.txt"
  else
    # No mode => name by the number of benchmarks
    SEVENTEEN_SMT2_FILE="/home/user/artifact/seventeen_smt2_${N}.txt"
    SEVENTEEN_FOF_FILE="/home/user/artifact/seventeen_fof_${N}.txt"
    SMTLIB_FILE="/home/user/artifact/smtlib_${N}.txt"
  fi

  # Generate from the “full” files
  head -n "$N" "$SEVENTEEN_SMT2_ALL" > "$SEVENTEEN_SMT2_FILE"
  head -n "$N" "$SEVENTEEN_FOF_ALL" > "$SEVENTEEN_FOF_FILE"
  head -n "$N" "$SMTLIB_ALL"        > "$SMTLIB_FILE"
fi

###############################################################################
# Prepare Output Paths
###############################################################################
RUN_ID="$MODE"
[ -z "$RUN_ID" ] && RUN_ID="$N"

DATA_DIR="/home/user/artifact/data/$RUN_ID"
FIGURES_DIR="/home/user/artifact/figures/$RUN_ID"
OUTPUT_DIR="/home/user/artifact/output/$RUN_ID"
TABLES_DIR="/home/user/artifact/tables/$RUN_ID"

rm -rf "$DATA_DIR" "$FIGURES_DIR" "$OUTPUT_DIR" "$TABLES_DIR"
mkdir -p "$DATA_DIR" "$FIGURES_DIR" "$OUTPUT_DIR" "$TABLES_DIR"

# Set unlimited stack size
ulimit -s unlimited

###############################################################################
# Run Functions
###############################################################################
run_seventeen_benchmarks() {
  local smt2_file="$1"
  local fof_file="$2"
  local jobs="$3"
  local timeout="$4"
  local memout="$5"
  local sledge="$6"

  # Always 60s for cvc5+leansmt-compiler
  python3 run_benchmarks.py "$smt2_file" cvc5+leansmt-compiler \
    --jobs "$jobs" --timeout "$timeout" --memout "$memout" \
    --output_dir "$OUTPUT_DIR"
  python3 collect_leansmt_stats.py "$OUTPUT_DIR/cvc5+leansmt-compiler/seventeen" "$DATA_DIR/seventeen/cvc5+leansmt-compiler.csv"

  # Always 60s for cvc5+leansmt+compiler
  python3 run_benchmarks.py "$smt2_file" cvc5+leansmt+compiler \
    --jobs "$jobs" --timeout "$timeout" --memout "$memout" \
    --output_dir "$OUTPUT_DIR"
  python3 collect_leansmt_stats.py "$OUTPUT_DIR/cvc5+leansmt+compiler/seventeen" "$DATA_DIR/seventeen/cvc5+leansmt+compiler.csv"

  # Always 60s for duper
  python3 run_benchmarks.py "$fof_file" duper \
    --jobs "$jobs" --timeout "$timeout" --memout "$memout" \
    --output_dir "$OUTPUT_DIR"
  python3 collect_duper_stats.py "$OUTPUT_DIR/duper/seventeen" "$DATA_DIR/seventeen/duper.csv"

  # Sledgehammer if enabled
  if [ "$sledge" -eq 1 ]; then
    python3 run_benchmarks.py "$smt2_file" verit+sledgehammer \
      --jobs 1 --timeout 1200 --memout 16384 \
      --output_dir "$OUTPUT_DIR"
    python3 collect_sledgehammer_stats.py "$OUTPUT_DIR/verit+sledgehammer/seventeen" "$DATA_DIR/seventeen/verit+sledgehammer.csv"
  fi

  # Summaries
  python3 tables.py "$DATA_DIR/seventeen" "$TABLES_DIR/seventeen.tex"
  python3 cactus.py "$DATA_DIR/seventeen" "$FIGURES_DIR/seventeen.pdf"
}

run_smtlib_benchmarks() {
  local smt_file="$1"
  local jobs="$2"
  local timeout="$3"
  local memout="$4"

  # cvc5+leansmt-compiler
  python3 run_benchmarks.py "$smt_file" cvc5+leansmt-compiler \
    --jobs "$jobs" --timeout "$timeout" --memout "$memout" \
    --output_dir "$OUTPUT_DIR"
  python3 collect_leansmt_stats.py "$OUTPUT_DIR/cvc5+leansmt-compiler/SMT-LIB" "$DATA_DIR/SMT-LIB/cvc5+leansmt-compiler.csv"

  # cvc5+leansmt+compiler
  python3 run_benchmarks.py "$smt_file" cvc5+leansmt+compiler \
    --jobs "$jobs" --timeout "$timeout" --memout "$memout" \
    --output_dir "$OUTPUT_DIR"
  python3 collect_leansmt_stats.py "$OUTPUT_DIR/cvc5+leansmt+compiler/SMT-LIB" "$DATA_DIR/SMT-LIB/cvc5+leansmt+compiler.csv"

  # cvc5+ethos
  python3 run_benchmarks.py "$smt_file" cvc5+ethos \
    --jobs "$jobs" --timeout "$timeout" --memout "$memout" \
    --output_dir "$OUTPUT_DIR"
  python3 collect_ethos_stats.py "$OUTPUT_DIR/cvc5+ethos/SMT-LIB" "$DATA_DIR/SMT-LIB/cvc5+ethos.csv"

  # verit+smtcoq
  python3 run_benchmarks.py "$smt_file" verit+smtcoq \
    --jobs "$jobs" --timeout "$timeout" --memout "$memout" \
    --output_dir "$OUTPUT_DIR"
  python3 collect_smtcoq_stats.py "$OUTPUT_DIR/verit+smtcoq/SMT-LIB" "$DATA_DIR/SMT-LIB/verit+smtcoq.csv"

  # Summaries
  python3 tables.py "$DATA_DIR/SMT-LIB" "$TABLES_DIR/SMT-LIB.tex"
  python3 tables.py --benchmark_filter QF_ "$DATA_DIR/SMT-LIB" "$TABLES_DIR/QF_SMT-LIB.tex"
  python3 cactus.py "$DATA_DIR/SMT-LIB" "$FIGURES_DIR/SMT-LIB.pdf"
  python3 cactus.py --benchmark_filter QF_ "$DATA_DIR/SMT-LIB" "$FIGURES_DIR/SMT-LIB_QF.pdf"
  python3 scatter.py "$DATA_DIR/SMT-LIB/cvc5+leansmt-compiler.csv" "$DATA_DIR/SMT-LIB/cvc5+ethos.csv" "$FIGURES_DIR/scatter-compiler.pdf"
  python3 scatter.py "$DATA_DIR/SMT-LIB/cvc5+leansmt+compiler.csv" "$DATA_DIR/SMT-LIB/cvc5+ethos.csv" "$FIGURES_DIR/scatter+compiler.pdf"
}

###############################################################################
# Main Script Execution
###############################################################################
if [ -n "$MODE" ]; then
  echo "Mode: $MODE"
else
  echo "Number of benchmarks (N): $N"
fi
echo "Timeout: $TIMEOUT"
echo "Memout: $MEMOUT"
echo "Jobs: $JOBS"
echo "Sledgehammer: $SLEDGEHAMMER"

# Subdirectories for Seventeen
run_seventeen_benchmarks "$SEVENTEEN_SMT2_FILE" "$SEVENTEEN_FOF_FILE" "$JOBS" 60 8192 "$SLEDGEHAMMER"

# Subdirectories for SMT-LIB
run_smtlib_benchmarks "$SMTLIB_FILE" "$JOBS" "$TIMEOUT" "$MEMOUT"

echo "All benchmarks completed."
echo "Results stored in:"
echo "  $OUTPUT_DIR"
echo "  $DATA_DIR"
echo "  $FIGURES_DIR"
echo "  $TABLES_DIR"
