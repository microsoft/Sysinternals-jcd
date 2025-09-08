#!/bin/bash

echo "=== Testing Absolute Path Bug Fix ==="
echo "Bug: jcd /some_drive/un should match /some_drive/unmemorize, not /some_drive/lost+found"
echo

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Build the binary
echo "Building binary..."
cd "$PROJECT_ROOT"
cargo build --release 2>&1

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Build successful!"
echo

# Test the specific bug scenario
echo "Testing the reported bug scenario:"
echo "Pattern: '/tmp/test_un/un' (should match directories starting with 'un')"
echo

# Create test directories for this test
TEST_DIR="/tmp/test_un"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"/{un,unmemorize,lost+found}

# Check what actually exists in test directory
echo "Directories in $TEST_DIR that contain 'un':"
ls -la "$TEST_DIR"/ 2>/dev/null | grep -i un || echo "No directories found"

echo
echo "Testing jcd binary with '$TEST_DIR/un':"
result=$(./target/release/jcd "$TEST_DIR/un" 0 2>/dev/null)
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
echo "Getting all matches for '$TEST_DIR/un':"
for i in {0..5}; do
    result=$(./target/release/jcd "$TEST_DIR/un" $i 2>/dev/null)
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