## 1. Runtime Manager Bootstrap

- [x] 1.1 Replace `asdf` package installation in development setup with `mise` package installation for supported platforms.
- [x] 1.2 Add a repo-managed `mise` configuration file that declares global Go, Python, Node.js, and Bun versions.
- [x] 1.3 Update Dotbot development shell steps to install runtimes and global defaults through `mise` without plugin registration or reshim commands.

## 2. Shell And Installer Integration

- [x] 2.1 Replace `script/load-asdf.sh` with a shared loader that activates `mise` for interactive and non-interactive shells.
- [x] 2.2 Update `config/zsh/zshrc.zsh` and `config/zsh/exec.sh` to remove `asdf`-specific PATH/bootstrap logic and initialize `mise`.
- [x] 2.3 Update `install.sh` post-install PATH checks and runtime validation to use `mise` equivalents instead of `asdf current/list/set`.

## 3. Documentation And Cleanup

- [x] 3.1 Update setup docs (`README.md`, `INSTALL.md`) to describe `mise` as the development runtime manager and replace `asdf` commands/examples.
- [x] 3.2 Update overwrite/configuration notices to reflect any new `mise`-managed files and remove stale `~/.asdfrc` guidance if no longer needed.
- [x] 3.3 Remove or replace leftover `asdf` references in development-focused config and package manifests where `mise` is now the supported path.

## 4. Verification

- [x] 4.1 Verify the repository no longer depends on `asdf`-specific bootstrap commands in development installation flow.
- [x] 4.2 Run the relevant install/bootstrap checks to confirm `mise` activation resolves `python`, `node`, `go`, and `bun` through the new setup.
