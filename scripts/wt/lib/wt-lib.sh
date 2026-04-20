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

# Print all running docker compose stacks as TSV: "<project_dir>\t<first_config_file>".
# project_dir is the dirname of the first config file.
# Emits nothing if Docker is unavailable.
list_running_stacks_tsv() {
  docker compose ls --format json 2>/dev/null \
    | jq -r '.[] | [(.ConfigFiles|split(",")[0]|split("/")[:-1]|join("/")), (.ConfigFiles|split(",")[0])] | @tsv' 2>/dev/null
}

# Given a worktree paths file and a running stacks TSV file,
# echo "<worktree_path>\t<config_file>" for stacks whose project_dir matches
# one of the worktree paths.
match_running_in_worktrees() {
  awk -F'\t' '
    NR==FNR { wt[$1]=1; next }
    ($1 in wt) { print $1 "\t" $2 }
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

# Find the running stack (if any) whose project_dir is within the current repo's worktree set.
# Input: cwd. Output: "<worktree_path>\t<config_file>" on stdout (single line), or nothing.
find_running_stack_for_repo() {
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

  match_running_in_worktrees "$wt_file" "$stacks_file" | head -n 1

  rm -f "$wt_file" "$stacks_file"
  trap - EXIT
}
