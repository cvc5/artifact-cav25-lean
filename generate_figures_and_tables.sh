#!/bin/bash

usage() {
  echo "Generate tables and figures from existing benchmark data."
  echo ""
  echo "Usage:"
  echo "  $0 [-h|--help] <smoke|minimal|brief|all|count>"
  echo ""
  echo "Arguments:"
  echo "  <mode-or-count>   Either a named mode (e.g., smoke) or a numeric count (e.g. '500')."
  echo "                    The script will look for data in /home/user/artifact/data/<mode-or-count>."
  echo ""
  echo "Example:"
  echo "  $0 brief"
  echo "  $0 500"
  exit 1
}

# Check for help flag or insufficient args
if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ $# -lt 1 ]; then
  usage
fi

# The user provides one argument (e.g. 'brief' or '500'), which we use to locate the data.
DATA_ID="$1"
DATA_DIR="/home/user/artifact/data/${DATA_ID}"
FIGURES_DIR="/home/user/artifact/figures/${DATA_ID}"
TABLES_DIR="/home/user/artifact/tables/${DATA_ID}"

rm -rf "${FIGURES_DIR}" "${TABLES_DIR}"

mkdir -p "${FIGURES_DIR}" "${TABLES_DIR}"

# Generate figures
python3 cactus.py "${DATA_DIR}/seventeen" "${FIGURES_DIR}/seventeen.pdf"
python3 cactus.py "${DATA_DIR}/SMT-LIB" "${FIGURES_DIR}/SMT-LIB.pdf"
python3 cactus.py --benchmark_filter QF_ "${DATA_DIR}/SMT-LIB" "${FIGURES_DIR}/QF_SMT-LIB.pdf"
python3 scatter.py "${DATA_DIR}/SMT-LIB/cvc5+leansmt.csv" "${DATA_DIR}/SMT-LIB/cvc5+ethos.csv" "${FIGURES_DIR}/scatter.pdf"

# Generate tables
python3 tables.py "${DATA_DIR}/seventeen" "${TABLES_DIR}/seventeen.tex"
python3 tables.py "${DATA_DIR}/SMT-LIB" "${TABLES_DIR}/SMT-LIB.tex"
python3 tables.py --benchmark_filter QF_ "${DATA_DIR}/SMT-LIB" "${TABLES_DIR}/QF_SMT-LIB.tex"

echo "Finished generating figures & tables under:"
echo "  ${FIGURES_DIR}"
echo "  ${TABLES_DIR}"
