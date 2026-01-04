# emacs-conf

Personal Emacs configuration with a mix of standard `.el` files and literate Org config. This repo is intended to be used as an Emacs `--init-directory` so it can be tested without touching a global setup.

## Requirements
- Emacs 27+ (newer is fine)
- Optional: Python 3 for LSP tooling

## Quick start
```bash
# Run Emacs using this repo as the init directory
emacs --init-directory .

# Debug startup issues with backtraces
emacs --debug-init --init-directory .
```

## Optional Python LSP environment
```bash
bash create_virtual_env.sh
```
This creates a local `venv/` and installs `python-lsp-server` and `ruff-lsp` for editor integration.

## Project layout
- `early-init.el`: early startup tweaks.
- `config.org`, `config.el`: literate configuration and tangled output.
- `scripts/`: small Emacs Lisp utilities and examples.
- `themes/`: custom theme(s).
- `OrgFiles/`: Org data (tasks, habits, etc.).
- `images/`: static assets.

## Notes
- Prefer adding new config in the Org files to keep related settings grouped.
- Keep machine-specific paths or secrets out of version control.
