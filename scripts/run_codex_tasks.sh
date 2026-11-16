#!/usr/bin/env bash
set -euo pipefail

TASK_FILE="tasks.md"
MODE="run"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --extract-tasks)
      MODE="extract"
      shift
      ;;
    --task-file)
      TASK_FILE="${2:-}"
      shift 2
      ;;
    *)
      TASK_FILE="$1"
      shift
      ;;
  esac
done

if [[ ! -f "$TASK_FILE" ]]; then
  echo "Task file not found: $TASK_FILE" >&2
  exit 1
fi

FULL_TASKS_CONTENT=$(cat "$TASK_FILE")

REVIEW_DIR="reviews"
mkdir -p "$REVIEW_DIR"

SEP='<<<TASK_SPLIT>>>'
TASKS_RAW=$(awk '
  BEGIN {in_task=0}
  {sub(/\r$/, "")}
  /^[[:space:]]*## \[ \] Task/ {
    if (in_task) {print block; print "'"$SEP"'"}
    in_task=1
    block=$0
    next
  }
  in_task {block = block ORS $0}
  END {if (in_task) print block}
' "$TASK_FILE")

if [[ "$MODE" == "extract" ]]; then
  printf "%s\n" "$TASKS_RAW"
  exit 0
fi

process_task() {
  local task_block="$1"
  local header
  local task_id
  local task_slug
  local review_file
  local impl_prompt
  local review_prompt
  local fix_prompt

  header=$(printf "%s" "$task_block" | head -n 1)
  task_id="unknown"
  if [[ "$header" =~ Task[[:space:]]+([0-9]+[A-Za-z]*) ]]; then
    task_id="${BASH_REMATCH[1]}"
  fi
  task_slug=$(printf "%s" "$task_id" | tr -c '[:alnum:]' '_' )

  review_file="$REVIEW_DIR/task_${task_slug}_review.md"

  impl_prompt=$(mktemp)
  review_prompt=$(mktemp)
  fix_prompt=$(mktemp)
  trap 'rm -f "$impl_prompt" "$review_prompt" "$fix_prompt"' RETURN

  echo "==> Implementing $header"
  cat > "$impl_prompt" <<CODEX_IMPL
You are working on a single task in a larger plan.

Full task file (for context only):
$FULL_TASKS_CONTENT

Current task:
$task_block

Rules:
- Execute only this task.
- Do not write a review.
- Keep changes minimal and aligned with existing conventions.
CODEX_IMPL
  codex exec --skip-git-repo-check - < "$impl_prompt"

  echo "==> Reviewing $header"
  cat > "$review_prompt" <<CODEX_REVIEW
You are a reviewer. Do NOT make code changes.

Full task file (for context only):
$FULL_TASKS_CONTENT

Current task:
$task_block

Write a review focused on bugs/risks/tests plus code style and cleanliness.
If you find issues, list them with file/line references and suggested fixes.
Write the review to:
$review_file
CODEX_REVIEW
  codex exec --skip-git-repo-check -o "$review_file" - < "$review_prompt"

  echo "==> Improving $header"
  cat > "$fix_prompt" <<CODEX_FIX
You are the improver. Apply fixes based on the review file.

Full task file (for context only):
$FULL_TASKS_CONTENT

Current task:
$task_block

Review file:
$review_file

Rules:
- Apply fixes if any issues are listed.
- Update code/tests/docs as needed.
- Do not overwrite the review file.
CODEX_FIX
  codex exec --skip-git-repo-check - < "$fix_prompt"

  if [[ "$task_id" != "unknown" ]]; then
    sed -i "0,/^## \\[ \\] Task ${task_id}:/s/^## \\[ \\] Task ${task_id}:/## [x] Task ${task_id}:/" "$TASK_FILE"
  fi
}

current=""
while IFS= read -r line; do
  if [[ "$line" == "$SEP" ]]; then
    if [[ -n "$current" ]]; then
      process_task "$current"
      current=""
    fi
  else
    current+="$line"$'\n'
  fi
done <<< "$TASKS_RAW"

if [[ -n "$current" ]]; then
  process_task "$current"
fi
