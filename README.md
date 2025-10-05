# rules_julia

Bazel rules for Julia. Supports hermetic and system Julia installations.

## Setup

### MODULE.bazel (Bazel 7+)

```starlark
bazel_dep(name = "rules_julia", version = "0.1.0")
```

Toolchains are registered automatically. To customize, see Configuration section.

### WORKSPACE (legacy)

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_julia",
    # urls = ["https://github.com/tuckerbabcock/rules_julia/archive/v0.1.0.tar.gz"],
    # sha256 = "...",
)

load("@rules_julia//toolchain:defs.bzl", "julia_register_toolchains")
julia_register_toolchains(hermetic = True)
```

## Configuration

### Hermetic (downloads Julia)

```starlark
load("@rules_julia//toolchain:defs.bzl", "julia_register_toolchains")

julia_register_toolchains(hermetic = True)  # 1.11.7 (stable)
julia_register_toolchains(hermetic = True, version = "1.10.10")  # LTS
```

Supports: Linux x86_64/aarch64, macOS x86_64/aarch64

### Non-Hermetic (uses system Julia)

```starlark
julia_register_toolchains()  # Auto-detect from PATH
julia_register_toolchains(julia_path = "/custom/path/to/julia")
```

### Custom Julia version

```starlark
julia_register_toolchains(
    hermetic = True,
    version = "1.12.0",
    custom_urls = {"linux_x86_64": "https://..."},
    custom_sha256 = {"linux_x86_64": "..."},
)
```

## Rules

```starlark
load("@rules_julia//julia:defs.bzl", "julia_binary", "julia_library", "julia_test")

julia_binary(
    name = "hello",
    main = "hello.jl",
    deps = [":mylib"],
)

julia_library(
    name = "mylib",
    srcs = ["mylib.jl"],
    deps = [],
)

julia_test(
    name = "mylib_test",
    main = "test.jl",
    deps = [":mylib"],
)
```

Run with: `bazel run //:hello`, `bazel test //:mylib_test`

See [examples/](examples/) for complete examples.

## Custom Rules

Access the toolchain in your own rules:

```starlark
def _my_rule_impl(ctx):
    julia_toolchain = ctx.toolchains["@rules_julia//toolchain:toolchain_type"].julia_toolchain
    ctx.actions.run(
        executable = julia_toolchain.julia_bin,
        arguments = ["-e", "println(\"Hello\")"],
    )

my_rule = rule(
    implementation = _my_rule_impl,
    toolchains = ["@rules_julia//toolchain:toolchain_type"],
)
```

Toolchain provides: `julia_bin`, `julia_home`, `julia_version`, `runtime_files`
