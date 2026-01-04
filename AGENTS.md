# Repository Guidelines

## Project Structure & Module Organization
- Root configuration lives in `early-init.el` and the literate config in `config.org` (tangles to `config.el`).
- Generated or supporting Lisp lives alongside in `.el` files.
- Supporting Emacs Lisp snippets are in `scripts/` and the custom theme in `themes/`.
- Org data files are in `OrgFiles/`; static assets are under `images/`.

## Build, Test, and Development Commands
- `emacs --init-directory .` loads this repository as the Emacs config for local testing.
- `emacs --debug-init --init-directory .` starts with backtraces to troubleshoot startup errors.
- `bash create_virtual_env.sh` creates a Python LSP venv for editor tooling (optional).

## Coding Style & Naming Conventions
- Emacs Lisp uses 2-space indentation; keep forms idiomatic and rely on `TAB`/`indent-region`.
- Prefer kebab-case for function/variable names (e.g., `my/feature-toggle` or `dt/enable-foo`).
- Keep related settings grouped in the Org files; add brief section headings when expanding config.

## Testing Guidelines
- There is no automated test suite. Validate changes by launching Emacs and exercising affected features.
- For UI or startup changes, validate both GUI and terminal startup paths.

## Commit & Pull Request Guidelines
- Commit messages are short, imperative, and sentence case (e.g., "Include Undo Tree", "Fix vterm error in config").
- PRs should include a concise summary, testing notes (manual steps are fine), and screenshots for UI changes.
- Call out machine-specific paths or OS assumptions in the description to ease review.

## Configuration Tips
- Avoid committing personal credentials or machine-specific absolute paths.
- Prefer adding new packages via the existing init/config flow rather than ad-hoc `load-file` calls.
