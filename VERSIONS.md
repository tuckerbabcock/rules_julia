# Supported Julia Versions

## Current Versions

| Version | Type | Notes |
|---------|------|-------|
| 1.11.7 | Stable | Default |
| 1.10.10 | LTS | Long-term support |

Source: https://julialang.org/downloads/

## Platforms

Hermetic toolchain supports:
- Linux x86_64
- Linux aarch64
- macOS x86_64 (Intel/Rosetta)
- macOS aarch64 (Apple Silicon)

For other platforms (Windows, FreeBSD, etc.), use `custom_urls` and `custom_sha256` parameters.

## Adding New Versions

1. Get checksums from https://julialang.org/downloads/
2. Add to `_JULIA_VERSIONS` in `toolchain/repositories.bzl`:

```starlark
"1.12.0": {
    "linux_x86_64": "sha256...",
    "linux_aarch64": "sha256...",
    "mac_x86_64": "sha256...",
    "mac_aarch64": "sha256...",
},
```

3. Update this file

