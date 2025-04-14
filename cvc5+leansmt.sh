#!/bin/bash

input_file="$1"

LEAN_SYSROOT=/home/user/.elan/toolchains/leanprover--lean4---v4.15.0 LEAN_PATH=/home/user/artifact/lean-cpc-checker/.lake/build/lib:/home/user/.elan/toolchains/leanprover--lean4---v4.15.0/lib/lean /home/user/artifact/lean-cpc-checker/.lake/build/bin/checker $input_file
