# Development
## Project Structure

```
jcd/
├── src/
│   └── main.rs                  # Core Rust implementation with relative path support
├── .github/
│   └── copilot-instructions.md  # Copilot custom instructions
├── .vscode/
│   └── tasks.json               # VS Code build tasks
├── jcd_function.sh              # Enhanced bash wrapper with animations (ESSENTIAL)
├── Cargo.toml                   # Rust dependencies and metadata
├── Cargo.lock                   # Dependency lock file
├── tests/                       # Test scripts
└── README.md                    # This file
```

## Build
1. **Clone and Build**:
   ```bash
   git clone https://github.com/microsoft/jcd.git
   cd jcd
   cargo build --release
   ```

2. **Add to Shell Configuration**:
   Add the following lines to your `~/.bashrc` or `~/.zshrc` (replace `/path/to/jcd` with your actual path):
   ```bash
   export JCD_BINARY="/path/to/jcd/target/release/jcd"
   source /path/to/jcd/jcd_function.sh
   ```

3. **Reload Shell**:
   ```bash
   source ~/.bashrc
   ```
4. **Build Packages**:

   Set the VERSION environment variable to the version of jcd.

   Debian:
   ```
   ./makePackages.sh . target/release jcd $(VERSION) 0 deb "$(dpkg --print-architecture)"
   ```

   RPM:
   ```
   ./makePackages.sh "$(pwd)" target/release jcd $(VERSION) 0 rpm "$(rpm --eval '%_arch')"
   ```

> **Note**: The shell function integration is **required** because a Rust binary cannot change the directory of its parent shell process. The `jcd_function.sh` wrapper handles this limitation by calling the binary and then changing directories based on its output.

## Test
The project includes a comprehensive test suite located in the `tests/` directory:

```bash
# Run all tests (recommended)
./tests/run_all_tests.sh

# Individual test suites:
# Run comprehensive test suite
./tests/test_relative_comprehensive.sh

# Test ignore functionality
./tests/test_ignore_functionality.sh

# Quick validation for CI/CD
./tests/validate_jcd.sh

# Validate Shift+Tab functionality
./tests/validate_shift_tab.sh

# Simple functionality test
./tests/simple_test.sh

# Quick regression test
./tests/quick_regression_test.sh

# Specific bug fix tests
./tests/test_absolute_bug.sh
./tests/test_absolute_path_consistency.sh
./tests/test_regression_fix.sh
./tests/final_absolute_path_test.sh

# Python-based basic functionality verification
./tests/verify_basic_functionality.py
```

### Manual Testing
You can also test manually:
```bash
# Build the project
cargo build --release

# Test basic navigation
cd /tmp
jcd ..

# Test relative paths
jcd ../Documents
jcd ../../usr/local

# Test pattern matching
jcd ../proj   # Should match project directories in parent
```

See `tests/README.md` for detailed information about the test suite.

## How It Works
The `jcd` tool works in two parts:

1. **Rust Binary (`src/main.rs`)**:
   - Performs the directory search and sorting
   - Returns **all matching directories** when given different index parameters
   - Supports cycling through multiple matches via index parameter
   - Cannot change the parent shell's directory (fundamental limitation)

2. **Shell Function (`jcd_function.sh`)**:
   - Wraps the Rust binary and handles directory changing
   - Provides intelligent tab completion with animated visual feedback
   - Manages completion state to enable smooth cycling experience
   - Handles fast shell-based navigation for common relative patterns
   - Changes to the selected directory using the shell's `cd` command
   - Shows animated loading indicators during search operations

### Search Process

1. **Ignore Pattern Loading**: Loads ignore patterns from configuration files (unless `-x` flag is used)
2. **Relative Path Resolution**: Handles `..`, `../..`, `../pattern` etc. before search
3. **Search Up**: Looks through parent directories for matches (applying ignore patterns)
4. **Search Down**: Recursively searches subdirectories (up to 8 levels deep, skipping ignored directories)
5. **Comprehensive Collection**: Gathers **all** matching directories (not just the first one)
6. **Smart Sorting**:
   - Prioritizes match quality (exact vs partial)
   - Sorts by proximity within each quality category
   - Maintains consistent ordering for reliable tab completion
7. **Shell Integration**: Uses a bash wrapper function with sophisticated tab completion cycling
8. **Visual Feedback**: Provides animated loading indicators for longer operations

## Technical Details

_JCD was vibe coded by Mark Russinovich, Mario Hewardt with Github Copilot Agent and Claude Sonnet 4._

- **Language**: Rust for performance and reliability
- **Dependencies**: `regex` crate for ignore pattern matching
- **Architecture**: Rust binary + enhanced bash wrapper function
- **Search Depth**: Limited to 8 levels deep for performance
- **Shell Support**: Bash (with bidirectional tab completion cycling and animations)
- **Case Sensitivity**: Configurable with `-i` flag (default: case-sensitive)
- **Directory Filtering**: Regex-based ignore patterns with multiple configuration sources
- **Configuration**: XDG Base Directory compliant with legacy support
- **Tab Navigation**: Forward (Tab) and backward (Shift+Tab) cycling through matches
- **Visual Feedback**: Animated loading indicators using ANSI escape sequences
- **Performance**: Shell-based fast paths for common navigation patterns
- **Relative Path Support**: Full resolution and search from resolved directories

