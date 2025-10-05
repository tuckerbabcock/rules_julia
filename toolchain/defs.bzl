"""Public API for Julia toolchain.

This module provides the main entry points for using Julia with Bazel.
Import this in your WORKSPACE file to set up Julia toolchains.
"""

load(
    "//toolchain:repositories.bzl",
    _julia_download = "julia_download",
    _julia_register_toolchains = "julia_register_toolchains",
    _julia_repository = "julia_repository",
)
load(
    "//toolchain:toolchain.bzl",
    _JuliaToolchainInfo = "JuliaToolchainInfo",
    _julia_toolchain = "julia_toolchain",
)

# Re-export public API
julia_register_toolchains = _julia_register_toolchains
julia_repository = _julia_repository
julia_download = _julia_download
julia_toolchain = _julia_toolchain
JuliaToolchainInfo = _JuliaToolchainInfo
