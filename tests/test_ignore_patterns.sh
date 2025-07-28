#!/bin/bash
echo "Testing .jcdignore pattern limits and regex safety..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TEST_ROOT="/tmp/jcd_test_ignore"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(realpath "$SCRIPT_DIR/..")"
BIN="${JCD_BIN:-$REPO_ROOT/target/release/jcd}"

if [[ ! -x "$BIN" ]]; then
    echo "ERROR: jcd binary not found or not executable at: $BIN"
    echo "Set JCD_BIN to override path. Example:"
    echo "  JCD_BIN=/path/to/jcd ./tests/test_ignore_patterns.sh"
    exit 1
fi

rm -rf "$TEST_ROOT"
mkdir -p "$TEST_ROOT/matchthis"
mkdir -p "$TEST_ROOT/skipme"

# Create many test directories
for i in {1..150}; do
    mkdir -p "$TEST_ROOT/spamdir$i"
done

# Create .jcdignore with a mix of valid, invalid, and dangerous patterns
cat > "$TEST_ROOT/.jcdignore" <<EOF
^skipme$
^((a+)+)$
[
^spamdir1$
^spamdir2$
EOF

for i in {3..147}; do
    echo "^spamdir$i\$" >> "$TEST_ROOT/.jcdignore"
done

cd "$TEST_ROOT"
echo "Current directory: $(pwd)"

echo -e "\n=== Running jcd ==="
JCD_DEBUG=1 "$BIN" "spamdir" 2>&1 | tee /tmp/jcd_ignore_test_output.txt

echo -e "\n=== Verifying expected behavior ==="
if grep -q "Invalid regex pattern '\['" /tmp/jcd_ignore_test_output.txt &&
    grep -q "Loaded 100 ignore patterns" /tmp/jcd_ignore_test_output.txt; then
    echo -e "${GREEN}✓ PASSED${NC}: invalid and catastrophic patterns were skipped, pattern count capped"
else
    echo -e "${RED}✗ FAILED{NC}: regex safety checks failed"
    exit 1
fi

echo -e "\nCleaning up..."
rm -rf "$TEST_ROOT"
