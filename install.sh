#!/usr/bin/env bash
#
# install.sh — universal setup script
# Repository: https://github.com/diluccio42/linux-aio

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/diluccio42/linux-aio/master"
TMPDIR=""
DRY_RUN=false
DO_TMUX=false
DO_ZSH=false

function show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -a, --all        Install all options
  -t, --tmux       Install tmux configuration
  -z, --zsh        Install zsh configuration
      --dry-run    Display all commands without executing
  -h, --help       Display help message
EOF
}

# dry-run wrapper
echo_cmd() {
  if $DRY_RUN; then
    echo "+ $*"
  else
    eval "$@"
  fi
}

# parse options
while (( "$#" )); do
  case "$1" in
    -a|--all)    DO_TMUX=true; DO_ZSH=true; shift ;;
    -t|--tmux)   DO_TMUX=true; shift ;;
    -z|--zsh)    DO_ZSH=true; shift ;;
    --dry-run)   DRY_RUN=true; shift ;;
    -h|--help)   show_help; exit 0 ;;
    *) echo "Unknown option: $1"; show_help >&2; exit 1 ;;
  esac
done

if ! $DO_TMUX && ! $DO_ZSH; then
  echo "No options selected." >&2
  show_help >&2
  exit 1
fi

# check for sudo availability and prompt for password
if ! command -v sudo >/dev/null; then
  echo "Error: sudo is required but not installed." >&2
  exit 1
fi

echo "Checking sudo privileges..."
if ! sudo true; then
  echo "Error: sudo authentication failed." >&2
  exit 1
fi

# detect package manager
if   command -v apt-get >/dev/null; then
  PKG_INSTALL="sudo apt-get install -y"
elif command -v dnf     >/dev/null; then
  PKG_INSTALL="sudo dnf install -y"
elif command -v yum     >/dev/null; then
  PKG_INSTALL="sudo yum install -y"
else
  echo "Unsupported package manager (apt, dnf, yum)." >&2
  exit 1
fi

# install prerequisites if missing
for cmd in git wget curl; do
  if ! command -v "$cmd" >/dev/null; then
    echo "Installing missing prerequisite: $cmd"
    echo_cmd "$PKG_INSTALL $cmd"
  fi
done

# create temporary directory
prepare_tmp() {
  TMPDIR=$(mktemp -d)
  trap 'rm -rf "$TMPDIR"' EXIT
}

# INSTALL TMUX
install_tmux() {
  echo "=== Setting up tmux ==="
  if ! command -v tmux >/dev/null; then
    echo_cmd "$PKG_INSTALL tmux"
  else
    echo "tmux is already installed."
  fi

  # download tpm plugin manager
  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    echo_cmd "git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
  else
    echo "tpm is already installed."
  fi

  # fetch .tmux.conf
  echo_cmd "wget -qO ~/.tmux.conf $REPO_RAW/tmux/.tmux.conf"
  echo "tmux configured."
}

# INSTALL ZSH
install_zsh() {
  echo "=== Setting up zsh ==="
  if ! command -v zsh >/dev/null; then
    echo_cmd "$PKG_INSTALL zsh"
  else
    echo "zsh is already installed."
  fi

  # install oh-my-zsh if missing
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo_cmd 'RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  else
    echo "Oh My Zsh is already installed."
  fi

  # download and copy custom folder
  prepare_tmp
  echo_cmd "wget -qO $TMPDIR/master.tar.gz https://github.com/diluccio42/linux-aio/archive/refs/heads/master.tar.gz"
  echo_cmd "tar -xzf $TMPDIR/master.tar.gz -C $TMPDIR"
  echo_cmd "rm -rf ~/.oh-my-zsh/custom"
  echo_cmd "cp -r $TMPDIR/linux-aio-master/zsh/custom ~/.oh-my-zsh/custom"

  # set ZSH_THEME to dpz34
  if [[ -f "$HOME/.zshrc" ]]; then
    echo "Setting ZSH_THEME to 'dpz34'..."
    echo_cmd "sed -i -E 's/^ZSH_THEME=.*/ZSH_THEME=\"dpz34\"/' ~/.zshrc"
  fi

  # change default shell or reload zsh config based on login shell
  CURRENT_SHELL=$(basename "$SHELL")
  if [[ "$CURRENT_SHELL" == "bash" ]]; then
    echo_cmd "chsh -s \$(command -v zsh)"
    echo "Default shell changed to zsh (will apply after next login)."
  else
    echo "To apply the new Zsh configuration, please run: source ~/.zshrc"
  fi
}

# MAIN
$DO_ZSH  && install_zsh
$DO_TMUX && install_tmux

echo ""
echo "Done!"
