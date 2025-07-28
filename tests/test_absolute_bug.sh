#!/bin/bash

echo "=== Testing Absolute Path Bug Fix ==="
echo "Bug: jcd /datadrive2/un should match /datadrive2/unmemorize, not /datadrive2/lost+found"
echo

# Build the binary
echo "Building binary..."
cd /datadrive/jcd
cargo build --release 2>&1

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Build successful!"
echo

# Test the specific bug scenario
echo "Testing the reported bug scenario:"
echo "Pattern: '/datadrive2/un' (should match directories starting with 'un')"
echo

# Check what actually exists in /datadrive2
echo "Directories in /datadrive2 that contain 'un':"
ls -la /datadrive2/ 2>/dev/null | grep -i un || echo "No directories found"

echo
echo "Testing jcd binary with '/datadrive2/un':"
result=$(./target/release/jcd "/datadrive2/un" 0 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "First match: $result"

    # Check if it's a prefix match (starts with "un") or substring match (contains "un")
    basename_result=$(basename "$result")
    if [[ "$basename_result" =~ ^un ]]; then
        echo "✓ GOOD: Result starts with 'un' (prefix match)"
    elif [[ "$basename_result" =~ un ]]; then
        echo "⚠ ISSUE: Result contains 'un' but doesn't start with it (substring match)"
        echo "  This suggests lost+found is being matched instead of unmemorize"
    else
        echo "✗ ERROR: Result doesn't contain 'un' at all"
    fi
else
    echo "No match found"
fi

echo
echo "Getting all matches for '/datadrive2/un':"
for i in {0..5}; do
    result=$(./target/release/jcd "/datadrive2/un" $i 2>/dev/null)
    if [ $? -eq 0 ]; then
        basename_result=$(basename "$result")
        if [[ "$basename_result" =~ ^un ]]; then
            echo "  Match $i: $result ✓ (prefix)"
        elif [[ "$basename_result" =~ un ]]; then
            echo "  Match $i: $result ⚠ (substring)"
        else
            echo "  Match $i: $result ✗ (no match?)"
        fi
    else
        echo "  No more matches after index $((i-1))"
        break
    fi
done

echo
echo "=== Analysis ==="
echo "Prefix matches (directories starting with 'un') should come first"
echo "Substring matches (directories containing 'un') should come later"
echo "If lost+found appears before unmemorize, the prioritization is wrong"