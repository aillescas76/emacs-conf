#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${SRC_DIR:-$ROOT_DIR/sources}"
PREFIX="${PREFIX:-$HOME/.local}"
TREE_SITTER_TAG="${TREE_SITTER_TAG:-v0.24.7}"
EMACS_TAG="${EMACS_TAG:-emacs-29.4}"
TREE_SITTER_VERSION="${TREE_SITTER_TAG#v}"

mkdir -p "$SRC_DIR"

echo "Source dir: $SRC_DIR"
echo "Install prefix: $PREFIX"
echo "tree-sitter tag: $TREE_SITTER_TAG"
echo "Emacs tag: $EMACS_TAG"

export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

if command -v tree-sitter >/dev/null 2>&1; then
  existing_cli="$(command -v tree-sitter)"
  existing_ver="$(tree-sitter --version | awk '{print $2}')"
  if [ "$existing_ver" != "$TREE_SITTER_VERSION" ]; then
    if [ -w "$existing_cli" ]; then
      echo "Removing mismatched tree-sitter CLI at $existing_cli (found $existing_ver)."
      rm -f "$existing_cli"
    else
      echo "Found tree-sitter CLI at $existing_cli (version $existing_ver)."
      echo "Please remove it or ensure $PREFIX/bin is first on PATH."
      exit 1
    fi
  fi
fi

if [ ! -d "$SRC_DIR/tree-sitter/.git" ]; then
  git clone https://github.com/tree-sitter/tree-sitter.git "$SRC_DIR/tree-sitter"
fi

(
  cd "$SRC_DIR/tree-sitter"
  git fetch --tags
  git checkout "$TREE_SITTER_TAG"
  make -j"$(nproc)"
  make install PREFIX="$PREFIX"
)

if ! command -v cargo >/dev/null 2>&1; then
  echo "cargo not found; install rustc/cargo to build tree-sitter CLI."
  exit 1
fi

(
  cd "$SRC_DIR/tree-sitter"
  cargo install --path cli --locked --root "$PREFIX"
)

installed_cli="$PREFIX/bin/tree-sitter"
if [ ! -x "$installed_cli" ]; then
  echo "tree-sitter CLI not found at $installed_cli after install."
  exit 1
fi

installed_ver="$("$installed_cli" --version | awk '{print $2}')"
if [ "$installed_ver" != "$TREE_SITTER_VERSION" ]; then
  echo "tree-sitter CLI version mismatch: expected $TREE_SITTER_VERSION, got $installed_ver."
  exit 1
fi

pkg_ver="$(PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}" pkg-config --modversion tree-sitter)"
if [ "$pkg_ver" != "$TREE_SITTER_VERSION" ]; then
  echo "tree-sitter pkg-config version mismatch: expected $TREE_SITTER_VERSION, got $pkg_ver."
  exit 1
fi

if [ ! -d "$SRC_DIR/emacs/.git" ]; then
  git clone https://git.savannah.gnu.org/git/emacs.git "$SRC_DIR/emacs"
fi

(
  cd "$SRC_DIR/emacs"
  git fetch --tags
  git checkout "$EMACS_TAG"
  ./autogen.sh
  ./configure --prefix="$PREFIX" --with-tree-sitter
  make -j"$(nproc)"
  make install
)

echo "Done. Ensure $PREFIX/bin is on your PATH."
