"""Repository rules for Julia toolchain setup.

This module provides rules for both hermetic (downloading Julia) and
non-hermetic (using system Julia) toolchain configurations.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")

# Official Julia versions with verified SHA256 checksums
# Source: https://julialang.org/downloads/
_JULIA_VERSIONS = {
    "1.10.10": {
        "linux_aarch64": "a4b157ed68da10471ea86acc05a0ab61c1a6931ee592a9b236be227d72da50ff",
        "linux_x86_64": "6a78a03a71c7ab792e8673dc5cedb918e037f081ceb58b50971dfb7c64c5bf81",
        "mac_aarch64": "52d3f82c50d9402e42298b52edc3d36e0f73e59f81fc8609d22fa094fbad18be",
        "mac_x86_64": "942b0d4accc9704861c7781558829b1d521df21226ad97bd01e1e43b1518d3e6",
    },
    "1.11.7": {
        "linux_aarch64": "f97f80b35c12bdaf40c26f6c55dbb7617441e49c9e6b842f65e8410a388ca6f4",
        "linux_x86_64": "aa5924114ecb89fd341e59aa898cd1882b3cb622ca4972582c1518eff5f68c05",
        "mac_aarch64": "74df9d4755a7740d141b04524a631e2485da9d65065d934e024232f7ba0790b6",
        "mac_x86_64": "b2c11315df39da478ab0fa77fb228f3fd818f1eaf42dc5cc1223c703f7122fe5",
    },
}

# Export for use in extensions.bzl
JULIA_VERSIONS = _JULIA_VERSIONS

def _normalize_os(os_name):
    """Normalize OS name to Bazel platform constraint format.

    Args:
        os_name: OS name from repository_ctx.os.name

    Returns:
        Normalized OS name matching @platforms//os values
    """
    os_lower = os_name.lower()
    if "mac" in os_lower or "darwin" in os_lower:
        return "macos"
    elif "windows" in os_lower:
        return "windows"
    else:
        return "linux"

def _normalize_cpu(arch):
    """Normalize CPU architecture to Bazel platform constraint format.

    Args:
        arch: Architecture name from repository_ctx.os.arch

    Returns:
        Normalized architecture matching @platforms//cpu values
    """
    if arch in ["amd64", "x86_64", "x64"]:
        return "x86_64"
    elif arch in ["arm64", "aarch64"]:
        return "aarch64"
    elif arch in ["arm", "armv7", "armv7l"]:
        return "arm"
    return arch

def _get_julia_download_url(version, os, arch):
    """Construct the official Julia download URL.

    Args:
        version: Julia version (e.g., "1.11.7")
        os: Operating system ("linux", "mac", "winnt")
        arch: Architecture ("x86_64", "aarch64", "x64", etc.)

    Returns:
        Full URL to the Julia tarball/archive

    Julia URL format: https://julialang-s3.julialang.org/bin/{os}/{arch}/{major.minor}/julia-{version}-{filename-pattern}
    """
    major_minor = ".".join(version.split(".")[:2])

    # Julia uses "x64" in URLs for x86_64 architecture
    # Map architecture to URL path component and filename pattern
    if os == "mac":
        if arch in ["x86_64", "x64"]:
            url_arch = "x64"
            filename = "julia-{}-mac64.tar.gz".format(version)
        elif arch == "aarch64":
            url_arch = "aarch64"
            filename = "julia-{}-macaarch64.tar.gz".format(version)
        else:
            fail("Unsupported macOS architecture: {}".format(arch))
    elif os == "linux":
        if arch in ["x86_64", "x64"]:
            url_arch = "x64"
            filename = "julia-{}-linux-x86_64.tar.gz".format(version)
        elif arch == "aarch64":
            url_arch = "aarch64"
            filename = "julia-{}-linux-aarch64.tar.gz".format(version)
        elif arch in ["i686", "x86"]:
            url_arch = "x86"
            filename = "julia-{}-linux-i686.tar.gz".format(version)
        else:
            fail("Unsupported Linux architecture: {}".format(arch))
    elif os == "winnt":
        if arch in ["x86_64", "x64"]:
            url_arch = "x64"
            filename = "julia-{}-win64.zip".format(version)
        elif arch in ["i686", "x86"]:
            url_arch = "x86"
            filename = "julia-{}-win32.zip".format(version)
        else:
            fail("Unsupported Windows architecture: {}".format(arch))
    else:
        fail("Unsupported operating system: {}".format(os))

    return "https://julialang-s3.julialang.org/bin/{}/{}/{}/{}".format(
        os,
        url_arch,
        major_minor,
        filename,
    )

def _julia_repository_impl(repository_ctx):
    """Auto-detect local Julia installation and create toolchain.

    This rule finds Julia on the system, queries its version and location,
    then generates a BUILD file with the appropriate toolchain definition.
    """
    julia_path = repository_ctx.attr.julia_path

    if not julia_path:
        julia_path = repository_ctx.which("julia")
        if not julia_path:
            fail(
                "Could not find Julia installation. " +
                "Please install Julia or set julia_path attribute.",
            )
    
    # Normalize the path to resolve any redundancies
    julia_path = paths.normalize(str(julia_path))

    # Get Julia version
    result = repository_ctx.execute([julia_path, "--version"])
    if result.return_code != 0:
        fail("Failed to execute Julia at {}: {}".format(julia_path, result.stderr))

    version_output = result.stdout.strip()
    
    # Validate this is actually Julia by checking version output format
    if not version_output.startswith("julia version"):
        fail(
            "Binary at {} does not appear to be Julia. ".format(julia_path) +
            "Version output: {}".format(version_output),
        )
    
    # Sanitize version string to prevent injection into BUILD file
    # Allow only alphanumeric, dots, hyphens, spaces, and parentheses
    sanitized_version = ""
    for char in version_output.elems():
        if char.isalnum() or char in [" ", ".", "-", "(", ")", "+"]:
            sanitized_version += char
    
    if not sanitized_version:
        fail("Julia version string contains invalid characters: {}".format(version_output))
    
    version_output = sanitized_version

    # Get Julia home directory (BINDIR)
    result = repository_ctx.execute([
        julia_path,
        "-e",
        "print(Sys.BINDIR)",
    ])
    if result.return_code != 0:
        fail("Failed to get Julia BINDIR: " + result.stderr)

    julia_bindir = result.stdout.strip()
    
    # Sanitize BINDIR path to prevent injection
    # This should be a filesystem path, validate it looks reasonable
    if not julia_bindir or "\n" in julia_bindir or "\r" in julia_bindir:
        fail("Julia BINDIR contains invalid characters: {}".format(julia_bindir))
    
    # Normalize the path to resolve any redundancies
    julia_bindir = paths.normalize(julia_bindir)

    # Create symlink to Julia binary
    repository_ctx.symlink(julia_path, "julia")

    # Normalize platform identifiers for Bazel constraints
    os_name = _normalize_os(repository_ctx.os.name)
    cpu_arch = _normalize_cpu(repository_ctx.os.arch)

    # Generate BUILD file
    repository_ctx.file("BUILD.bazel", """# Auto-generated by julia_repository
load("@rules_julia//toolchain:toolchain.bzl", "julia_toolchain")

exports_files(["julia"])

julia_toolchain(
    name = "julia_toolchain_impl",
    julia_bin = ":julia",
    julia_home = "{julia_home}",
    julia_version = "{version}",
    visibility = ["//visibility:public"],
)

toolchain(
    name = "julia_toolchain",
    exec_compatible_with = [
        "@platforms//os:{os}",
        "@platforms//cpu:{cpu}",
    ],
    toolchain = ":julia_toolchain_impl",
    toolchain_type = "@rules_julia//toolchain:toolchain_type",
    visibility = ["//visibility:public"],
)
""".format(
        julia_home = julia_bindir,
        version = version_output,
        os = os_name,
        cpu = cpu_arch,
    ))

julia_repository = repository_rule(
    implementation = _julia_repository_impl,
    attrs = {
        "julia_path": attr.string(
            doc = "Path to the Julia binary. If not specified, searches PATH.",
        ),
    },
    local = True,
    configure = True,
    doc = """Auto-detects the local Julia installation and creates a toolchain.

This rule is used for non-hermetic builds where Julia is already installed
on the system. It will find Julia, query its version and location, and
generate a toolchain that Bazel can use.

Example:
    julia_repository(
        name = "local_julia",
        julia_path = "/usr/local/bin/julia",  # optional
    )
""",
)

def _julia_download_impl(repository_ctx):
    """Download hermetic Julia distribution from official sources.

    Downloads and extracts a Julia release, then creates a BUILD file
    with a hermetic toolchain definition.
    """
    version = repository_ctx.attr.version
    os = repository_ctx.attr.os
    arch = repository_ctx.attr.arch
    url = repository_ctx.attr.url
    sha256 = repository_ctx.attr.sha256

    # Use custom URL if provided, otherwise construct official URL
    if not url:
        url = _get_julia_download_url(version, os, arch)

    # Download and extract Julia
    repository_ctx.download_and_extract(
        url = url,
        sha256 = sha256,
        stripPrefix = "julia-" + version,
    )

    # Determine binary path based on OS
    julia_bin_path = "bin/julia.exe" if os == "winnt" else "bin/julia"

    # Normalize platform constraints for Bazel
    os_constraint = _normalize_os(os)
    cpu_constraint = _normalize_cpu(arch)

    # Generate BUILD file
    repository_ctx.file("BUILD.bazel", """# Auto-generated by julia_download
load("@rules_julia//toolchain:toolchain.bzl", "julia_toolchain")

filegroup(
    name = "runtime_files",
    srcs = glob(["**/*"]),
    visibility = ["//visibility:public"],
)

exports_files(["{julia_bin}"])

julia_toolchain(
    name = "julia_toolchain_impl",
    julia_bin = "{julia_bin}",
    julia_home = "bin",
    julia_version = "{version}",
    runtime_files = [":runtime_files"],
    visibility = ["//visibility:public"],
)

toolchain(
    name = "julia_toolchain",
    exec_compatible_with = [
        "@platforms//os:{os}",
        "@platforms//cpu:{cpu}",
    ],
    target_compatible_with = [
        "@platforms//os:{os}",
        "@platforms//cpu:{cpu}",
    ],
    toolchain = ":julia_toolchain_impl",
    toolchain_type = "@rules_julia//toolchain:toolchain_type",
    visibility = ["//visibility:public"],
)
""".format(
        julia_bin = julia_bin_path,
        version = version,
        os = os_constraint,
        cpu = cpu_constraint,
    ))

julia_download = repository_rule(
    implementation = _julia_download_impl,
    attrs = {
        "arch": attr.string(
            mandatory = True,
            doc = "Architecture: 'x86_64', 'aarch64', 'i686', etc.",
        ),
        "os": attr.string(
            mandatory = True,
            doc = "Operating system: 'linux', 'mac', or 'winnt'.",
        ),
        "sha256": attr.string(
            doc = "SHA256 checksum of the archive. Required for hermetic builds.",
        ),
        "url": attr.string(
            doc = "Optional: Override URL for Julia download. If not specified, uses official Julia S3 URL.",
        ),
        "version": attr.string(
            mandatory = True,
            doc = "Julia version to download (e.g., '1.11.7').",
        ),
    },
    doc = """Downloads a hermetic Julia distribution for a specific platform.

This rule downloads Julia from the official sources (or a custom URL) and
creates a hermetic toolchain that doesn't depend on system installations.

Example:
    julia_download(
        name = "julia_linux",
        version = "1.11.7",
        os = "linux",
        arch = "x86_64",
        sha256 = "aa5924114ecb89fd341e59aa898cd1882b3cb622ca4972582c1518eff5f68c05",
    )
""",
)

def julia_register_toolchains(
        name = "julia",
        julia_path = None,
        hermetic = False,
        version = "1.11.7",
        custom_urls = None,
        custom_sha256 = None):
    """Register Julia toolchains with Bazel.

    This is the main entry point for setting up Julia toolchains. It supports
    both hermetic (downloaded) and non-hermetic (system) Julia installations.

    Args:
        name: Unused, required by buildifier convention for macros.
        julia_path: Path to Julia binary for non-hermetic mode. If not provided,
                   searches PATH. Ignored if hermetic=True.
        hermetic: If True, downloads Julia binaries for hermetic builds.
                 If False, uses system Julia installation.
        version: Julia version for hermetic mode. Default: "1.11.7" (current stable).
                 Supported: "1.11.7" (stable), "1.10.10" (LTS).
        custom_urls: Dict mapping platform keys to download URLs for custom versions.
                    Keys: "linux_x86_64", "linux_aarch64", "mac_x86_64", "mac_aarch64".
                    Only used in hermetic mode with custom versions.
        custom_sha256: Dict mapping platform keys to SHA256 checksums.
                      Required if custom_urls is provided.

    Example (non-hermetic):
        julia_register_toolchains()

    Example (hermetic - stable):
        julia_register_toolchains(hermetic = True)

    Example (hermetic - LTS):
        julia_register_toolchains(hermetic = True, version = "1.10.10")

    Example (custom version):
        julia_register_toolchains(
            hermetic = True,
            version = "1.12.0",
            custom_urls = {"linux_x86_64": "https://..."},
            custom_sha256 = {"linux_x86_64": "abc123..."},
        )
    """
    if hermetic:
        # Determine checksums and URLs
        if custom_urls:
            if not custom_sha256:
                fail("custom_sha256 must be provided when using custom_urls")
            checksums = custom_sha256
            url_override = custom_urls
        elif version in _JULIA_VERSIONS:
            checksums = _JULIA_VERSIONS[version]
            url_override = {}
        else:
            fail(
                "Unknown Julia version: {}. Supported versions: {}. ".format(
                    version,
                    ", ".join(_JULIA_VERSIONS.keys()),
                ) + "Or provide custom_urls and custom_sha256.",
            )

        # Register hermetic toolchains for multiple platforms
        # Bazel will automatically select the appropriate one based on target platform
        julia_download(
            name = "julia_linux_x86_64",
            version = version,
            os = "linux",
            arch = "x86_64",
            url = url_override.get("linux_x86_64", ""),
            sha256 = checksums.get("linux_x86_64", ""),
        )

        julia_download(
            name = "julia_linux_aarch64",
            version = version,
            os = "linux",
            arch = "aarch64",
            url = url_override.get("linux_aarch64", ""),
            sha256 = checksums.get("linux_aarch64", ""),
        )

        julia_download(
            name = "julia_macos_x86_64",
            version = version,
            os = "mac",
            arch = "x64",
            url = url_override.get("mac_x86_64", ""),
            sha256 = checksums.get("mac_x86_64", ""),
        )

        julia_download(
            name = "julia_macos_aarch64",
            version = version,
            os = "mac",
            arch = "aarch64",
            url = url_override.get("mac_aarch64", ""),
            sha256 = checksums.get("mac_aarch64", ""),
        )

        # Register all hermetic toolchains
        native.register_toolchains(
            "@julia_linux_x86_64//:julia_toolchain",
            "@julia_linux_aarch64//:julia_toolchain",
            "@julia_macos_x86_64//:julia_toolchain",
            "@julia_macos_aarch64//:julia_toolchain",
        )
    else:
        # Non-hermetic: use system Julia
        julia_repository(
            name = "julia_toolchain_repo",
            julia_path = julia_path,
        )

        native.register_toolchains("@julia_toolchain_repo//:julia_toolchain")
