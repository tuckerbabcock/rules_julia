"""Implementation of julia_test rule."""

load("@bazel_skylib//lib:shell.bzl", "shell")
load("//julia/private:providers.bzl", "JuliaInfo")

def _julia_test_impl(ctx):
    """Implementation of julia_test rule."""
    julia_toolchain = ctx.toolchains["@rules_julia//toolchain:toolchain_type"].julia_toolchain

    # Main test file
    main_file = ctx.file.main

    # Collect all source files
    srcs = [main_file]
    for dep in ctx.attr.deps:
        if JuliaInfo in dep:
            srcs.extend(dep[JuliaInfo].srcs.to_list())

    # Create test wrapper script
    wrapper = ctx.actions.declare_file(ctx.label.name)

    # Build LOAD_PATH from dependencies
    load_paths = []
    for dep in ctx.attr.deps:
        if JuliaInfo in dep:
            for src in dep[JuliaInfo].srcs.to_list():
                load_paths.append(src.dirname)

    load_paths = {p: None for p in load_paths}.keys()
    load_path_str = ":".join(load_paths)

    # Create test wrapper
    ctx.actions.write(
        output = wrapper,
        content = """#!/bin/bash
set -euo pipefail

# Set Julia load path
export JULIA_LOAD_PATH={load_path}:@:@stdlib

# Run Julia test
exec {julia_bin} --color=yes {main_file} "$@"
""".format(
            julia_bin = shell.quote(julia_toolchain.julia_bin.short_path),
            main_file = shell.quote(main_file.short_path),
            load_path = shell.quote(load_path_str),
        ),
        is_executable = True,
    )

    # Collect runtime files
    runfiles = ctx.runfiles(files = srcs + [julia_toolchain.julia_bin])

    for dep in ctx.attr.deps:
        if JuliaInfo in dep:
            runfiles = runfiles.merge(dep[JuliaInfo].runfiles)

    # Add toolchain runtime files
    if julia_toolchain.runtime_files:
        runfiles = runfiles.merge(
            ctx.runfiles(transitive_files = julia_toolchain.runtime_files),
        )

    return [
        DefaultInfo(
            executable = wrapper,
            runfiles = runfiles,
        ),
    ]

julia_test = rule(
    implementation = _julia_test_impl,
    attrs = {
        "deps": attr.label_list(
            providers = [JuliaInfo],
            doc = "Julia library dependencies.",
        ),
        "main": attr.label(
            allow_single_file = [".jl"],
            mandatory = True,
            doc = "The main test file to execute.",
        ),
    },
    test = True,
    toolchains = ["@rules_julia//toolchain:toolchain_type"],
    doc = """Defines a Julia test.

Julia tests are executed with the Test stdlib available and should
use @test macros to define test cases.

Example:
    julia_test(
        name = "mylib_test",
        main = "mylib_test.jl",
        deps = [":mylib"],
    )
""",
)
