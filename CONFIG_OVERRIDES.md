# Configuration File Override Notice

When using `install.asdf.yaml` and `install.base.yaml` for installation, the following configuration files will be **forcefully overwritten**. Please back up any important existing configurations before proceeding.

## List of Forcefully Overwritten Configuration Files

### 1. Files Overwritten via `link` Operation

The following files will be overwritten during installation via the `link` operation (with `force: true` or `relink: true`):

- `~/.config/starship.toml`  ←  `config/starship/starship.toml`
- `~/.zshrc`                ←  `config/zsh/zshrc.zsh`
- `~/.zprofile`             ←  `config/zsh/zprofile.zsh`
- `~/.config/zsh`           ←  `config/zsh`
- `~/.gitconfig`            ←  `config/git/gitconfig`
- `~/.gitmessage`           ←  `config/git/gitmessage`
- `~/.gitignore`            ←  `config/git/gitignore`
- `~/.config/htop`          ←  `config/htop`
- `~/.config/tmux`          ←  `config/tmux`
- `~/.config/nvim`          ←  `config/nvim`
- `~/.m2/settings.xml`      ←  `config/maven/settings.xml`
- `~/.npmrc`                ←  `config/node/npmrc`
- `~/.asdfrc`               ←  `config/asdf/asdfrc`
- `~/.asdf/asdf.sh`         ←  `config/asdf/asdf.sh`
- `~/.mcp.sh`               ←  `config/mcp/mcp.sh`
- `~/.cursor/mcp.json`      ←  `config/mcp/mcp.json`  (development mode)
- `~/.gemini/settings.json` ←  `config/mcp/gemini.json` (development mode)

> Note: Some files are only overwritten on macOS (e.g., `~/.config/iterm2`, `~/.mackup.cfg`, `~/.mackup`).

### 2. Files Initialized via `cp` Command

The following files are initialized during installation using the `cp` command (with the `-n` option, only copied if the target does not exist). Existing files will NOT be overwritten:

- `~/.zshrc.user`           ←  `config/zsh/zshrc.zsh.user`
- `~/.secrets`              ←  `config/zsh/secrets`
- `~/.gitconfig.user`       ←  `config/git/gitconfig.user`

### 3. Additional Notes

- Files in the `~/.local/bin` directory will be linked from `config/scripts/*` using glob. Any files with the same name will be overwritten.
- Tools installed via asdf, npm, pip, etc., do not directly overwrite configuration files but may affect related environments.

## Override Behavior Explanation

- The `link` operation with `force: true` or `relink: true` will **unconditionally overwrite** the target file/directory.
- `cp -n` only copies if the target file does not exist and will NOT overwrite existing files.

## Recommendations

- Please back up all important configuration files listed above before installation.
- If you wish to keep personalized configurations, restore or merge them manually after installation.

---

If you have any questions, please refer to `dotfiles/dotbot/minimal/install.base.yaml` and `dotfiles/dotbot/development/install.asdf.yaml`, or contact the maintainer. 