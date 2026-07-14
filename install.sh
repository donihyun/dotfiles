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

        brew install tmux fzf git zsh lazygit
        return
    fi

    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y tmux fzf git zsh curl
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y tmux fzf git zsh curl
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y tmux fzf git zsh curl
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
}

main() {
    echo "Installing packages..."
    install_packages

    echo "Creating symlinks..."
    link_file "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
    link_file "$DOTFILES_DIR/bin/tmux-sessionizer" \
        "$HOME/.local/bin/tmux-sessionizer"

    install_tpm

    echo
    echo "Installation complete."
    echo
    echo "Before using Ctrl+s as the tmux prefix, run:"
    echo "  stty -ixon"
    echo
    echo "Start tmux:"
    echo "  tmux new -s work"
    echo
    echo "Then install TPM plugins with:"
    echo "  Ctrl+s followed by Shift+i"
}

main "$@"
