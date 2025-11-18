# Docker Testing for Dotfiles

This directory contains Docker-based testing infrastructure for the dotfiles repository.

## Quick Start

```bash
# Test minimal installation on all distributions
make test

# Test specific distribution
make test-fedora
make test-rocky
make test-centos
make test-ubuntu
make test-alpine

# Test all distributions with all modes (comprehensive)
make test-all

# Quick test (Fedora minimal with cleanup)
make test-quick

# Clean up all test containers and images
make test-clean
```

## Manual Testing

### Using docker-compose

```bash
cd tests/docker

# Build and run specific test
docker-compose build fedora-minimal
docker-compose run --rm fedora-minimal

# Build all images
docker-compose build

# Run interactive shell in container
docker-compose run --rm fedora-minimal /bin/bash

# Clean up
docker-compose down --rmi all --volumes
```

### Using test script

```bash
cd tests/docker
./test-dotfiles.sh --help

# Test specific combinations
./test-dotfiles.sh -d fedora -m "minimal devops"
./test-dotfiles.sh -d "fedora rockylinux" -m minimal

# Test with cleanup
./test-dotfiles.sh -d fedora -m minimal -c
```

## Supported Distributions

- **Fedora** (latest) - Uses dnf package manager
- **Rocky Linux 9** - RHEL-compatible, uses dnf
- **CentOS Stream 9** - Rolling release RHEL, uses dnf
- **Ubuntu** (latest) - Debian-based, uses apt
- **Alpine Linux** (latest) - Minimal Linux, uses apk

## Installation Modes

- **minimal** - Basic configuration and tools
- **devops** - DevOps tools (kubectl, helm, terraform)
- **development** - Development environment with ASDF
- **desktop** - Full desktop environment (not tested in Docker)

## Test Structure

Each Dockerfile:
1. Installs basic dependencies (git, sudo, python3)
2. Creates a test user with sudo permissions
3. Copies dotfiles repository
4. Runs installation script with specified mode
5. Validates installation

## Adding New Tests

1. Create a new Dockerfile:
```dockerfile
FROM distro:version
# ... setup steps
```

2. Add service to docker-compose.yml:
```yaml
distro-mode:
  build:
    context: ../..
    dockerfile: tests/docker/Dockerfile.distro
    args:
      INSTALL_MODE: mode
```

3. Add Makefile target if needed:
```makefile
test-distro:
	@tests/docker/test-dotfiles.sh -d distro -m mode
```

## Troubleshooting

### Build failures
- Check logs: `docker-compose logs service-name`
- Review build output: `docker-compose build --no-cache service-name`

### Test failures
- Run interactively: `docker-compose run --rm service-name /bin/bash`
- Check installation logs inside container: `cat ~/.dotfiles/install.log`

### Clean up stuck containers
```bash
docker container prune -f
docker image prune -f
docker volume prune -f
```

## CI/CD Integration

The test suite can be integrated into CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Test dotfiles
  run: |
    make test-quick
    make test-clean
```