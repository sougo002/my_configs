#!/bin/sh
# Shared helpers for worktree-aware docker compose tooling (`wt`).

# Echo the absolute path of each worktree for the repo containing $1.
# Emits nothing (exit 0) if $1 is not inside a git repo.
list_worktree_paths() {
  dir=$1
  [ -d "$dir" ] || return 0
  git -C "$dir" --no-optional-locks worktree list --porcelain 2>/dev/null \
    | awk '/^worktree /{print substr($0, 10)}'
}

# Print all running docker compose stacks as TSV:
# "<project_dir>\t<first_config_file>\t<project_name>".
# project_dir is the dirname of the first config file.
# project_name is the actual COMPOSE_PROJECT_NAME the stack was started with —
# required to target the stack with `docker compose -p`, since cwd-derived
# defaults silently mismatch when the stack was started with `-p NAME`.
# Emits nothing if Docker is unavailable.
list_running_stacks_tsv() {
  docker compose ls --format json 2>/dev/null \
    | jq -r '.[] | [(.ConfigFiles|split(",")[0]|split("/")[:-1]|join("/")), (.ConfigFiles|split(",")[0]), .Name] | @tsv' 2>/dev/null
}

# Given a worktree paths file and a running stacks TSV file,
# echo "<worktree_path>\t<config_file>\t<project_name>" for stacks whose
# project_dir matches one of the worktree paths.
match_running_in_worktrees() {
  awk -F'\t' '
    NR==FNR { wt[$1]=1; next }
    ($1 in wt) { print $1 "\t" $2 "\t" $3 }
  ' "$1" "$2"
}

# Echo current branch (or short SHA if detached) for the worktree at $1.
resolve_branch_of_path() {
  path=$1
  [ -d "$path" ] || return 0
  branch=$(git -C "$path" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ "$branch" = "HEAD" ]; then
    git -C "$path" --no-optional-locks rev-parse --short HEAD 2>/dev/null
  else
    printf '%s' "$branch"
  fi
}

# Find all running stacks whose project_dir is within the current repo's worktree set.
# Input: cwd. Output: zero or more lines of "<worktree_path>\t<config_file>\t<project_name>".
find_running_stacks_for_repo() {
  cwd=$1
  wt_file=$(mktemp -t wt-wt.XXXXXX) || return 1
  stacks_file=$(mktemp -t wt-stacks.XXXXXX) || { rm -f "$wt_file"; return 1; }
  trap 'rm -f "$wt_file" "$stacks_file"' EXIT

  list_worktree_paths "$cwd" > "$wt_file"
  list_running_stacks_tsv > "$stacks_file"

  if [ ! -s "$wt_file" ] || [ ! -s "$stacks_file" ]; then
    rm -f "$wt_file" "$stacks_file"
    trap - EXIT
    return 0
  fi

  match_running_in_worktrees "$wt_file" "$stacks_file"

  rm -f "$wt_file" "$stacks_file"
  trap - EXIT
}

# Echo a default COMPOSE_PROJECT_NAME for the given path, combining the repo
# name and the worktree directory name so that worktrees with the same basename
# across different repos (e.g. my-app-algo/.claude/worktrees/feat-x vs
# my-app-ai-widget/.claude/worktrees/feat-x) do not collide.
#
# Format:
#   <repo-basename>-<cwd-basename>   when cwd is a non-main worktree
#   <repo-basename>                  when cwd is the main worktree
#   <cwd-basename>                   when cwd is not inside a git repo
#
# The result is lowercased and non-[a-z0-9_-] chars are folded to '-' to satisfy
# docker compose project-name constraints.
compute_default_project_name() {
  cwd=$1
  main_worktree=$(git -C "$cwd" --no-optional-locks worktree list --porcelain 2>/dev/null \
    | awk '/^worktree /{print substr($0, 10); exit}')
  cwd_abs=$(cd "$cwd" 2>/dev/null && pwd) || cwd_abs=$cwd
  if [ -z "$main_worktree" ]; then
    raw=$(basename "$cwd_abs")
  else
    repo_name=$(basename "$main_worktree")
    if [ "$cwd_abs" = "$main_worktree" ]; then
      raw=$repo_name
    else
      raw="${repo_name}-$(basename "$cwd_abs")"
    fi
  fi
  printf '%s' "$raw" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9_-]/-/g'
}

# Echo PIDs of running `docker compose watch` (or its plugin binary) whose
# current working directory matches the given path. One PID per line.
# Empty if none found. macOS-compatible (uses lsof for cwd lookup).
list_compose_watch_pids_in_cwd() {
  target=$1
  pgrep -f 'compose watch' 2>/dev/null | while IFS= read -r pid; do
    [ -n "$pid" ] || continue
    pcwd=$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | awk '/^n/{print substr($0, 2); exit}')
    if [ "$pcwd" = "$target" ]; then
      printf '%s\n' "$pid"
    fi
  done
  return 0
}
