# JCD - Enhanced Directory Navigation Tool

`jcd` (Jump Change Directory) is a Rust-based command-line tool that provides enhanced directory navigation with substring matching and smart selection. It's like the `cd` command, but with superpowers!

![JCD Demo](https://github.com/markrussinovich/jcd/blob/main/assets/jcd.gif?raw=true)

## Features

- **Tab Navigation**: Intelligent cycling through all matches with visual feedback and animated loading indicators
- **Bidirectional Tab Cycling**: Tab cycles forward, Shift+Tab cycles backward through matches
- **Case Sensitivity Control**: Use `-i` flag for case-insensitive matching (default is case-sensitive)
- **Directory Ignore Support**: Skip unwanted directories using `.jcdignore` files with regex patterns
- **Flexible Ignore Configuration**: Support for project-local, user, and system-wide ignore files
- **First-Match Jump**: Press Enter after typing to immediately navigate to the best match
- **Priority Matching Order**:
  1. Exact matches prioritized over partial matches
  2. Up-tree matches (parent directories) have highest priority
  3. Down-tree matches (subdirectories) sorted by proximity
  4. Alphabetical sorting within same priority level
- **Substring Matching**: Find directories by partial name matches
- **Bidirectional Search**: Searches both up the directory tree and down into subdirectories

## Installation

1. **Clone and Build**:
   ```bash
   git clone <repository-url>
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
   ```
   cargo deb
   or
   cargo rpm
   ```

> **Note**: The shell function integration is **required** because a Rust binary cannot change the directory of its parent shell process. The `jcd_function.sh` wrapper handles this limitation by calling the binary and then changing directories based on its output.

## Usage

```bash
Usage:
  jcd [-i] [-x] <directory_pattern>   - Changes directory according to the pattern

Flags:
  -i                     - Case-insensitive matching (default: case-sensitive)
  -x                     - Bypass ignore patterns (search all directories)

directory_pattern:
  jcd <substring>        # Navigate to directory matching substring
  jcd <absolute_path>    # Navigate to absolute path
  jcd <path/pattern>     # Navigate using path-like patterns
```

### Examples

#### Basic Navigation
```bash
# Navigate to any directory containing "proj"
jcd proj

# Case-insensitive search for directories with "PROJ", "proj", "Proj", etc.
jcd -i proj

# Find directories with "src" in the name
jcd src

# Navigate to parent directories matching "work"
jcd work

# Navigate to absolute path
jcd /home/user/projects

# Use path patterns
jcd projects/src    # Find 'src' within 'projects'
```

#### Case Sensitivity Examples
```bash
# Default behavior is case-sensitive
jcd Test        # Matches: Test, TestDir  (but not test, TEST)
jcd test        # Matches: test, testdir  (but not Test, TEST)

# Use -i flag for case-insensitive matching
jcd -i test     # Matches: test, Test, TEST, TestDir, testdir, etc.
jcd -i proj     # Matches: proj, PROJ, Project, project, etc.

# Case-insensitive with tab completion
jcd -i test<Tab>         # Cycles through all matches regardless of case
jcd -i test<Shift+Tab>   # Cycles backward through matches
```

#### Ignore Patterns
```bash
# Skip common build/cache directories (honors .jcdignore files)
jcd target      # Skipped if "target" is in ignore patterns
jcd node        # Skipped if "node_modules" is in ignore patterns

# Use -x to bypass ignore patterns and search all directories
jcd -x target   # Finds target directory even if ignored
jcd -x node     # Finds node_modules even if ignored

# Combine flags
jcd -i -x test  # Case-insensitive search bypassing ignore patterns
```


### Advanced Tab Completion

When multiple directories match your search term, `jcd` provides intelligent tab completion that cycles through all available matches with visual feedback:

```bash
# Type 'jcd fo' and press Tab - shows animated dots while searching
$ jcd fo<Tab>
...  # Animated loading indicator
jcd /.font-unix

# Press Tab again to cycle forward to next match
$ jcd /.font-unix<Tab>
jcd /foo

# Press Shift+Tab to cycle backward to previous match
$ jcd /foo<Shift+Tab>
jcd /.font-unix

# Press Tab again to cycle forward
$ jcd /.font-unix<Tab>
jcd /some/other/folder

# Press Enter to navigate to the currently shown match
$ jcd /foo<Enter>
# Now in /foo directory
```

#### Tab Completion Features

- **Animated Loading**: Visual dots animation during search operations
- **Bidirectional Cycling**: Tab cycles forward, Shift+Tab cycles backward through matches
- **Inline Cycling**: Tab repeatedly to cycle through all matches in both directions
- **Smart Prioritization**: Exact matches shown before partial matches
- **Proximity Sorting**: Closer directories (fewer levels away) shown first
- **Trailing Slash Support**: Add `/` to explore subdirectories of the current match
- **Relative Path Support**: Full tab completion for `../`, `../../`, etc.
- **Case Sensitivity**: Works with both case-sensitive (default) and case-insensitive (`-i`) modes


## Directory Ignore Support

`jcd` supports ignoring unwanted directories using `.jcdignore` files with regex patterns. This helps skip common build directories, cache folders, and other directories you typically don't want to navigate to.

### Ignore File Locations

`jcd` searches for ignore files in the following order (first found takes precedence):

1. **Project-local**: `./.jcdignore` (in current directory)
2. **User config**: `~/.config/jcd/ignore` (follows XDG Base Directory Specification)
3. **Legacy user**: `~/.jcdignore` (for backward compatibility)
4. **System-wide**: `/etc/jcd/ignore` (affects all users)

### Ignore File Format

Ignore files contain regex patterns, one per line:

```bash
# .jcdignore example
# Common build directories
target
build
dist

# Cache and temporary directories
\.cache
\.tmp
temp.*

# Version control
\.git
\.svn

# Node.js
node_modules
npm-debug\.log

# Complex patterns using regex
.*\.egg-info
__pycache__
\.pytest_cache

# Python virtual environments
venv
\.venv
env
```

### Comment and Empty Line Support

- Lines starting with `#` are comments and ignored
- Empty lines are ignored
- Whitespace-only lines are ignored
- Invalid regex patterns are skipped (with silent error handling)

### Usage Examples

#### Basic Ignore Usage
```bash
# Create a project-local ignore file
echo "target" > .jcdignore
echo "node_modules" >> .jcdignore

# These directories will be skipped in searches
jcd target      # No results found (ignored)
jcd node        # No results found (ignored)

# Bypass ignore patterns with -x flag
jcd -x target   # Finds target directory
jcd -x node     # Finds node_modules directory
```

#### User-Wide Ignore Configuration
```bash
# Create user config directory
mkdir -p ~/.config/jcd

# Create user-wide ignore patterns
cat > ~/.config/jcd/ignore << 'EOF'
# User-wide ignores
\.git
\.svn
cache
temp
build
target
node_modules
__pycache__
\.pytest_cache
EOF

# These patterns now apply to all jcd searches
jcd cache       # Skipped everywhere
jcd build       # Skipped everywhere
```

#### Regex Pattern Examples
```bash
# Ignore all hidden directories (starting with .)
echo "\\..*" > .jcdignore

# Ignore specific patterns
echo "target|build|dist" > .jcdignore

# Ignore numbered cache directories
echo "cache\\d+" > .jcdignore

# Ignore temporary files and directories
echo "tmp.*|temp.*|\\.tmp" > .jcdignore
```

### Precedence Rules

When multiple ignore files exist:

1. **Project-local** `.jcdignore` has highest precedence
2. **User config** `~/.config/jcd/ignore`
3. **Legacy user** `~/.jcdignore`
4. **System-wide** `/etc/jcd/ignore` has lowest precedence

Only the first found file is used (no merging).

### Best Practices

1. **Use project-local ignore** for project-specific patterns
2. **Use user config** for personal preferences across all projects
3. **Use simple regex** for better performance and readability
4. **Comment your patterns** for future maintenance
5. **Test patterns** using the `-x` flag to verify they work as expected



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


## Development

### Building

```bash
# Debug build
cargo build

# Release build
cargo build --release

# Run tests
cargo test
```

### Project Structure

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

### Testing

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

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

```
