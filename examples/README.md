# Julia Bazel Examples

This directory contains working examples demonstrating the Julia rules for Bazel.

## Examples

### 1. Hello World (`hello_world/`)

The simplest possible Julia program.

```bash
bazel run //examples/hello_world:hello
```

Output:
```
Hello from Julia 1.11.7!
Running on x86_64-linux-gnu
```

### 2. Library (`library/`)

Demonstrates `julia_library` for code reuse and `julia_test` for testing.

**Run the calculator:**
```bash
bazel run //examples/library:calculator
```

**Run tests:**
```bash
bazel test //examples/library:mathlib_test
```

**What it shows:**
- Creating reusable Julia modules with `julia_library`
- Using libraries as dependencies in binaries
- Writing tests with Julia's Test framework
- Organizing code into modules

## Running Examples

From the repository root:

```bash
# Run all examples
bazel run //examples/hello_world:hello
bazel run //examples/library:calculator

# Run all tests
bazel test //examples/...

# Run specific test
bazel test //examples/library:mathlib_test --test_output=all
```

## Building for Different Platforms

Use the platform definitions:

```bash
# Build for Linux x86_64
bazel build //examples/hello_world:hello --platforms=//platforms:linux_x86_64

# Build for macOS ARM64
bazel build //examples/hello_world:hello --platforms=//platforms:macos_aarch64
```

## Next Steps

See the main README.md for:
- Setting up the toolchain in your project
- Creating your own Julia rules
- Advanced features

