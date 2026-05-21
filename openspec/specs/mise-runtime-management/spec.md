## ADDED Requirements

### Requirement: Development install SHALL provision mise as the runtime manager
The development installation workflow SHALL install `mise` instead of `asdf` and SHALL stop requiring `asdf` plugin registration as part of bootstrap.

#### Scenario: Fresh development install
- **WHEN** a user runs the development or desktop installation mode on a machine without a runtime manager installed
- **THEN** the workflow installs `mise`
- **AND** the workflow does not execute `asdf` plugin registration or other `asdf`-specific bootstrap commands

#### Scenario: Re-running installation
- **WHEN** a user reruns the development or desktop installation mode on a machine where `mise` is already available
- **THEN** the workflow reuses the existing `mise` installation idempotently
- **AND** continues with runtime provisioning without requiring manual cleanup

### Requirement: Development install SHALL declare global runtime versions through mise
The development installation workflow SHALL declare and install the repository's default versions for Go, Python, Node.js, and Bun through `mise`-managed configuration so that runtime selection is reproducible.

#### Scenario: Installing configured runtimes
- **WHEN** the development installation workflow reaches runtime provisioning
- **THEN** it installs the configured Go, Python, Node.js, and Bun versions through `mise`
- **AND** sets those versions as the global defaults used after installation

#### Scenario: Missing runtime after bootstrap
- **WHEN** a configured runtime version is absent on the local machine during installation
- **THEN** the workflow installs the missing version through `mise`
- **AND** leaves the resulting global configuration aligned with the repository defaults

### Requirement: Shell bootstrap SHALL activate mise-managed shims
Interactive shells, non-interactive shell wrappers, and installer-side bootstrap scripts SHALL initialize `mise` so that runtime commands resolve through `mise` without sourcing `asdf`.

#### Scenario: Interactive zsh startup
- **WHEN** a user opens a new zsh session after applying the dotfiles
- **THEN** the shell activates `mise`
- **AND** runtime executables such as `python`, `node`, `go`, and `bun` resolve from `mise`-managed paths

#### Scenario: Non-interactive helper execution
- **WHEN** repository helper scripts execute commands through the shared shell wrapper
- **THEN** the wrapper activates `mise` before running the requested command
- **AND** does not require `ASDF_DIR`, `ASDF_DATA_DIR`, or `~/.asdf/shims` to be present

### Requirement: Documentation SHALL describe mise-based runtime management
User-facing documentation and overwrite notices SHALL describe `mise` as the supported development runtime manager and SHALL remove instructions that tell users to install, load, or reshim `asdf`.

#### Scenario: Reading setup guides
- **WHEN** a user follows the repository setup documentation for development mode
- **THEN** the documentation tells them that development runtimes are managed with `mise`
- **AND** any command examples use `mise` terminology

#### Scenario: Reviewing overwrite notices
- **WHEN** a user checks the configuration override documentation before installation
- **THEN** the document reflects any new `mise`-managed config files
- **AND** no longer claims that `~/.asdfrc` is the managed runtime-manager config unless a compatibility file is intentionally retained
