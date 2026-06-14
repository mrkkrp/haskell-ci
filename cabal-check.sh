#!/usr/bin/env bash
set -euo pipefail

if output="$(
    cabal check \
        --ignore=missing-upper-bounds \
        --ignore=option-o2 \
        2>&1
)"; then
    status=0
else
    status=$?
fi

# Always print the output
printf '%s\n' "$output"

# Exit with error if there were errors or warnings
if [ "$status" -ne 0 ] || grep -q '^Warning:' <<<"$output"; then
    exit 1
fi
