#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(
  cd "$(dirname "${BASH_SOURCE[0]}")"
  pwd
)"

backup_file() {
  local target="$1"

  if [[ -e "$target" || -L "$target" ]]; then
    local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
    echo "Backing up $target -> $backup"
    mv "$target" "$backup"
  fi
}

link_file() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" ]] &&
    [[ "$(readlink "$target")" == "$source" ]]; then
    echo "Already linked: $target"
    return
  fi

  backup_file "$target"
  ln -s "$source" "$target"
  echo "Linked $target -> $source"
}

install_packages() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
      echo "Homebrew is required on macOS."
      exit 1
    fi

    brew install tmux fzf git zsh lazygit zoxide eza bat ripgrep fd
    return
  fi

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y tmux fzf git zsh curl bat ripgrep fd-find
  elif command -v dnf >/dev/null 2>&1; then
    if grep -Eq '^ID="?ol"?$' /etc/os-release; then
      sudo dnf --enablerepo=ol9_developer_EPEL install -y \
        tmux fzf git zsh curl gcc clang

      local nvim_arch
      nvim_arch="$(uname -m)"
      [[ "$nvim_arch" == "aarch64" ]] && nvim_arch="arm64"
      mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"
      curl -fsSL "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${nvim_arch}.tar.gz" |
        tar -xz -C "$HOME/.local/opt"
      ln -sfn "$HOME/.local/opt/nvim-linux-${nvim_arch}/bin/nvim" \
        "$HOME/.local/bin/nvim"

      if [[ ! -x "$HOME/.local/bin/tree-sitter" ]]; then
        local remove_rust=false
        if [[ ! -x "$HOME/.cargo/bin/cargo" ]]; then
          curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
            sh -s -- -y --profile minimal
          remove_rust=true
        fi
        BINDGEN_EXTRA_CLANG_ARGS="-I$(gcc -print-file-name=include)" \
          "$HOME/.cargo/bin/cargo" install --locked --root "$HOME/.local" \
            tree-sitter-cli
        if "$remove_rust"; then
          "$HOME/.cargo/bin/rustup" self uninstall -y
        fi
      fi
    else
      sudo dnf install -y tmux fzf git zsh
    fi
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y tmux git zsh curl
  else
    echo "Unsupported package manager."
    exit 1
  fi

  if ! command -v lazygit >/dev/null 2>&1; then
    echo
    echo "lazygit was not found."
    echo "The tmux config will still work, but Prefix+g will fail until lazygit is installed."
  fi
}

install_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"

  if [[ -d "$tpm_dir/.git" ]]; then
    echo "TPM already installed."
  else
    mkdir -p "$(dirname "$tpm_dir")"
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  fi

  echo "Installing TPM plugins..."
  "$tpm_dir/bin/install_plugins"
}

install_zoxide() {
  if command -v zoxide >/dev/null 2>&1; then
    echo "zoxide already installed."
    return
  fi

  curl -sSfL \
    https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh |
    sh
}

main() {
  echo "Installing packages..."
  install_packages
  install_zoxide
  echo "Creating symlinks..."
  link_file "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
  link_file "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/bin/tmux-sessionizer" \
    "$HOME/.local/bin/tmux-sessionizer"
  link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
  install_tpm

  echo
  echo "Installation complete."
  echo
  echo "Before using Ctrl+s as the tmux prefix, run:"
  echo "  stty -ixon"
  echo
  echo "Start tmux:"
  echo "  tmux new -s work"
}

main "$@"
