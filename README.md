# Haskell CI

A reusable GitHub Actions workflow for Haskell projects that eliminates CI/CD boilerplate while maintaining flexibility.

## Features

- **Code formatting** with Ormolu
- **Package validation** with automatic `cabal check`
- **Multi-GHC version** testing via build matrix
- **Dependency caching** for faster builds
- **Cross-platform support** (Linux and Windows)
- **Multi-package project** support (automatically builds and tests all packages)
- **Configurable build options**
- **Pre-test setup** for external services
- **Documentation generation** with Haddock
- **Source distribution** creation

## Quick Start

In your Haskell project, create `.github/workflows/ci.yml`:

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

That's it! This gives you a complete CI pipeline with sensible defaults.

## Configuration Options

### Basic Options

| Input | Description | Default |
|-------|-------------|---------|
| `ghc-versions` | GHC versions to test (JSON array) | `["9.10.3", "9.12.4", "9.14.1"]` |
| `cabal-version` | Cabal version | `3.16` |
| `run-ormolu` | Run Ormolu formatting check | `true` |
| `ormolu-version` | Ormolu action version | `v17` |

### Multi-Package Projects

| Input | Description | Default |
|-------|-------------|---------|
| `additional-packages` | Space-separated list of additional packages in subdirectories (e.g., test packages). These packages will have formatting checks, cabal check, and sdist creation applied to them in addition to the main package. | `""` |

### Cross-Platform Testing

| Input | Description | Default |
|-------|-------------|---------|
| `test-windows` | Enable Windows testing | `false` |

### Build Configuration

| Input | Description | Default |
|-------|-------------|---------|
| `pre-test-script` | Script to run before tests | `""` |
| `cache-version` | Cache key version suffix | `0` |

## Examples

### Simple Project

Most single-package projects work with defaults:

```yaml
jobs:
  ci:
    uses: mrkkrp/haskell-ci/.github/workflows/haskell-ci.yml@master
```

### Multi-Package Project

For projects with multiple packages (e.g., main package + tests package in
subdirectories):

```yaml
jobs:
  ci:
    uses: mrkkrp/haskell-ci/.github/workflows/haskell-ci.yml@master
    with:
      # List subdirectories containing additional .cabal packages
      additional-packages: 'my-package-tests'
```

This ensures that additional packages get:
- Code formatting checks (`cabal format`)
- Package validation (`cabal check`)
- Source distribution creation (`cabal sdist`)

Note: `cabal build all`, `cabal test all`, and `cabal haddock all`
automatically handle all packages in your `cabal.project`, so you don't need
to specify packages for building, testing, or documentation generation.

### With External Services

For projects requiring external services (databases, APIs):

```yaml
jobs:
  ci:
    uses: mrkkrp/haskell-ci/.github/workflows/haskell-ci.yml@master
    with:
      pre-test-script: |
        docker pull postgres:15
        docker run -p 5432:5432 -e POSTGRES_PASSWORD=test postgres:15 &
```

### Cross-Platform

For libraries that must work on Windows:

```yaml
jobs:
  ci:
    uses: mrkkrp/haskell-ci/.github/workflows/haskell-ci.yml@master
    with:
      test-windows: true
      # Uses the same GHC versions for both Linux and Windows
```

### Custom Configuration

Full control over all aspects:

```yaml
jobs:
  ci:
    uses: mrkkrp/haskell-ci/.github/workflows/haskell-ci.yml@master
    with:
      ghc-versions: '["9.8.2", "9.10.1"]'
      cabal-version: '3.14'
      run-ormolu: false
      cache-version: '1'  # Bump to invalidate caches
```

## Migration Guide

### From Manual Workflow

Replace your existing `.github/workflows/ci.yml` with one of the examples above. The workflow handles:

1. **Ormolu job**: Automatically included (disable with `run-ormolu: false`)
2. **Build matrix**: Configurable via `ghc-versions`
3. **All standard steps**: checkout, setup, cache, format, build, test, haddock, sdist

### Handling Special Cases

#### Multiple Packages
If you have commands that handle packages in subdirectories:
```yaml
- run: pushd my-tests && cabal format && popd
- run: pushd my-tests && cabal check && popd
- run: pushd my-tests && cabal sdist && popd
```

Replace with:
```yaml
with:
  # Specify subdirectory containing the additional package
  additional-packages: 'my-tests'
```

Multiple packages can be specified with space separation:
```yaml
with:
  additional-packages: 'package-tests package-benchmarks'
```

#### Docker Services
If you have:
```yaml
- run: docker run -p 1234:80 httpbin &
- run: cabal test
```

Use:
```yaml
with:
  pre-test-script: 'docker run -p 1234:80 httpbin &'
```

#### Cabal Check

The workflow automatically runs `cabal check` with sensible defaults
including `--ignore=missing-upper-bounds` and `--ignore=option-o2`. No
configuration needed.

## Workflow Structure

The reusable workflow creates these jobs:

1. **ormolu** (optional): Checks code formatting
2. **build-linux**: Main build and test job with GHC matrix
3. **build-windows** (optional): Windows-specific testing

Each build job performs:
1. Checkout code
2. Set up GHC and Cabal
3. Update and freeze dependencies
4. Cache dependencies
5. Check formatting
6. Run cabal check
7. Build all packages (`cabal build all`)
8. Run pre-test script (optional)
9. Run all tests (`cabal test all`)
10. Generate documentation for all packages (`cabal haddock all`)
11. Create source distributions

## Versioning

Use specific tags or commits for stability:

```yaml
uses: mrkkrp/haskell-ci/.github/workflows/haskell-ci.yml@v1.0.0
```

## License

MIT

## Contributing

Issues and pull requests are welcome! Please test changes with the example
workflows.
