"""Implementation of julia_binary rule."""

load("@bazel_skylib//lib:shell.bzl", "shell")
load("//julia/private:providers.bzl", "JuliaInfo")

def _julia_binary_impl(ctx):
    """Implementation of julia_binary rule."""
    julia_toolchain = ctx.toolchains["@rules_julia//toolchain:toolchain_type"].julia_toolchain

    # Main source file
    main_file = ctx.file.main

    # Collect all source files (main + deps)
    srcs = [main_file]
    for dep in ctx.attr.deps:
        if JuliaInfo in dep:
            srcs.extend(dep[JuliaInfo].srcs.to_list())

    # Create executable wrapper script
    wrapper = ctx.actions.declare_file(ctx.label.name)

    # Build LOAD_PATH from dependencies
    load_paths = []
    for dep in ctx.attr.deps:
        if JuliaInfo in dep:
            for src in dep[JuliaInfo].srcs.to_list():
                load_paths.append(src.dirname)

    # Make load paths unique
    load_paths = {p: None for p in load_paths}.keys()
    load_path_str = ":".join(load_paths)

    # Create wrapper script
    ctx.actions.write(
        output = wrapper,
        content = """#!/bin/bash
set -euo pipefail

# Set Julia load path to include dependencies
export JULIA_LOAD_PATH={load_path}:@:@stdlib

# Run Julia with the main file
exec {julia_bin} {main_file} "$@"
""".format(
            julia_bin = shell.quote(julia_toolchain.julia_bin.short_path),
            main_file = shell.quote(main_file.short_path),
            load_path = shell.quote(load_path_str),
        ),
        is_executable = True,
    )

    # Collect runtime files
    runfiles = ctx.runfiles(files = srcs + [julia_toolchain.julia_bin])

    # Add dependency runfiles
    for dep in ctx.attr.deps:
        if JuliaInfo in dep:
            runfiles = runfiles.merge(dep[JuliaInfo].runfiles)

    # Add toolchain runtime files for hermetic builds
    if julia_toolchain.runtime_files:
        runfiles = runfiles.merge(
            ctx.runfiles(transitive_files = julia_toolchain.runtime_files),
        )

    return [
        DefaultInfo(
            executable = wrapper,
            runfiles = runfiles,
        ),
        JuliaInfo(
            srcs = depset([main_file]),
            runfiles = runfiles,
        ),
    ]

julia_binary = rule(
    implementation = _julia_binary_impl,
    attrs = {
        "deps": attr.label_list(
            providers = [JuliaInfo],
            doc = "Julia library dependencies.",
        ),
        "main": attr.label(
            allow_single_file = [".jl"],
            mandatory = True,
            doc = "The main Julia source file to execute.",
        ),
    },
    executable = True,
    toolchains = ["@rules_julia//toolchain:toolchain_type"],
    doc = """Builds an executable Julia program.

Example:
    julia_binary(
        name = "hello",
        main = "hello.jl",
        deps = [":mylib"],
    )
""",
)
