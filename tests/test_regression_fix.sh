#!/bin/bash

echo "=== Testing Regression Fix for Immediate Match Prioritization ==="
echo "Regression: 'jcd /da' should return immediate matches (/datadrive, /datadrive2)"
echo "            without doing a deep search"
echo

# Build binary
echo "Building binary..."
cd /datadrive/jcd
cargo build --release

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo "Build successful!"
echo

# Test the regression scenario
echo "=== Test 1: Immediate matches should return quickly ==="
echo "Pattern: '/da' (should find /datadrive, /datadrive2 immediately)"
echo

echo "Checking what exists in root that starts with 'da':"
ls -d /da* 2>/dev/null || echo "No directories found starting with 'da' in root"

echo
echo "Testing timing for '/da' pattern (should be fast - immediate matches):"
time ./target/release/jcd "/da" 0 2>/dev/null
echo

echo "Getting all matches for '/da':"
for i in {0..3}; do
    result=$(./target/release/jcd "/da" $i 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "  Match $i: $result"
    else
        echo "  No more matches after index $((i-1))"
        break
    fi
done

echo

# Test that the original bug fix still works
echo "=== Test 2: Original bug fix still works ==="
echo "Pattern: '/datadrive2/un' (should prioritize prefix matches)"
echo

if [ -d "/datadrive2" ]; then
    echo "Directories in /datadrive2 containing 'un':"
    ls -la /datadrive2/ 2>/dev/null | grep -i un || echo "No directories found"

    echo
    echo "Testing '/datadrive2/un' (first match should start with 'un'):"
    result=$(./target/release/jcd "/datadrive2/un" 0 2>/dev/null)
    if [ $? -eq 0 ]; then
        basename_result=$(basename "$result")
        if [[ "$basename_result" =~ ^un ]]; then
            echo "✓ GOOD: First match starts with 'un': $result"
        else
            echo "✗ BAD: First match doesn't start with 'un': $result"
        fi
    else
        echo "No matches found"
    fi
else
    echo "Skipping - /datadrive2 doesn't exist"
fi

echo

# Test that relative paths still work
echo "=== Test 3: Relative paths still work ==="
echo "Testing that relative path functionality wasn't broken"

# Create test structure
mkdir -p /tmp/jcd_regression_test/{immediate1,immediate2,deep/nested}
cd /tmp/jcd_regression_test

echo "Testing relative pattern 'imm' (should find immediate matches quickly):"
time ../datadrive/jcd/target/release/jcd "imm" 0 2>/dev/null
echo

echo "Testing relative pattern '../' navigation:"
cd deep
result=$(../datadrive/jcd/target/release/jcd ".." 2>/dev/null)
if [[ "$result" == "/tmp/jcd_regression_test" ]]; then
    echo "✓ GOOD: Relative navigation works: $result"
else
    echo "✗ BAD: Relative navigation broken: $result"
fi

# Cleanup
rm -rf /tmp/jcd_regression_test

echo
echo "=== Summary ==="
echo "1. Immediate matches for absolute paths should be fast (no deep search)"
echo "2. Prefix prioritization for absolute paths should still work"
echo "3. Relative path functionality should be unchanged"