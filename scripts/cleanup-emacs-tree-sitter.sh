#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: cleanup-emacs-tree-sitter.sh [--apply] [--prefix PATH] [--only emacs|tree-sitter] [--packages] [--package-dir PATH]

Removes Emacs and tree-sitter artifacts under a system prefix (default: /usr/local).
By default it prints what would be removed. Use --apply to delete.
With --packages, also removes ELPA and native compilation caches.
EOF
}

prefix="/usr/local"
apply=0
only=""
packages=0
package_dirs=()

while [ $# -gt 0 ]; do
  case "$1" in
    --apply)
      apply=1
      ;;
    --prefix)
      shift
      prefix="${1:-}"
      if [ -z "$prefix" ]; then
        echo "Missing value for --prefix." >&2
        exit 1
      fi
      ;;
    --only)
      shift
      only="${1:-}"
      if [ "$only" != "emacs" ] && [ "$only" != "tree-sitter" ]; then
        echo "Invalid value for --only: $only" >&2
        exit 1
      fi
      ;;
    --packages)
      packages=1
      ;;
    --package-dir)
      shift
      if [ -z "${1:-}" ]; then
        echo "Missing value for --package-dir." >&2
        exit 1
      fi
      package_dirs+=("$1")
      packages=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

lib_dirs=("$prefix/lib" "$prefix/lib64")

shopt -s nullglob
targets=()

should_include() {
  local kind="$1"
  if [ -z "$only" ] || [ "$only" = "$kind" ]; then
    return 0
  fi
  return 1
}

add_if_exists() {
  local path="$1"
  if [ -e "$path" ]; then
    targets+=("$path")
  fi
}

emacs_match() {
  local path="$1"
  if [ ! -x "$path" ]; then
    return 1
  fi
  "$path" --version 2>/dev/null | grep -qi "Emacs"
}

if should_include "tree-sitter"; then
  add_if_exists "$prefix/bin/tree-sitter"
  add_if_exists "$prefix/include/tree_sitter"
  for lib_dir in "${lib_dirs[@]}"; do
    for lib_file in "$lib_dir"/libtree-sitter.*; do
      targets+=("$lib_file")
    done
    add_if_exists "$lib_dir/pkgconfig/tree-sitter.pc"
    add_if_exists "$lib_dir/cmake/tree-sitter"
    add_if_exists "$lib_dir/cmake/TreeSitter"
  done
fi

if should_include "emacs"; then
  add_if_exists "$prefix/bin/emacs"
  add_if_exists "$prefix/bin/emacsclient"
  add_if_exists "$prefix/share/emacs"
  add_if_exists "$prefix/libexec/emacs"
  add_if_exists "$prefix/share/man/man1/emacs.1"
  add_if_exists "$prefix/share/man/man1/emacsclient.1"
  add_if_exists "$prefix/share/info/emacs"
  add_if_exists "$prefix/share/info/emacs-*"
  add_if_exists "$prefix/share/applications/emacs.desktop"
  add_if_exists "$prefix/share/icons/hicolor/128x128/apps/emacs.png"
  add_if_exists "$prefix/share/icons/hicolor/48x48/apps/emacs.png"
  add_if_exists "$prefix/share/icons/hicolor/32x32/apps/emacs.png"
  add_if_exists "$prefix/share/icons/hicolor/24x24/apps/emacs.png"
  add_if_exists "$prefix/share/icons/hicolor/16x16/apps/emacs.png"
  if emacs_match "$prefix/bin/ctags"; then
    targets+=("$prefix/bin/ctags")
  fi
  if emacs_match "$prefix/bin/etags"; then
    targets+=("$prefix/bin/etags")
  fi
fi

if [ "$packages" -eq 1 ]; then
  xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  xdg_cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
  default_package_dirs=(
    "$xdg_config_home/emacs/elpa"
    "$xdg_config_home/emacs/eln-cache"
    "$xdg_cache_home/emacs/eln-cache"
    "$HOME/.emacs.d/elpa"
    "$HOME/.emacs.d/eln-cache"
  )
  for dir in "${default_package_dirs[@]}"; do
    add_if_exists "$dir"
  done
  for dir in "${package_dirs[@]}"; do
    add_if_exists "$dir"
  done
fi

if [ "${#targets[@]}" -eq 0 ]; then
  echo "No matching artifacts found under $prefix."
  exit 0
fi

echo "Artifacts under $prefix:"
printf '  %s\n' "${targets[@]}"

if [ "$apply" -eq 0 ]; then
  echo "Dry run only. Re-run with --apply to remove."
  exit 0
fi

for target in "${targets[@]}"; do
  target_parent="$(dirname "$target")"
  if [ -w "$target_parent" ]; then
    rm -rf "$target"
    continue
  fi
  if command -v sudo >/dev/null 2>&1; then
    sudo rm -rf "$target"
  else
    echo "Need write access to remove $target or sudo." >&2
    exit 1
  fi
done

echo "Removal complete."
