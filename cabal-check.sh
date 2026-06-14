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

if [ "$status" -ne 0 ] || grep -q '^Warning:' <<<"$output"; then
    printf '%s\n' "$output"
    exit 1
fi
