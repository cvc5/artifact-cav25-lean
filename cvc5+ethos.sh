#!/bin/bash

input_file="$1"

# Temporary file for the proof
proof_file=$(mktemp /tmp/ethos.proof.XXXXXX.cpc)

# Function to generate proof
generate_proof() {
    local input_file="$1"
    echo "(include \"/home/user/artifact/cvc5/proofs/eo/cpc/Cpc.eo\")"
    /home/user/artifact/cvc5/build/bin/cvc5 --enum-inst --cegqi-midpoint --produce-proofs --proof-elim-subtypes --dump-proofs --proof-format=cpc --proof-granularity=dsl-rewrite "$input_file" | tail -n +2
}

# Function to check proof
check_proof() {
    cat "$proof_file" | grep WARNING
    CHECK=$(cat "$proof_file" | grep "step\|assume")
    [ -z "$CHECK" ] && echo "; WARNING: Empty proof"
    /home/user/artifact/cvc5/deps/bin/ethos "$proof_file"
}

echo "=== Generate proof with cvc5"

# Measure time for proof generation
start_time=$(date +%s%3N) # Start time in milliseconds
generate_proof "$input_file" > "$proof_file"
end_time=$(date +%s%3N)   # End time in milliseconds

# Calculate and print the elapsed time for generation
gen_time=$((end_time - start_time))
echo "[time] solve: $gen_time"

echo "=== Check proof with ethos"

# Measure time for proof checking
start_time=$(date +%s%3N)
check_proof
end_time=$(date +%s%3N)

# Calculate and print the elapsed time for checking
check_time=$((end_time - start_time))
echo "[time] check: $check_time"
