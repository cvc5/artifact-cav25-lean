#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path/to/file.smt_in>"
    exit 1
fi

input_file="$1"

# Extract "VeriComp" from the grandparent directory of the file
module="$(basename "$(dirname "$(dirname "$input_file")")")"

# Extract the parent directory, e.g. "0002_Well_founded"
parent_dir="$(basename "$(dirname "$input_file")")"
# Remove the numeric prefix (e.g. "0002_"), leaving "Well_founded"
test_name="$(echo "$parent_dir" | sed 's/^[0-9]\+_//')"

# Get the file name without its extension, e.g. "prob_00087_002136__8477998"
filename_noext="$(basename "$input_file" .smt_in)"

# Remove "prob_" prefix and everything after "__"
# e.g. "prob_00087_002136__8477998" -> "00087_002136"
lines_part="$(echo "$filename_noext" | sed 's/^prob_//; s/__.*//')"

# Convert the underscore to a colon, e.g. "00087_002136" -> "00087:002136"
lines="$(echo "$lines_part" | tr '_' ':')"

# Final combined test_with_lines, e.g. "Well_founded[00087:002136]"
test_with_lines="${test_name}[${lines}]"

echo "module: $module"
echo "test_with_lines: $test_with_lines"

# Create the target directory and cd into it
# Strip the leading "/home/user/artifact/benchmarks/" portion
relative_path="${input_file#/home/user/artifact/benchmarks/}"

output_dir="/home/user/artifact/output/verit+sledgehammer/$relative_path"

mkdir -p "$output_dir"
cd "$output_dir"

# Run the Isabelle command (example usage)
isabelle mirabelle \
  -d '$AFP' \
  -m 1 \
  -t 1200 \
  -A "sledgehammer[provers=verit,fact_filter=mepo,minimize=false,max_facts=512,induction_rules=exclude,uncurried_aliases=false,lam_trans=lifting,max_mono_iters=3,max_new_mono_instances=100,timeout=1200,preplay_timeout=1200,check_trivial=true,keep_probs=true,keep_proofs=true,isar_proofs=false,try0=false,slice=false,proof_method=smt]" \
  -T "$test_with_lines" \
  "$module"
