# dotfiles

My macOS dev setup: Wave terminal, Orca, vim, zsh, Homebrew.

## New machine

```sh
xcode-select --install          # if git isn't available yet
git clone https://github.com/<you>/dotfiles ~/code/dotfiles
cd ~/code/dotfiles && ./install.sh
```

`install.sh` is safe to re-run. It:

1. Installs Homebrew if missing, then everything in `Brewfile`
2. Symlinks the config files below into place (existing files are moved to `~/.dotfiles-backup/<timestamp>/`)
3. Installs vim-plug and runs `:PlugInstall`
4. Installs Node via nvm if no default is set
5. Runs `gh auth login` if needed and sets gh as the git credential helper

`./install.sh --links` only redoes the symlinks.

## What's tracked

| Repo path | Linked to |
|---|---|
| `zsh/.zshrc`, `zsh/.zprofile` | `~/` |
| `vim/.vimrc` | `~/.vimrc` |
| `waveterm/*.json` | `~/.config/waveterm/` |
| `gh/config.yml` | `~/.config/gh/config.yml` |
| `Brewfile` | — (used by `brew bundle`) |

Since these are symlinks, edits made on this machine show up directly in the repo, so just commit them.

## Not tracked (on purpose)

- `~/.orca/`, `~/.config/opencode/`, `~/.claude/skills/`, and the Orca hooks in `~/.claude/settings.json` are written by Orca and get reinstalled when you launch it.
- `gh/hosts.yml` holds auth tokens.

## Keeping the Brewfile current

After installing or removing something with brew:

```sh
brew bundle dump --file=~/code/dotfiles/Brewfile --force
```

To find things installed that aren't in the Brewfile: `brew bundle cleanup --file=~/code/dotfiles/Brewfile` (this only lists them; add `--force` to uninstall).
