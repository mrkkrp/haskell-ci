#!/usr/bin/env bash
set -euo pipefail

# Script to run cabal check and optionally verify tested-with field
# Usage: ./cabal-check.sh [ghc-versions-json]
# Example: ./cabal-check.sh '["9.10.3", "9.12.4", "9.14.1"]'

# Check if ghc-versions parameter was provided for tested-with validation
if [ $# -eq 1 ] && [ -n "$1" ]; then
    GHC_VERSIONS_JSON="$1"

    # Convert JSON array to space-separated list and sort it
    # Parse JSON array without jq - handle formats like ["9.10.3", "9.12.4", "9.14.1"]
    EXPECTED_VERSIONS=$(echo "$GHC_VERSIONS_JSON" | \
        sed 's/\[//g; s/\]//g; s/"//g; s/,/ /g' | \
        tr -s ' ' '\n' | \
        grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | \
        sort -V | \
        tr '\n' ' ' | \
        sed 's/ $//')

    if [ -z "$EXPECTED_VERSIONS" ]; then
        echo "Error: Could not parse GHC versions from JSON: $GHC_VERSIONS_JSON"
        exit 1
    fi

    echo "Checking tested-with field against CI configuration..."
    echo "Expected GHC versions: $EXPECTED_VERSIONS"

    # Find cabal file in current directory
    CABAL_FILES=$(find . -maxdepth 1 -name "*.cabal" -type f)

    if [ -z "$CABAL_FILES" ]; then
        echo "Error: No cabal file found in current directory"
        exit 1
    fi

    # Process each cabal file (usually just one)
    for CABAL_FILE in $CABAL_FILES; do
        echo "Checking: $CABAL_FILE"

        # Extract tested-with field (handle multi-line tested-with fields)
        TESTED_WITH=$(awk '
            /^[Tt]ested-with:/ {
                found = 1
                print $0
            }
            found && /^[[:space:]]/ {
                print $0
            }
            found && /^[^[:space:]]/ && !/^[Tt]ested-with:/ {
                exit
            }
        ' "$CABAL_FILE" | tr '\n' ' ')

        if [ -z "$TESTED_WITH" ]; then
            echo "Error: No 'tested-with' field found in $CABAL_FILE"
            echo "Please add a 'tested-with' field with the following GHC versions:"
            echo "tested-with: $(echo "$EXPECTED_VERSIONS" | sed 's/\([^ ]*\)/GHC==\1/g' | sed 's/ /, /g')"
            exit 1
        fi

        # Extract GHC versions from tested-with field
        # Handle various formats: GHC==x.y.z, GHC == x.y.z, ghc>=x.y.z, etc. (case-insensitive)
        ACTUAL_VERSIONS=$(echo "$TESTED_WITH" | grep -oiE 'GHC[[:space:]]*[=><!]+[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+' | \
                          sed -E 's/[Gg][Hh][Cc][[:space:]]*[=><!]+[[:space:]]*//' | sort -V | tr '\n' ' ' | sed 's/ $//')

        if [ -z "$ACTUAL_VERSIONS" ]; then
            echo "Error: Could not parse GHC versions from tested-with field"
            echo "Expected format: tested-with: GHC==9.10.3, GHC==9.12.4, GHC==9.14.1"
            exit 1
        fi

        # Compare the versions
        if [ "$EXPECTED_VERSIONS" = "$ACTUAL_VERSIONS" ]; then
            echo "✓ tested-with field matches CI configuration"
        else
            echo "✗ Error: tested-with field does not match CI configuration"
            echo "  Expected: $EXPECTED_VERSIONS"
            echo "  Actual:   $ACTUAL_VERSIONS"
            echo ""
            echo "To fix this, update the tested-with field in $CABAL_FILE to:"
            echo "tested-with: $(echo "$EXPECTED_VERSIONS" | sed 's/\([^ ]*\)/GHC==\1/g' | sed 's/ /, /g')"
            exit 1
        fi
    done

    echo ""
fi

# Run cabal check
echo "Running cabal check..."

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

echo "✓ cabal check passed"