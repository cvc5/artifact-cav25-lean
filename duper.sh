#!/bin/bash

input_file="$1"

# Measure time for proof generation
start_time=$(date +%s%3N) # Start time in milliseconds
/home/user/artifact/duper/.lake/build/bin/duper $input_file
end_time=$(date +%s%3N)   # End time in milliseconds

# Calculate and print the elapsed time for generation
gen_time=$((end_time - start_time))
echo "[time] prove: $gen_time"
