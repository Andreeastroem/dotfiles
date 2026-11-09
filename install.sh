#!/usr/bin/env bash
# Bootstrap a new Mac from this repo. Safe to re-run.
#   ./install.sh          full setup
#   ./install.sh --links  only (re)create symlinks
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

LOG="$(mktemp -t dotfiles-install)"

# run "label" cmd...  — show a spinner while cmd runs, output goes to $LOG.
# Use only for non-interactive steps; falls back to plain output without a TTY.
run() {
  local label="$1"; shift
  if [ ! -t 1 ]; then
    info "$label"
    "$@"
    return
  fi
  : >"$LOG"
  "$@" >"$LOG" 2>&1 &
  local pid=$! i=0 frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  printf '\033[?25l'
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r\033[1;34m%s\033[0m %s' "${frames:i++%${#frames}:1}" "$label"
    sleep 0.08
  done
  printf '\033[?25h'
  if wait "$pid"; then
    printf '\r\033[K\033[1;32m✔\033[0m %s\n' "$label"
  else
    printf '\r\033[K\033[1;31m✘\033[0m %s\n' "$label"
    tail -n 20 "$LOG" | sed 's/^/    /'
    echo "  full log: $LOG"
    return 1
  fi
}
trap 'printf "\033[?25h"' EXIT

# repo path -> target path
LINKS=(
  "zsh/.zshrc:$HOME/.zshrc"
  "zsh/.zprofile:$HOME/.zprofile"
  "vim/.vimrc:$HOME/.vimrc"
  "waveterm/settings.json:$HOME/.config/waveterm/settings.json"
  "waveterm/backgrounds.json:$HOME/.config/waveterm/backgrounds.json"
  "gh/config.yml:$HOME/.config/gh/config.yml"
  "mise/config.toml:$HOME/.config/mise/config.toml"
)

link_all() {
  info "Linking dotfiles"
  for pair in "${LINKS[@]}"; do
    src="$DOTFILES/${pair%%:*}"
    dst="${pair#*:}"
    if [ "$(readlink "$dst" 2>/dev/null)" = "$src" ]; then
      continue
    fi
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] || [ -L "$dst" ]; then
      mkdir -p "$BACKUP"
      mv "$dst" "$BACKUP/"
      echo "  backed up $dst -> $BACKUP/"
    fi
    ln -s "$src" "$dst"
    echo "  $dst -> $src"
  done
}

if [ "${1:-}" = "--links" ]; then
  link_all
  exit 0
fi

# Xcode command line tools (git, compilers)
if ! xcode-select -p >/dev/null 2>&1; then
  info "Installing Xcode Command Line Tools — re-run this script when it finishes"
  xcode-select --install
  exit 1
fi

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

info "Installing Brewfile packages"
brew bundle --file="$DOTFILES/Brewfile"

link_all

# vim-plug + plugins
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  info "Installing vim-plug"
  curl -fsLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
run "Installing vim plugins" \
  vim -es -u "$HOME/.vimrc" -i NONE -c "PlugInstall" -c "qa" || true

# Node via nvm
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
# shellcheck disable=SC1091
. "$(brew --prefix nvm)/nvm.sh"
if ! nvm ls default >/dev/null 2>&1; then
  run "Installing latest Node via nvm" nvm install node
  nvm alias default node >/dev/null
fi

# Runtimes from mise/config.toml (Java)
run "Installing mise tools" mise install

# Pinned: Homebrew's newest Python (3.15) lacks wheels for open-webui's deps (onnxruntime)
run "Installing open-webui (Python 3.12)" uv tool install --python 3.12 open-webui

# GitHub auth (interactive, only first time)
if ! gh auth status >/dev/null 2>&1; then
  info "Logging in to GitHub"
  gh auth login
fi
gh auth setup-git

info "Done. Open a new terminal to pick up the shell config."
