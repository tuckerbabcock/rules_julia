"""Implementation of julia_library rule."""

load("//julia/private:providers.bzl", "JuliaInfo")

def _julia_library_impl(ctx):
    """Implementation of julia_library rule."""

    # Collect all source files
    srcs = ctx.files.srcs

    # Collect transitive sources from dependencies
    transitive_srcs = [depset(srcs)]
    for dep in ctx.attr.deps:
        if JuliaInfo in dep:
            transitive_srcs.append(dep[JuliaInfo].srcs)

    # Collect runfiles
    runfiles = ctx.runfiles(files = srcs)
    for dep in ctx.attr.deps:
        if JuliaInfo in dep:
            runfiles = runfiles.merge(dep[JuliaInfo].runfiles)

    return [
        DefaultInfo(
            files = depset(srcs),
            runfiles = runfiles,
        ),
        JuliaInfo(
            srcs = depset(transitive = transitive_srcs),
            runfiles = runfiles,
        ),
    ]

julia_library = rule(
    implementation = _julia_library_impl,
    attrs = {
        "deps": attr.label_list(
            providers = [JuliaInfo],
            doc = "Julia library dependencies.",
        ),
        "srcs": attr.label_list(
            allow_files = [".jl"],
            mandatory = True,
            doc = "Julia source files.",
        ),
    },
    doc = """Defines a Julia library.

A Julia library is a collection of Julia source files that can be used
as dependencies by julia_binary or other julia_library targets.

Example:
    julia_library(
        name = "mylib",
        srcs = ["lib.jl", "utils.jl"],
        deps = [":otherlib"],
    )
""",
)
