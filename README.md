# Haskell CI

This project aims to capture my typical CI workflow for open source Haskell
libraries. It is by no means suggested as a production CI workflow for
Haskell projects. In particular, in the case of open source library
development I do not bother pinning down all my dependencies—I welcome
testing against newer versions of dependencies as they appear. The present
workflow is intentionally built around Cabal and features checks that I find
meaningful for developing and publishing on Hackage.

## Quick Start

In your Haskell project, create `.github/workflows/ci.yaml`:

```yaml
name: CI
on:
  push:
    branches:
      - master
  pull_request:
    types:
      - opened
      - synchronize

jobs:
  ci:
    uses: mrkkrp/haskell-ci/.github/workflows/haskell-ci.yml@master
```

This GitHub action assumes the existence of a `cabal.project` file of this
form:

```
packages: .
tests: True      # recommended, will not be enabled by this action
benchmarks: True # similarly for benchmarks
constraints: my-package +dev # enable dev options for CI, such as -Wall -Werror
```

## Configuration

| Input | Description | Type | Default |
|-------|-------------|------|---------|
| `ghc-versions` | GHC versions to test (JSON array) | `string` | `["9.10.3", "9.12.4", "9.14.1"]` |
| `cabal-version` | Cabal version | `string` | `3.16` |
| `run-ormolu` | Run Ormolu formatting check | `boolean` | `true` |
| `additional-packages` | Space-separated list of additional packages in subdirectories (e.g., test packages). These packages will have formatting checks, cabal check, and sdist creation applied to them in addition to the main package. | `string` | `""` |
| `test-windows` | Enable Windows testing | `boolean` | `false` |
| `system-dependencies` | System packages to install via apt-get (space-separated, Linux only) | `string` | `""` |
| `pre-test-script` | Script to run before tests | `string` | `""` |
| `cache-version` | Cache key version suffix | `string` | `0` |

None of these options is required.

## Workflow structure

The workflow creates these jobs:

1. **ormolu** (optional): Checks code formatting
2. **linux**: Main build and test job with GHC matrix
3. **windows** (optional): Windows-specific testing

Each build job performs:
1. Checkout code
2. Set up GHC and Cabal
3. Update and freeze dependencies
4. Cache dependencies
5. Check formatting of Cabal files (in Linux job only)
6. Run cabal check (in Linux job only)
7. Create source distributions (in Linux job only)
8. Build all packages with documentation (`cabal build all --enable-documentation`)
9. Run pre-test script (optional, in Linux job only)
10. Run all tests (`cabal test all --enable-documentation`)

## License

MIT

## Contributing

Issues and pull requests are welcome! Please test changes with the example
workflows.
