workspace(name = "rules_julia")

load("//toolchain:defs.bzl", "julia_register_toolchains")

# Configuration options (uncomment one):

# Option 1: Use system Julia (non-hermetic, faster setup)
# Requires Julia to be installed on your system
# julia_register_toolchains()

# Option 2: Use hermetic Julia - latest stable (1.11.7) [DEFAULT]
# Downloads Julia for hermetic, reproducible builds
julia_register_toolchains(hermetic = True)

# Option 3: Use hermetic Julia - LTS version (1.10.10)
# For long-term stability
# julia_register_toolchains(hermetic = True, version = "1.10.10")
