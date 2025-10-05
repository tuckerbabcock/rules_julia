"""Providers for Julia rules."""

JuliaInfo = provider(
    doc = "Information about a Julia library or binary.",
    fields = {
        "runfiles": "runfiles: Runtime dependencies",
        "srcs": "depset[File]: Julia source files",
    },
)
