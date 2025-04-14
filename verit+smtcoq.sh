#!/bin/bash

input_file="$1"

# Temporary file for the proof
proof_file=$(mktemp /tmp/proof.XXXXXX.vtlog)

echo "Running veriT and producing proof"

# Measure time for running veriT
start_time=$(date +%s%3N)
/home/user/artifact/veriT9f48a98/veriT --proof-prune --proof-merge --proof-with-sharing --cnf-definitional --disable-ackermann --proof=$proof_file $input_file
end_time=$(date +%s%3N)

# Calculate and print the elapsed time for veriT
verit_time=$((end_time - start_time))
echo "[time] solve: $verit_time"

echo "Running smtcoq with proof"

# Measure time for running smtcoq
start_time=$(date +%s%3N)
/home/user/artifact/smtcoq/src/extraction/smtcoq -verit $input_file $proof_file
end_time=$(date +%s%3N)

# Calculate and print the elapsed time for smtcoq
smtcoq_time=$((end_time - start_time))
echo "[time] check: $smtcoq_time"
