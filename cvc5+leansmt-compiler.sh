#!/bin/bash

input_file="$1"

LEAN_SYSROOT=/home/user/.elan/toolchains/leanprover--lean4---v4.20.0-rc5 LEAN_PATH=/home/user/artifact/lean-cpc-checker/.lake/build/lib/lean:/home/user/.elan/toolchains/leanprover--lean4---v4.20.0-rc5/lib/lean /home/user/artifact/lean-cpc-checker/.lake/build/bin/checker false $input_file
