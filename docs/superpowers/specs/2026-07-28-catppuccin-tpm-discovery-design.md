# Catppuccin TPM Discovery Design

## Goal

Make TPM discover and install `catppuccin/tmux#v2.3.0` while preserving the existing behavior that only loads and configures Catppuccin on tmux versions that support the modern UI features.

## Change

Move the Catppuccin `set -g @plugin` declaration out of the quoted `if-shell` branch and make it an unconditional top-level plugin declaration. TPM statically parses top-level `@plugin` lines, so this makes Catppuccin part of its install list.

Keep the existing `@modern_tmux` conditions around `run-shell "~/.tmux/plugins/tmux/catppuccin.tmux"` and the Catppuccin status configuration. Older tmux versions may have the plugin installed on disk, but they will not load or use it.

## Verification

Before the change, run TPM's equivalent static parser against `.tmux.conf` and confirm that `catppuccin/tmux#v2.3.0` is absent. After the change, rerun it and confirm the plugin is present exactly once. Also verify that the guarded Catppuccin loading and status configuration remain in place, and that the installed `~/.tmux.conf` still matches the dotfiles source.

## Scope

This change only fixes Catppuccin discovery. It does not install plugins, change the tmux prefix, alter terminal flow control, or change the behavior of resurrect and continuum.
