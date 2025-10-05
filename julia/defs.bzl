"""Public API for Julia build rules.

This module provides rules for building Julia programs with Bazel.
"""

load("//julia/private:julia_binary.bzl", _julia_binary = "julia_binary")
load("//julia/private:julia_library.bzl", _julia_library = "julia_library")
load("//julia/private:julia_test.bzl", _julia_test = "julia_test")

# Public API
julia_binary = _julia_binary
julia_library = _julia_library
julia_test = _julia_test
