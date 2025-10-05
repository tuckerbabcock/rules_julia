"""Julia toolchain rule and provider definitions.

This module defines the core Julia toolchain infrastructure for Bazel.
The toolchain provides access to the Julia compiler/runtime and associated files.
"""

JuliaToolchainInfo = provider(
    doc = "Information about a Julia toolchain.",
    fields = {
        "julia_bin": "File: The Julia binary executable",
        "julia_home": "str: The Julia installation directory (BINDIR)",
        "julia_version": "str: The Julia version string",
        "runtime_files": "depset[File]: Files needed at runtime (hermetic builds only)",
    },
)

def _julia_toolchain_impl(ctx):
    """Implementation of the julia_toolchain rule."""
    toolchain_info = JuliaToolchainInfo(
        julia_bin = ctx.file.julia_bin,
        julia_home = ctx.attr.julia_home,
        julia_version = ctx.attr.julia_version,
        runtime_files = depset(ctx.files.runtime_files) if ctx.files.runtime_files else depset([]),
    )

    return [
        platform_common.ToolchainInfo(
            julia_toolchain = toolchain_info,
        ),
    ]

julia_toolchain = rule(
    implementation = _julia_toolchain_impl,
    attrs = {
        "julia_bin": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The Julia binary executable.",
        ),
        "julia_home": attr.string(
            mandatory = True,
            doc = "The Julia installation directory (typically Sys.BINDIR).",
        ),
        "julia_version": attr.string(
            mandatory = True,
            doc = "The Julia version string (e.g., '1.11.7').",
        ),
        "runtime_files": attr.label_list(
            allow_files = True,
            default = [],
            doc = "Additional runtime files needed by Julia (for hermetic builds).",
        ),
    },
    doc = """Defines a Julia toolchain.

This rule wraps Julia toolchain information (binary, home directory, version)
into a format that Bazel can use for toolchain resolution.

Example:
    julia_toolchain(
        name = "my_julia_toolchain",
        julia_bin = "bin/julia",
        julia_home = "/usr/local/julia/bin",
        julia_version = "1.11.7",
    )
""",
)
