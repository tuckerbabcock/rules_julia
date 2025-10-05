"""Bazel module extensions for Julia toolchain."""

load("//toolchain:repositories.bzl", "JULIA_VERSIONS", "julia_download", "julia_repository")

def _toolchain_impl(module_ctx):
    """Implementation of julia_toolchain module extension."""

    # Track created repos for Bazel 8+ compatibility
    repos = []

    # Collect all toolchain configurations
    for mod in module_ctx.modules:
        for toolchain in mod.tags.toolchain:
            if toolchain.hermetic:
                # Register hermetic toolchains
                version = toolchain.version

                # Get checksums from JULIA_VERSIONS
                if version not in JULIA_VERSIONS:
                    fail("Unsupported Julia version: {}. Supported: {}".format(
                        version,
                        ", ".join(JULIA_VERSIONS.keys()),
                    ))

                checksums = JULIA_VERSIONS[version]

                julia_download(
                    name = "julia_linux_x86_64",
                    version = version,
                    os = "linux",
                    arch = "x86_64",
                    sha256 = checksums.get("linux_x86_64", ""),
                )
                repos.append("julia_linux_x86_64")

                julia_download(
                    name = "julia_linux_aarch64",
                    version = version,
                    os = "linux",
                    arch = "aarch64",
                    sha256 = checksums.get("linux_aarch64", ""),
                )
                repos.append("julia_linux_aarch64")

                julia_download(
                    name = "julia_macos_x86_64",
                    version = version,
                    os = "mac",
                    arch = "x64",
                    sha256 = checksums.get("mac_x86_64", ""),
                )
                repos.append("julia_macos_x86_64")

                julia_download(
                    name = "julia_macos_aarch64",
                    version = version,
                    os = "mac",
                    arch = "aarch64",
                    sha256 = checksums.get("mac_aarch64", ""),
                )
                repos.append("julia_macos_aarch64")
            else:
                # Register system Julia
                julia_repository(
                    name = "julia_toolchain_repo",
                    julia_path = toolchain.julia_path,
                )
                repos.append("julia_toolchain_repo")

    # Return extension metadata for Bazel 8+ compatibility
    return module_ctx.extension_metadata(
        root_module_direct_deps = repos,
        root_module_direct_dev_deps = [],
    )

_toolchain = tag_class(
    attrs = {
        "hermetic": attr.bool(
            doc = "Whether to use hermetic Julia",
            default = True,
        ),
        "julia_path": attr.string(
            doc = "Path to system Julia (non-hermetic only)",
        ),
        "name": attr.string(
            doc = "Name of the toolchain configuration",
            default = "julia",
        ),
        "version": attr.string(
            doc = "Julia version for hermetic builds",
            default = "1.11.7",
        ),
    },
)

julia_toolchain_extension = module_extension(
    implementation = _toolchain_impl,
    tag_classes = {
        "toolchain": _toolchain,
    },
)
