# linux-aio

Personal aio script for quick setup on Debian/Ubuntu-based distros and Fedora

## Features
- tmux + TPM setup
- zsh + Oh My Zsh + custom folder from this repo (theme, aliases, options, editor)
- lsd
- flatpak + flathub remote
- flatpak apps: Gear Lever, KeePassXC
- syncthing
- micro installed to /usr/local/bin and set as default editor
- dry run

## Prerequisites
- bash
- sudo
- curl/wget

## Installation

### curl

```

bash <(curl -fsSL https://raw.githubusercontent.com/xqbreeze/linux-aio/master/install.sh) --all

```

### wget

```

bash <(wget -qO- https://raw.githubusercontent.com/xqbreeze/linux-aio/master/install.sh) --all

```

## Usage

- `-a, --all` — everything
- `-t, --tmux` — tmux config
- `-z, --zsh` — zsh + oh-my-zsh + repo custom
- `-l, --lsd` — lsd
- `-f, --flatpak` — flatpak + flathub remote
- `-g, --gearlever` — flatpak Gear Lever (requires `--flatpak` if flatpak not present)
- `-k, --keepassxc` — flatpak KeePassXC (requires `--flatpak` if flatpak not present)
- `-s, --syncthing` — syncthing via package manager
- `-m, --micro` — micro to `/usr/local/bin`, set as default editor (zsh via `custom/editor.zsh`, bash via `~/.bashrc`)
- `--dry-run` — print commands without executing

Examples:
- Everything: `bash <(wget -qO- https://raw.githubusercontent.com/xqbreeze/linux-aio/master/install.sh) -a`
- Flatpak base + apps only: `bash <(wget -qO- https://raw.githubusercontent.com/xqbreeze/linux-aio/master/install.sh) -f -g -k`
- Only zsh + micro: `bash <(wget -qO- https://raw.githubusercontent.com/xqbreeze/linux-aio/master/install.sh) -z -m`
