#!/bin/sh
set -e

# ─── Utilities ──────────────────────────────────────────────────────

has() { command -v "$1" >/dev/null 2>&1; }

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
elif has sudo; then
  SUDO="sudo"
else
  SUDO=""
fi

run_root() {
  if [ -n "$SUDO" ]; then
    $SUDO "$@"
  else
    "$@"
  fi
}

gh_latest_tag() {
  curl -sI -o /dev/null -w '%{redirect_url}' "https://github.com/$1/$2/releases/latest" |
    sed 's|.*/tag/||; s|^v||'
}

install_pkg() {
  case "$PM" in
  apt)
    run_root apt-get update -qq
    run_root apt-get install -y -qq "$@"
    ;;
  apk) run_root apk add --no-cache "$@" ;;
  brew) brew install "$@" ;;
  dnf) run_root dnf install -y "$@" ;;
  pacman) run_root pacman -S --noconfirm "$@" ;;
  zypper) run_root zypper install -y "$@" ;;
  esac
}

# ─── Platform detection ─────────────────────────────────────────────

PM=unknown
if has apt-get; then
  PM=apt
elif has apk; then
  PM=apk
elif has brew; then
  PM=brew
elif has dnf; then
  PM=dnf
elif has pacman; then
  PM=pacman
elif has zypper; then
  PM=zypper
fi

ARCH=$(uname -m)
case "$ARCH" in
x86_64)
  GH_ARCH=amd64
  BIN_ARCH=x86_64
  ;;
aarch64 | arm64)
  GH_ARCH=arm64
  BIN_ARCH=aarch64
  ;;
*)
  GH_ARCH="$ARCH"
  BIN_ARCH="$ARCH"
  ;;
esac
# lazygit uses different arch naming
LAZY_ARCH="$BIN_ARCH"
[ "$ARCH" = aarch64 ] && LAZY_ARCH=arm64

# ─── System packages (available in most distros) ────────────────────

install_pkg git curl ca-certificates jq ripgrep fzf lua5.4 pv unzip lolcat

case "$PM" in
apt)
  install_pkg nala neofetch 2>/dev/null || run_root apt-get install -y -qq nala 2>/dev/null || true
  run_root apt-get install -y -qq neofetch 2>/dev/null || true
  ;;
esac

# ─── Neovim ─────────────────────────────────────────────────────────

# Always install the latest release, even if an older nvim is already present.
case "$ARCH" in
  x86_64|amd64) NVIM_ARCH="x86_64" ;;
  aarch64|arm64) NVIM_ARCH="arm64" ;;
  *) NVIM_ARCH="$ARCH" ;;
esac
NVIM_PKG="nvim-linux-${NVIM_ARCH}"
NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/${NVIM_PKG}.tar.gz"
NVIM_LATEST=$(gh_latest_tag neovim neovim)
if ! has nvim || [ "$(nvim --version | head -1 | awk '{print $2}')" != "v${NVIM_LATEST}" ]; then
  curl -fsSL "$NVIM_URL" -o /tmp/nvim.tar.gz
  run_root rm -rf "/opt/${NVIM_PKG}"
  run_root tar xf /tmp/nvim.tar.gz -C /opt
  run_root ln -sf "/opt/${NVIM_PKG}/bin/nvim" /usr/local/bin/nvim
  rm -f /tmp/nvim.tar.gz
fi

# ─── btop ───────────────────────────────────────────────────────────

if ! has btop; then
  curl -fsSL "https://github.com/aristocratos/btop/releases/latest/download/btop-${BIN_ARCH}-unknown-linux-musl.tar.gz" \
    -o /tmp/btop.tar.gz
  tmpd=$(mktemp -d)
  (cd "$tmpd" && tar xf /tmp/btop.tar.gz && run_root cp btop/bin/btop /usr/local/bin/) && rm -rf "$tmpd"
  rm -f /tmp/btop.tar.gz
fi

# ─── lazygit ────────────────────────────────────────────────────────

if ! has lazygit; then
  tag=$(gh_latest_tag jesseduffield lazygit)
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${tag}_Linux_${LAZY_ARCH}.tar.gz" \
    -o /tmp/lazygit.tar.gz
  run_root tar xf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
  rm -f /tmp/lazygit.tar.gz
fi

# ─── lsd ────────────────────────────────────────────────────────────

if ! has lsd; then
  tag=$(gh_latest_tag lsd-rs lsd)
  curl -fsSL "https://github.com/lsd-rs/lsd/releases/latest/download/lsd-v${tag}-${BIN_ARCH}-unknown-linux-musl.tar.gz" \
    -o /tmp/lsd.tar.gz
  run_root tar xf /tmp/lsd.tar.gz -C /usr/local/bin --strip-components=1 "lsd-v${tag}-${BIN_ARCH}-unknown-linux-musl/lsd"
  rm -f /tmp/lsd.tar.gz
fi

# ─── carapace ───────────────────────────────────────────────────────

if ! has carapace; then
  tag=$(gh_latest_tag carapace-sh carapace-bin)
  curl -fsSL "https://github.com/carapace-sh/carapace-bin/releases/latest/download/carapace-bin_${tag}_linux_${GH_ARCH}.tar.gz" \
    -o /tmp/carapace.tar.gz
  run_root tar xf /tmp/carapace.tar.gz -C /usr/local/bin carapace
  rm -f /tmp/carapace.tar.gz
fi

# ─── starship ───────────────────────────────────────────────────────

# The dotfiles' starship.toml uses modules that need a current Starship.
# The distro package is usually older, so compare against the latest release.
STARSHIP_LATEST=$(gh_latest_tag starship starship)
if ! has starship || [ "$(starship --version | head -1 | awk '{print $2}')" != "$STARSHIP_LATEST" ]; then
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b /usr/local/bin
fi

# ─── btop ───────────────────────────────────────────────────────────

# The dotfiles' btop.conf is written for btop >= 1.4.6. The distro
# package can be much older and then throws "Cpu:: -> key not found".
BTOP_VER=$(btop --version 2>/dev/null | head -1 | tr -d '\033' | sed 's/\[[0-9;]*m//g' | awk '{print $NF}' | sed 's/+.*//')
if ! has btop || [ "$(printf '%s\n%s\n' 1.4.6 "$BTOP_VER" | sort -V | head -1)" != "1.4.6" ]; then
  curl -fsSL "https://github.com/aristocratos/btop/releases/latest/download/btop-${BIN_ARCH}-unknown-linux-musl.tar.gz" \
    -o /tmp/btop.tar.gz
  tmpd=$(mktemp -d)
  tar xf /tmp/btop.tar.gz -C "$tmpd"
  run_root install -m755 "$tmpd/btop/btop" /usr/local/bin/btop
  # Avoid an older package binary earlier in PATH shadowing the new one.
  [ -e /usr/bin/btop ] && run_root ln -sf /usr/local/bin/btop /usr/bin/btop
  rm -rf "$tmpd" /tmp/btop.tar.gz
fi

# ─── helix ──────────────────────────────────────────────────────────

if ! has hx; then
  tag=$(gh_latest_tag helix-editor helix)
  curl -fsSL "https://github.com/helix-editor/helix/releases/latest/download/helix-${tag}-${BIN_ARCH}-linux.tar.xz" \
    -o /tmp/helix.tar.xz
  run_root tar xf /tmp/helix.tar.xz -C /usr/local/bin --strip-components=1 "helix-${tag}-${BIN_ARCH}-linux/hx"
  rm -f /tmp/helix.tar.xz
fi

# ─── GitHub CLI ─────────────────────────────────────────────────────

if ! has gh; then
  if [ "$PM" = apt ]; then
    install_pkg gh
  else
    tag=$(gh_latest_tag cli cli)
    curl -fsSL "https://github.com/cli/cli/releases/latest/download/gh_${tag}_linux_${GH_ARCH}.tar.gz" \
      -o /tmp/gh.tar.gz
    run_root tar xf /tmp/gh.tar.gz -C /usr/local/bin --strip-components=2 "gh_${tag}_linux_${GH_ARCH}/bin/gh"
    rm -f /tmp/gh.tar.gz
  fi
fi

# ─── Node.js, C/C++ toolchain, clangd ──────────────────────────────

if ! has node || ! has clangd || ! has clang; then
  case "$PM" in
  apt) install_pkg nodejs npm clang clangd build-essential ;;
  apk) install_pkg nodejs npm clang clangd build-base ;;
  brew) install_pkg node llvm ;;
  dnf) install_pkg nodejs npm clang clang-tools-extra gcc gcc-c++ make ;;
  pacman) install_pkg nodejs npm clang gcc make ;;
  zypper) install_pkg nodejs npm clang gcc make ;;
  esac
fi

# ─── Grayscale ─────────────────────────────────────────────────────

if ! has gray; then
  GRAY_ARCH=amd64
  [ "$ARCH" = aarch64 ] && GRAY_ARCH=arm64
  curl -fsSL "https://github.com/grayscale-lang/Grayscale/releases/latest/download/gray-linux-${GRAY_ARCH}.tar.gz" \
    -o /tmp/gray.tar.gz
  tmpd=$(mktemp -d)
  (cd "$tmpd" && tar xf /tmp/gray.tar.gz && run_root install -m755 gray /usr/local/bin/gray) && rm -rf "$tmpd"
  rm -f /tmp/gray.tar.gz
fi

# ─── GrayLS (Node build used by the Neovim config) ─────────────────

if has node; then
  mkdir -p "$HOME/.local/share/grayls"
  curl -fsSL "https://github.com/grayscale-lang/grayls/releases/latest/download/server.js" \
    -o "$HOME/.local/share/grayls/server.js"
fi

# ─── Odin ──────────────────────────────────────────────────────────

if ! has odin; then
  tag=$(gh_latest_tag odin-lang Odin)
  ODIN_ARCH=amd64
  [ "$ARCH" = aarch64 ] && ODIN_ARCH=arm64
  ODIN_DIR="$HOME/.local/share/odin"
  curl -fsSL "https://github.com/odin-lang/Odin/releases/latest/download/odin-linux-${ODIN_ARCH}-${tag}.tar.gz" \
    -o /tmp/odin.tar.gz
  rm -rf "$ODIN_DIR"
  mkdir -p "$ODIN_DIR"
  tar xf /tmp/odin.tar.gz -C "$ODIN_DIR" --strip-components=1
  run_root ln -sf "$ODIN_DIR/odin" /usr/local/bin/odin
  rm -f /tmp/odin.tar.gz
fi

# ─── OLS (Odin Language Server) ────────────────────────────────────

if ! has ols; then
  case "$ARCH" in
  x86_64 | amd64) OLS_ARCH=x86_64 ;;
  aarch64 | arm64) OLS_ARCH=arm64 ;;
  *) OLS_ARCH="$BIN_ARCH" ;;
  esac
  OLS_DIR="$HOME/.local/share/ols"
  curl -fsSL "https://github.com/DanielGavin/ols/releases/latest/download/ols-${OLS_ARCH}-unknown-linux-gnu.zip" \
    -o /tmp/ols.zip
  rm -rf "$OLS_DIR"
  mkdir -p "$OLS_DIR"
  unzip -oq /tmp/ols.zip -d "$OLS_DIR"
  mv "$OLS_DIR/ols-${OLS_ARCH}-unknown-linux-gnu" "$OLS_DIR/ols"
  mv "$OLS_DIR/odinfmt-${OLS_ARCH}-unknown-linux-gnu" "$OLS_DIR/odinfmt"
  chmod +x "$OLS_DIR/ols" "$OLS_DIR/odinfmt"
  run_root ln -sf "$OLS_DIR/ols" /usr/local/bin/ols
  run_root ln -sf "$OLS_DIR/odinfmt" /usr/local/bin/odinfmt
  rm -f /tmp/ols.zip
fi

# ─── Go ─────────────────────────────────────────────────────────────

if ! has go; then
  if [ "$PM" = apt ]; then
    install_pkg golang-go
  else
    tag=$(curl -fsSL https://go.dev/VERSION?m=text | head -1)
    curl -fsSL "https://go.dev/dl/${tag}.linux-${GH_ARCH}.tar.gz" -o /tmp/go.tar.gz
    run_root tar xf /tmp/go.tar.gz -C /usr/local
    rm -f /tmp/go.tar.gz
  fi
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

# ─── Language servers (Node) ────────────────────────────────────────

if has npm; then
  has bash-language-server || npm install -g bash-language-server 2>/dev/null || true
  has fish-lsp || npm install -g fish-lsp 2>/dev/null || true
  has vtsls || npm install -g @vtsls/language-server typescript 2>/dev/null || true
  has vscode-css-language-server || npm install -g vscode-langservers-extracted 2>/dev/null || true
fi

# ─── tree-sitter CLI (needed to build Neovim parsers) ───────────────

if ! has tree-sitter; then
  case "$ARCH" in
  x86_64 | amd64) TS_ARCH=x64 ;;
  aarch64 | arm64) TS_ARCH=arm64 ;;
  *) TS_ARCH="$ARCH" ;;
  esac
  curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-${TS_ARCH}.gz" \
    -o /tmp/tree-sitter.gz
  gunzip -c /tmp/tree-sitter.gz > /tmp/tree-sitter-bin
  run_root install -m755 /tmp/tree-sitter-bin /usr/local/bin/tree-sitter
  rm -f /tmp/tree-sitter.gz /tmp/tree-sitter-bin
fi

# ─── lua-language-server ────────────────────────────────────────────

if ! has lua-language-server; then
  case "$ARCH" in
  x86_64 | amd64) LS_ARCH=x64 ;;
  aarch64 | arm64) LS_ARCH=arm64 ;;
  *) LS_ARCH="$ARCH" ;;
  esac
  tag=$(gh_latest_tag LuaLS/lua-language-server)
  curl -fsSL "https://github.com/LuaLS/lua-language-server/releases/download/${tag}/lua-language-server-${tag}-linux-${LS_ARCH}.tar.gz" \
    -o /tmp/luals.tar.gz
  run_root rm -rf /usr/local/share/lua-language-server
  run_root mkdir -p /usr/local/share/lua-language-server
  run_root tar xf /tmp/luals.tar.gz -C /usr/local/share/lua-language-server
  run_root ln -sf /usr/local/share/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server
  rm -f /tmp/luals.tar.gz
fi

# ─── markdown-oxide ─────────────────────────────────────────────────

if ! has markdown-oxide; then
  case "$ARCH" in
  x86_64 | amd64) MO_ARCH=x86_64 ;;
  aarch64 | arm64) MO_ARCH=aarch64 ;;
  *) MO_ARCH="$ARCH" ;;
  esac
  tag=$(gh_latest_tag Feel-ix-343/markdown-oxide)
  curl -fsSL "https://github.com/Feel-ix-343/markdown-oxide/releases/download/v${tag}/markdown-oxide-v${tag}-${MO_ARCH}-unknown-linux-gnu.tar.gz" \
    -o /tmp/markdown-oxide.tar.gz
  tmpd=$(mktemp -d)
  tar xf /tmp/markdown-oxide.tar.gz -C "$tmpd"
  run_root install -m755 "$(find "$tmpd" -type f -name markdown-oxide | head -1)" /usr/local/bin/markdown-oxide
  rm -rf "$tmpd" /tmp/markdown-oxide.tar.gz
fi

# ─── Chezmoi bootstrap ──────────────────────────────────────────────

if ! has chezmoi; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply "https://github.com/prjctimg/dotfiles.git"
else
  chezmoi init --apply "https://github.com/prjctimg/dotfiles.git"
fi
