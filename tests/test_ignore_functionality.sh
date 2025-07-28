#!/bin/bash

# Comprehensive test for JCD ignore functionality
# Tests the new ignore file features with various patterns and configurations

echo "=== JCD Ignore Functionality Test ==="
echo "Testing ignore file patterns and configurations"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test result counters
PASSED=0
FAILED=0

# Get the absolute path to the JCD binary
JCD_BIN="$(pwd)/target/debug/jcd"

# Ensure JCD is built
if [ ! -f "$JCD_BIN" ]; then
    echo -e "${RED}Error: JCD binary not found. Building...${NC}"
    cargo build || exit 1
fi

# Create test directory structure
TEST_DIR="/tmp/jcd_ignore_test_$$"
echo -e "${BLUE}Creating test directory structure in: $TEST_DIR${NC}"

cleanup() {
    echo -e "\n${BLUE}Cleaning up test directory...${NC}"
    rm -rf "$TEST_DIR"
    # Clean up any ignore files we created
    rm -f ~/.jcdignore
    rm -rf ~/.config/jcd
    rm -rf /tmp/jcd_test_config
}

# Set cleanup trap
trap cleanup EXIT

# Create test directory structure
mkdir -p "$TEST_DIR"/{project/{src,target,node_modules,build,.git},home/{Documents,Downloads},system/{cache,temp,logs}}
mkdir -p "$TEST_DIR"/project/target/{debug,release}
mkdir -p "$TEST_DIR"/project/node_modules/{react,lodash}
mkdir -p "$TEST_DIR"/project/.git/{objects,refs}
mkdir -p "$TEST_DIR"/home/Documents/{work,personal}
mkdir -p "$TEST_DIR"/system/{cache/browser,temp/app,logs/system}

# Test function
test_jcd() {
    local description="$1"
    local command="$2"
    local expected_result="$3"  # "should_find" or "should_not_find"
    local search_pattern="$4"
    local start_dir="$5"

    echo -e "\n${YELLOW}Test:${NC} $description"
    echo "Command: $command"
    echo "Start dir: $start_dir"
    echo "Expected: $expected_result '$search_pattern'"

    cd "$start_dir" || { echo "Failed to cd to $start_dir"; return 1; }
    
    # Execute the command and capture output
    local output
    output=$($command 2>&1)
    local exit_code=$?

    echo "Output: $output"
    echo "Exit code: $exit_code"

    local found=false
    if echo "$output" | grep -q "$search_pattern"; then
        found=true
    fi

    local test_passed=false
    if [[ "$expected_result" == "should_find" && "$found" == true ]]; then
        test_passed=true
    elif [[ "$expected_result" == "should_not_find" && "$found" == false ]]; then
        test_passed=true
    fi

    if $test_passed; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "  Expected to $expected_result '$search_pattern' but result was opposite"
        ((FAILED++))
    fi
}

echo -e "\n${BLUE}=== Test 1: No ignore files (baseline) ===${NC}"
cd "$TEST_DIR/project"
test_jcd "Find target directory (no ignore)" \
    "$JCD_BIN target" \
    "should_find" \
    "target" \
    "$TEST_DIR/project"

test_jcd "Find node_modules directory (no ignore)" \
    "$JCD_BIN node" \
    "should_find" \
    "node_modules" \
    "$TEST_DIR/project"

echo -e "\n${BLUE}=== Test 2: Project-local .jcdignore ===${NC}"
# Create project-local ignore file
cat > "$TEST_DIR/project/.jcdignore" << 'EOF'
# Common build directories
target
node_modules
# Cache directories
\.cache
# Build artifacts
build
dist
EOF

cd "$TEST_DIR/project"
test_jcd "Target should be ignored with .jcdignore" \
    "$JCD_BIN target" \
    "should_not_find" \
    "target" \
    "$TEST_DIR/project"

test_jcd "Node_modules should be ignored with .jcdignore" \
    "$JCD_BIN node" \
    "should_not_find" \
    "node_modules" \
    "$TEST_DIR/project"

test_jcd "Src should still be found (not ignored)" \
    "$JCD_BIN src" \
    "should_find" \
    "src" \
    "$TEST_DIR/project"

echo -e "\n${BLUE}=== Test 3: Bypass ignore with -x flag ===${NC}"
test_jcd "Target found with -x flag (bypass ignore)" \
    "$JCD_BIN -x target" \
    "should_find" \
    "target" \
    "$TEST_DIR/project"

test_jcd "Node_modules found with -x flag (bypass ignore)" \
    "$JCD_BIN -x node" \
    "should_find" \
    "node_modules" \
    "$TEST_DIR/project"

echo -e "\n${BLUE}=== Test 4: User config ignore file ===${NC}"
# Remove project-local ignore
rm -f "$TEST_DIR/project/.jcdignore"

# Create user config directory and ignore file
mkdir -p "$HOME/.config/jcd"
cat > "$HOME/.config/jcd/ignore" << 'EOF'
# User-specific ignores
temp
cache
\.git
logs
EOF

cd "$TEST_DIR"
test_jcd "Cache directory should be ignored (user config)" \
    "$JCD_BIN cache" \
    "should_not_find" \
    "cache" \
    "$TEST_DIR"

test_jcd "Git directory should be ignored (user config)" \
    "$JCD_BIN git" \
    "should_not_find" \
    ".git" \
    "$TEST_DIR/project"

test_jcd "Temp directory should be ignored (user config)" \
    "$JCD_BIN temp" \
    "should_not_find" \
    "temp" \
    "$TEST_DIR"

test_jcd "Documents should still be found (not in user ignore)" \
    "$JCD_BIN Documents" \
    "should_find" \
    "Documents" \
    "$TEST_DIR"

echo -e "\n${BLUE}=== Test 5: Legacy ~/.jcdignore file ===${NC}"
# Remove user config ignore
rm -rf "$HOME/.config/jcd"

# Create legacy ignore file
cat > "$HOME/.jcdignore" << 'EOF'
# Legacy ignore patterns
Downloads
build
EOF

cd "$TEST_DIR"
test_jcd "Downloads should be ignored (legacy config)" \
    "$JCD_BIN Downloads" \
    "should_not_find" \
    "Downloads" \
    "$TEST_DIR"

test_jcd "Build should be ignored (legacy config)" \
    "$JCD_BIN build" \
    "should_not_find" \
    "build" \
    "$TEST_DIR/project"

test_jcd "Documents should still be found (not in legacy ignore)" \
    "$JCD_BIN Documents" \
    "should_find" \
    "Documents" \
    "$TEST_DIR"

echo -e "\n${BLUE}=== Test 6: Multiple ignore files (precedence) ===${NC}"
# Create both project-local and user config
cat > "$TEST_DIR/project/.jcdignore" << 'EOF'
# Project overrides user config
target
node_modules
EOF

mkdir -p "$HOME/.config/jcd"
cat > "$HOME/.config/jcd/ignore" << 'EOF'
# User config - should be overridden by project
src
cache
EOF

cd "$TEST_DIR/project"
test_jcd "Target ignored by project config (precedence test)" \
    "$JCD_BIN target" \
    "should_not_find" \
    "target" \
    "$TEST_DIR/project"

test_jcd "Src NOT ignored (project config takes precedence)" \
    "$JCD_BIN src" \
    "should_find" \
    "src" \
    "$TEST_DIR/project"

echo -e "\n${BLUE}=== Test 7: Invalid regex patterns ===${NC}"
# Create ignore file with invalid regex
cat > "$TEST_DIR/project/.jcdignore" << 'EOF'
# Valid pattern
target
# Invalid regex pattern (unclosed bracket)
[invalid
# Another valid pattern
node_modules
EOF

cd "$TEST_DIR/project"
test_jcd "Valid patterns still work despite invalid regex" \
    "$JCD_BIN target" \
    "should_not_find" \
    "target" \
    "$TEST_DIR/project"

test_jcd "Node_modules still ignored despite invalid regex" \
    "$JCD_BIN node" \
    "should_not_find" \
    "node_modules" \
    "$TEST_DIR/project"

echo -e "\n${BLUE}=== Test 8: Complex regex patterns ===${NC}"
cat > "$TEST_DIR/project/.jcdignore" << 'EOF'
# Complex regex patterns
.*\.git.*
target|build|dist
node_modules.*
cache\d*
temp.*
EOF

cd "$TEST_DIR/project"
test_jcd "Git directory ignored by regex pattern" \
    "$JCD_BIN git" \
    "should_not_find" \
    ".git" \
    "$TEST_DIR/project"

test_jcd "Target ignored by alternation pattern" \
    "$JCD_BIN target" \
    "should_not_find" \
    "target" \
    "$TEST_DIR/project"

echo -e "\n${BLUE}=== Test 9: Case sensitivity in patterns ===${NC}"
mkdir -p "$TEST_DIR/project"/{Target,NODE_MODULES}

cat > "$TEST_DIR/project/.jcdignore" << 'EOF'
# Case sensitive patterns
target
node_modules
EOF

cd "$TEST_DIR/project"
test_jcd "Lowercase target ignored" \
    "$JCD_BIN target" \
    "should_not_find" \
    "target" \
    "$TEST_DIR/project"

# Note: This test depends on how jcd handles case sensitivity in search vs ignore
test_jcd "Uppercase Target should be found (case sensitive ignore)" \
    "$JCD_BIN Target" \
    "should_find" \
    "Target" \
    "$TEST_DIR/project"

echo -e "\n${BLUE}=== Test 10: Empty and comment-only ignore files ===${NC}"
cat > "$TEST_DIR/project/.jcdignore" << 'EOF'
# This file only has comments

# Another comment
   # Indented comment

EOF

cd "$TEST_DIR/project"
test_jcd "All directories found with comment-only ignore file" \
    "$JCD_BIN target" \
    "should_find" \
    "target" \
    "$TEST_DIR/project"

# Summary
echo -e "\n${BLUE}=== Test Results Summary ===${NC}"
echo -e "Tests passed: ${GREEN}$PASSED${NC}"
echo -e "Tests failed: ${RED}$FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All ignore functionality tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed. Please review the output above.${NC}"
    exit 1
fi
