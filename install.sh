#!/usr/bin/env bash
#
# install.sh — universal setup script
# Repository: https://github.com/xqbreeze/linux-aio

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/xqbreeze/linux-aio/master"
TMPDIR=""
TMPDIRS=()
DRY_RUN=false
DO_TMUX=false
DO_ZSH=false
DO_LSD=false
DO_FLATPAK_BASE=false
DO_GEAR_LEVER=false
DO_KEEPASSXC=false
DO_SYNCTHING=false
DO_MICRO=false

function show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -a, --all        Install all options
  -t, --tmux       Install tmux configuration
  -z, --zsh        Install zsh configuration
  -l, --lsd        Install lsd
  -f, --flatpak    Install flatpak and add flathub remote
  -g, --gearlever  Install Gear Lever (flatpak)
  -k, --keepassxc  Install KeePassXC (flatpak)
  -s, --syncthing  Install syncthing
  -m, --micro      Install micro editor and set it as default
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
    -a|--all)    DO_TMUX=true; DO_ZSH=true; DO_LSD=true; DO_FLATPAK_BASE=true; DO_GEAR_LEVER=true; DO_KEEPASSXC=true; DO_SYNCTHING=true; DO_MICRO=true; shift ;;
    -t|--tmux)   DO_TMUX=true; shift ;;
    -z|--zsh)    DO_ZSH=true; shift ;;
    -l|--lsd)    DO_LSD=true; shift ;;
    -f|--flatpak) DO_FLATPAK_BASE=true; shift ;;
    -g|--gearlever) DO_GEAR_LEVER=true; shift ;;
    -k|--keepassxc) DO_KEEPASSXC=true; shift ;;
    -s|--syncthing) DO_SYNCTHING=true; shift ;;
    -m|--micro)  DO_MICRO=true; shift ;;
    --dry-run)   DRY_RUN=true; shift ;;
    -h|--help)   show_help; exit 0 ;;
    *) echo "Unknown option: $1"; show_help >&2; exit 1 ;;
  esac
done

if ! $DO_TMUX && ! $DO_ZSH && ! $DO_LSD && ! $DO_FLATPAK_BASE && ! $DO_GEAR_LEVER && ! $DO_KEEPASSXC && ! $DO_SYNCTHING && ! $DO_MICRO; then
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
  TMPDIRS+=("$TMPDIR")
  trap 'rm -rf "${TMPDIRS[@]}"' EXIT
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
  echo_cmd "wget -qO $TMPDIR/master.tar.gz https://github.com/xqbreeze/linux-aio/archive/refs/heads/master.tar.gz"
  echo_cmd "tar -xzf $TMPDIR/master.tar.gz -C $TMPDIR"
  echo_cmd "rm -rf ~/.oh-my-zsh/custom"
  echo_cmd "cp -r $TMPDIR/linux-aio-master/zsh/custom ~/.oh-my-zsh/custom"

  # set ZSH_THEME to dpz34
  if [[ -f "$HOME/.zshrc" ]]; then
    echo "Setting ZSH_THEME to 'dpz34'..."
    echo_cmd "sed -i -E 's/^ZSH_THEME=.*/ZSH_THEME=\"dpz34\"/' ~/.zshrc"
  fi

  # change default shell
  CURRENT_SHELL=$(basename "$SHELL")
  if [[ "$CURRENT_SHELL" != "zsh" ]]; then
    echo_cmd "chsh -s \$(command -v zsh)"
    echo "Default shell changed to zsh (will apply after next login)."
  else
    echo "To apply the new Zsh configuration, please run: source ~/.zshrc"
  fi
}

# INSTALL LSD
install_lsd() {
  echo "=== Installing lsd ==="
  if ! command -v lsd >/dev/null; then
    echo_cmd "$PKG_INSTALL lsd"
  else
    echo "lsd is already installed."
  fi
}

install_flatpak_base() {
  echo "=== Installing flatpak and adding flathub ==="
  if ! command -v flatpak >/dev/null; then
    echo_cmd "$PKG_INSTALL flatpak"
  else
    echo "flatpak is already installed."
  fi

  if ! command -v flatpak >/dev/null; then
    if $DRY_RUN; then
      echo "flatpak is not currently available (dry-run), showing intended commands."
    else
      echo "flatpak installation failed." >&2
      exit 1
    fi
  fi

  echo_cmd "flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
}

require_flatpak() {
  if ! command -v flatpak >/dev/null; then
    echo "flatpak is required. Run with --flatpak first." >&2
    exit 1
  fi
}

install_gearlever() {
  echo "=== Installing Gear Lever (flatpak) ==="
  require_flatpak
  if flatpak list --app --columns=application | grep -Fxq "it.mijorus.gearlever"; then
    echo "Gear Lever is already installed."
  else
    echo_cmd "flatpak install -y --noninteractive flathub it.mijorus.gearlever"
  fi
}

install_keepassxc() {
  echo "=== Installing KeePassXC (flatpak) ==="
  require_flatpak
  if flatpak list --app --columns=application | grep -Fxq "org.keepassxc.KeePassXC"; then
    echo "KeePassXC is already installed."
  else
    echo_cmd "flatpak install -y --noninteractive --user flathub org.keepassxc.KeePassXC"
  fi
}

install_syncthing() {
  echo "=== Installing syncthing ==="
  if command -v syncthing >/dev/null; then
    echo "syncthing is already installed."
    return
  fi
  echo_cmd "$PKG_INSTALL syncthing"
}

set_bash_editor_env() {
  local file="$HOME/.bashrc"
  if [[ -f "$file" ]] && grep -q 'export EDITOR=micro' "$file" && grep -q 'export VISUAL=micro' "$file"; then
    return
  fi
  echo_cmd "printf '\\nexport EDITOR=micro\\nexport VISUAL=micro\\n' >> \"$file\""
  echo "Default editor set to micro in $file"
}

install_micro() {
  echo "=== Installing micro editor ==="
  local micro_path
  micro_path=$(command -v micro 2>/dev/null || true)

  if [[ "$micro_path" == "/usr/local/bin/micro" ]]; then
    echo "micro is already installed in /usr/local/bin."
  else
    prepare_tmp
    echo_cmd "cd \"$TMPDIR\" && curl -fsSL https://getmic.ro | bash"
    local micro_bin="$TMPDIR/micro"
    if ! $DRY_RUN; then
      micro_bin=$(find "$TMPDIR" -maxdepth 2 -type f -name micro -perm -u+x | head -n 1)
      if [[ -z "$micro_bin" ]]; then
        echo "Failed to download micro." >&2
        exit 1
      fi
    fi
    echo_cmd "sudo install -m 0755 \"$micro_bin\" /usr/local/bin/micro"
  fi

  if command -v update-alternatives >/dev/null; then
    echo_cmd "sudo update-alternatives --install /usr/bin/editor editor /usr/local/bin/micro 110"
    echo_cmd "sudo update-alternatives --set editor /usr/local/bin/micro"
  elif command -v alternatives >/dev/null; then
    echo_cmd "sudo alternatives --install /usr/bin/editor editor /usr/local/bin/micro 110"
    echo_cmd "sudo alternatives --set editor /usr/local/bin/micro"
  fi

  if ! $DO_ZSH; then
    set_bash_editor_env
  fi
}

# MAIN
$DO_ZSH  && install_zsh
$DO_TMUX && install_tmux
$DO_LSD  && install_lsd
$DO_FLATPAK_BASE && install_flatpak_base
$DO_GEAR_LEVER && install_gearlever
$DO_KEEPASSXC && install_keepassxc
$DO_SYNCTHING && install_syncthing
$DO_MICRO && install_micro

echo ""
echo "Done!"
