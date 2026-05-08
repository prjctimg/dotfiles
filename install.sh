#!/bin/sh
set -e

# ─── Utilities ──────────────────────────────────────────────────────

has() { command -v "$1" >/dev/null 2>&1; }

gh_latest_tag() {
  curl -sI -o /dev/null -w '%{redirect_url}' "https://github.com/$1/$2/releases/latest" |
    sed 's|.*/tag/||; s|^v||'
}

install_pkg() {
  case "$PM" in
    apt)
      sudo apt-get update -qq
      sudo apt-get install -y -qq "$@"
      ;;
    apk)    sudo apk add --no-cache "$@" ;;
    brew)   brew install "$@" ;;
    dnf)    sudo dnf install -y "$@" ;;
    pacman) sudo pacman -S --noconfirm "$@" ;;
    zypper) sudo zypper install -y "$@" ;;
  esac
}

# ─── Platform detection ─────────────────────────────────────────────

PM=unknown
if has apt-get; then PM=apt
elif has apk;   then PM=apk
elif has brew;  then PM=brew
elif has dnf;   then PM=dnf
elif has pacman; then PM=pacman
elif has zypper; then PM=zypper
fi

ARCH=$(uname -m)
case "$ARCH" in
  x86_64)          GH_ARCH=amd64;  BIN_ARCH=x86_64  ;;
  aarch64|arm64)   GH_ARCH=arm64;  BIN_ARCH=aarch64 ;;
  *)               GH_ARCH="$ARCH"; BIN_ARCH="$ARCH" ;;
esac
# lazygit uses different arch naming
LAZY_ARCH="$BIN_ARCH"; [ "$ARCH" = aarch64 ] && LAZY_ARCH=arm64

# ─── System packages (available in most distros) ────────────────────

install_pkg git curl ca-certificates jq ripgrep fzf lua5.4 pv unzip lolcat

case "$PM" in
  apt) install_pkg nala neofetch ;;
esac

# ─── Neovim (appimage) ──────────────────────────────────────────────

if ! has nvim; then
  curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz \
    -o /tmp/nvim.tar.gz
  sudo tar xf /tmp/nvim.tar.gz -C /opt
  sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
  rm -f /tmp/nvim.tar.gz
fi

# ─── btop ───────────────────────────────────────────────────────────

if ! has btop; then
  tag=$(gh_latest_tag aristocratos btop)
  curl -fsSL "https://github.com/aristocratos/btop/releases/latest/download/btop-${BIN_ARCH}-linux-musl.tbz" \
    -o /tmp/btop.tbz
  tmpd=$(mktemp -d)
  cd "$tmpd" && tar xf /tmp/btop.tbz && sudo cp btop/bin/btop /usr/local/bin/ && rm -rf "$tmpd"
  rm -f /tmp/btop.tbz
fi

# ─── lazygit ────────────────────────────────────────────────────────

if ! has lazygit; then
  tag=$(gh_latest_tag jesseduffield lazygit)
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${tag}_Linux_${LAZY_ARCH}.tar.gz" \
    -o /tmp/lazygit.tar.gz
  sudo tar xf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
  rm -f /tmp/lazygit.tar.gz
fi

# ─── lsd ────────────────────────────────────────────────────────────

if ! has lsd; then
  tag=$(gh_latest_tag lsd-rs lsd)
  curl -fsSL "https://github.com/lsd-rs/lsd/releases/latest/download/lsd-${tag}-${BIN_ARCH}-unknown-linux-musl.tar.gz" \
    -o /tmp/lsd.tar.gz
  sudo tar xf /tmp/lsd.tar.gz -C /usr/local/bin --strip-components=1 "lsd-${tag}-${BIN_ARCH}-unknown-linux-musl/lsd"
  rm -f /tmp/lsd.tar.gz
fi

# ─── carapace ───────────────────────────────────────────────────────

if ! has carapace; then
  tag=$(gh_latest_tag carapace-sh carapace-bin)
  curl -fsSL "https://github.com/carapace-sh/carapace-bin/releases/latest/download/carapace_${tag}_linux_${GH_ARCH}.tar.gz" \
    -o /tmp/carapace.tar.gz
  sudo tar xf /tmp/carapace.tar.gz -C /usr/local/bin carapace
  rm -f /tmp/carapace.tar.gz
fi

# ─── starship ───────────────────────────────────────────────────────

if ! has starship; then
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y
fi

# ─── helix ──────────────────────────────────────────────────────────

if ! has hx; then
  tag=$(gh_latest_tag helix-editor helix)
  curl -fsSL "https://github.com/helix-editor/helix/releases/latest/download/helix-${tag}-${BIN_ARCH}-linux.tar.gz" \
    -o /tmp/helix.tar.gz
  sudo tar xf /tmp/helix.tar.gz -C /usr/local/bin --strip-components=1 "helix-${tag}-${BIN_ARCH}-linux/hx"
  rm -f /tmp/helix.tar.gz
fi

# ─── GitHub CLI ─────────────────────────────────────────────────────

if ! has gh; then
  if [ "$PM" = apt ]; then
    install_pkg gh
  else
    tag=$(gh_latest_tag cli cli)
    curl -fsSL "https://github.com/cli/cli/releases/latest/download/gh_${tag}_linux_${GH_ARCH}.tar.gz" \
      -o /tmp/gh.tar.gz
    sudo tar xf /tmp/gh.tar.gz -C /usr/local/bin --strip-components=2 "gh_${tag}_linux_${GH_ARCH}/bin/gh"
    rm -f /tmp/gh.tar.gz
  fi
fi

# ─── Rust (rustup) ─────────────────────────────────────────────────

if ! has rustc; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# shellcheck source=dev/null
. "$HOME/.cargo/env" 2>/dev/null || true

# ─── Go ─────────────────────────────────────────────────────────────

if ! has go; then
  if [ "$PM" = apt ]; then
    install_pkg golang-go
  else
    tag=$(curl -fsSL https://go.dev/VERSION?m=text | head -1)
    curl -fsSL "https://go.dev/dl/${tag}.linux-${GH_ARCH}.tar.gz" -o /tmp/go.tar.gz
    sudo tar xf /tmp/go.tar.gz -C /usr/local
    rm -f /tmp/go.tar.gz
  fi
fi

# ─── zvm (Zig version manager) ─────────────────────────────────────

if ! has zvm; then
  tag=$(gh_latest_tag tristanisham zvm)
  curl -fsSL "https://github.com/tristanisham/zvm/releases/latest/download/zvm-linux-${GH_ARCH}.tar.gz" \
    -o /tmp/zvm.tar.gz
  sudo tar xf /tmp/zvm.tar.gz -C /usr/local/bin
  rm -f /tmp/zvm.tar.gz
fi

# ─── pipx ───────────────────────────────────────────────────────────

if ! has pipx; then
  if has python3; then
    python3 -m pip install --user pipx 2>/dev/null || install_pkg pipx
  fi
fi

# ─── opencode ───────────────────────────────────────────────────────

if ! has opencode; then
  if has npm; then
    npm install -g @opencode-ai/opencode 2>/dev/null || true
  elif has pipx; then
    pipx install opencode 2>/dev/null || true
  fi
fi

# ─── fish-lsp (via cargo) ───────────────────────────────────────────

if ! has fish-lsp && has cargo; then
  cargo install fish-lsp 2>/dev/null || true
fi

# ─── Chezmoi bootstrap ──────────────────────────────────────────────

if ! has chezmoi; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply "https://github.com/prjctimg/dotfiles.git"
else
  chezmoi init --apply "https://github.com/prjctimg/dotfiles.git"
fi
