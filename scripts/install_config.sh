#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
xdg_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
xdg_target="${xdg_config_home}/emacs"
legacy_target="$HOME/.emacs.d"

if [ -e "$xdg_target" ] || [ -L "$xdg_target" ]; then
  target="$xdg_target"
elif [ -e "$legacy_target" ] || [ -L "$legacy_target" ]; then
  target="$legacy_target"
else
  target="$xdg_target"
fi

backup_suffix="$(date +%Y%m%d-%H%M%S)"

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

require_cmd() {
  if ! have_cmd "$1"; then
    echo "Missing required dependency: $1" >&2
    exit 1
  fi
}

warn_cmd() {
  if ! have_cmd "$1"; then
    echo "Warning: optional dependency not found: $1" >&2
  fi
}

warn_langserver() {
  local name="$1"
  local hint="$2"
  if ! have_cmd "$name"; then
    echo "Warning: optional language server not found: $name" >&2
    if [ -n "$hint" ]; then
      echo "Hint: $hint" >&2
    fi
  fi
}

check_emacs_version() {
  local major
  major="$(emacs --batch --eval "(princ emacs-major-version)" 2>/dev/null || true)"
  if [ -z "$major" ]; then
    echo "Unable to determine Emacs version." >&2
    exit 1
  fi
  if [ "$major" -lt 29 ]; then
    echo "Emacs 29+ is required. Detected Emacs $major." >&2
    exit 1
  fi
}

check_dependencies() {
  require_cmd emacs
  check_emacs_version
  warn_cmd git
  warn_cmd rg
  if ! have_cmd fd && ! have_cmd fdfind; then
    echo "Warning: optional dependency not found: fd (or fdfind)" >&2
  fi
  warn_cmd sqlite3
  if ! have_cmd cc && ! have_cmd gcc && ! have_cmd clang; then
    echo "Warning: optional dependency not found: C compiler (cc/gcc/clang)" >&2
  fi
  warn_cmd sxiv
  warn_cmd mpv
  warn_langserver basedpyright-langserver "pipx install basedpyright or pip install basedpyright"
  warn_langserver vtsls "npm install -g @vtsls/language-server"
  warn_langserver lexical "mix archive.install hex lexical"
  warn_langserver gopls "go install golang.org/x/tools/gopls@latest"
  check_fonts
}

check_fonts() {
  if ! have_cmd fc-list; then
    echo "Warning: fontconfig (fc-list) not found; cannot verify fonts." >&2
    echo "Hint: install fontconfig via your package manager (e.g. apt, dnf, pacman)." >&2
    return
  fi

  local matcher_cmd
  if have_cmd rg; then
    matcher_cmd=(rg -q -i)
  else
    matcher_cmd=(grep -qiE)
  fi

  local mono_fonts="Fira Code Retina|Fira Code|JetBrains Mono|DejaVu Sans Mono|Monospace"
  local var_fonts="Ubuntu|Cantarell|Noto Sans|Sans"

  if ! fc-list | "${matcher_cmd[@]}" "$mono_fonts"; then
    echo "Warning: no preferred monospace font found." >&2
    echo "Hint: install one of: Fira Code, JetBrains Mono, or DejaVu Sans Mono." >&2
    echo "  Debian/Ubuntu: sudo apt install fonts-firacode fonts-jetbrains-mono fonts-dejavu-core" >&2
    echo "  Fedora: sudo dnf install fira-code-fonts jetbrains-mono-fonts dejavu-sans-mono-fonts" >&2
    echo "  Arch: sudo pacman -S ttf-fira-code ttf-jetbrains-mono ttf-dejavu" >&2
  fi

  if ! fc-list | "${matcher_cmd[@]}" "$var_fonts"; then
    echo "Warning: no preferred variable-pitch font found." >&2
    echo "Hint: install one of: Ubuntu, Cantarell, or Noto Sans." >&2
    echo "  Debian/Ubuntu: sudo apt install fonts-ubuntu fonts-cantarell fonts-noto-core" >&2
    echo "  Fedora: sudo dnf install ubuntu-fonts cantarell-fonts google-noto-sans-fonts" >&2
    echo "  Arch: sudo pacman -S ttf-ubuntu-font-family cantarell-fonts noto-fonts" >&2
  fi
}

resolve_path() {
  if command -v realpath >/dev/null 2>&1; then
    realpath "$1"
  elif command -v readlink >/dev/null 2>&1; then
    readlink -f "$1" 2>/dev/null || readlink "$1"
  else
    echo "$1"
  fi
}

is_this_config() {
  if [ -L "$target" ]; then
    local resolved
    resolved="$(resolve_path "$target")"
    if [ -n "$resolved" ] && [ "$resolved" = "$repo_root" ]; then
      return 0
    fi
  fi

  if [ -d "$target" ] && [ -f "$target/config.org" ] && [ -f "$target/early-init.el" ]; then
    if grep -q "^#\\+TITLE: DT's GNU Emacs Config" "$target/config.org"; then
      return 0
    fi
  fi

  return 1
}

maybe_tangle() {
  emacs --batch -l org --eval "(progn (require 'org) (org-babel-tangle-file \"${repo_root}/config.org\"))" >/dev/null
}

case "${1-}" in
  -h|--help)
    echo "Usage: $(basename "$0") [--check-deps]"
    exit 0
    ;;
  -c|--check-deps)
    check_dependencies
    echo "Dependency check complete."
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
esac

check_dependencies

if is_this_config; then
  echo "Detected existing emacs-conf config at $target"
  maybe_tangle
  exit 0
fi

if [ -e "$target" ] || [ -L "$target" ]; then
  backup_target="${target}.backup-${backup_suffix}"
  mv "$target" "$backup_target"
  echo "Backed up $target -> $backup_target"
fi

if [ -e "$HOME/.emacs" ]; then
  backup_emacs="${HOME}/.emacs.backup-${backup_suffix}"
  mv "$HOME/.emacs" "$backup_emacs"
  echo "Backed up $HOME/.emacs -> $backup_emacs"
fi

mkdir -p "$(dirname "$target")"
ln -s "$repo_root" "$target"
echo "Installed emacs-conf to $target -> $repo_root"

maybe_tangle
