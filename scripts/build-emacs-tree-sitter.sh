#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${SRC_DIR:-$ROOT_DIR/sources}"
PREFIX="${PREFIX:-$HOME/.local}"
TREE_SITTER_TAG="${TREE_SITTER_TAG:-v0.24.7}"
EMACS_TAG="${EMACS_TAG:-emacs-30.2}"
TREE_SITTER_VERSION="${TREE_SITTER_TAG#v}"
BUILD_TREE_SITTER_CLI="${BUILD_TREE_SITTER_CLI:-0}"

mkdir -p "$SRC_DIR"

echo "Source dir: $SRC_DIR"
echo "Install prefix: $PREFIX"
echo "tree-sitter tag: $TREE_SITTER_TAG"
echo "Emacs tag: $EMACS_TAG"
echo "Build tree-sitter CLI: $BUILD_TREE_SITTER_CLI"

export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

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

if [ "$BUILD_TREE_SITTER_CLI" = "1" ]; then
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

  if ! command -v cargo >/dev/null 2>&1; then
    echo "cargo not found; install rustc/cargo to build tree-sitter CLI."
    exit 1
  fi

  version_lt() {
    local a="$1"
    local b="$2"
    [ "$(printf '%s\n' "$a" "$b" | sort -V | head -n1)" = "$a" ] && [ "$a" != "$b" ]
  }

  rustc_ver="$(rustc --version | awk '{print $2}')"
  if version_lt "$rustc_ver" "1.76.0"; then
    echo "rustc $rustc_ver is older than 1.76.0; upgrade rustc to build tree-sitter CLI."
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
else
  echo "Skipping tree-sitter CLI build."
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
  CPPFLAGS="-I$PREFIX/include ${CPPFLAGS:-}" \
  LDFLAGS="-L$PREFIX/lib -Wl,-rpath,$PREFIX/lib ${LDFLAGS:-}" \
  ./configure --prefix="$PREFIX" --with-tree-sitter
  make clean
  make bootstrap
  make -j"$(nproc)"
  make install
)

echo "Done. Ensure $PREFIX/bin is on your PATH."
