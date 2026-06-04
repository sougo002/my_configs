#!/bin/sh
# Unit tests for scripts/wt/lib/wt-lib.sh.
#
# POSIX sh, no test framework. Only needs `git` and `jq` — the same tools the
# `wt` commands themselves depend on. Run directly:
#
#   sh scripts/wt/test/run.sh
#
# Strategy:
#   - Logic functions are exercised against throwaway git repos created under a
#     temp dir (cleaned up on exit). Paths are always derived from what git
#     itself reports, so symlinked temp dirs (e.g. macOS /var -> /private/var)
#     don't cause spurious mismatches.
#   - Docker access is isolated behind `_list_stacks_tsv` / a stubbed `docker`,
#     so nothing real is ever started or stopped.
#
# `list_compose_watch_pids_in_cwd` (lsof/pgrep) is intentionally not covered —
# it has no pure logic worth the mocking cost.

set -u

HERE=$(cd "$(dirname "$0")" && pwd)
LIB="$HERE/../lib/wt-lib.sh"
. "$LIB"

TAB=$(printf '\t')

TMP=$(mktemp -d "${TMPDIR:-/tmp}/wt-test.XXXXXX") || exit 1
trap 'rm -rf "$TMP"' EXIT INT TERM

# Results are appended to a file rather than counter variables, because each
# test group runs in a subshell (for function-override / cwd isolation) and
# variable mutations there would not propagate back to this shell — which would
# silently swallow failures.
RESULTS="$TMP/results"
: > "$RESULTS"

ok()  { printf 'p\n' >> "$RESULTS"; printf '  ok   - %s\n' "$1"; }
bad() { printf 'f\n' >> "$RESULTS"; printf '  FAIL - %s\n         want: [%s]\n         got:  [%s]\n' "$1" "$3" "$2"; }
eq()  { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "$2" "$3"; fi; }

# Create a throwaway git repo with one commit; echo the path git reports for it
# (its canonical "main worktree" path).
new_repo() {
  d="$TMP/$1"
  mkdir -p "$d"
  git -C "$d" init -q
  git -C "$d" -c user.email=t@example.com -c user.name=test commit -q --allow-empty -m init
  git -C "$d" worktree list --porcelain | awk '/^worktree /{print substr($0, 10); exit}'
}

# ---------------------------------------------------------------------------
echo "match_running_in_worktrees:"
(
  wt="$TMP/wt.txt"
  st="$TMP/st.txt"
  printf '%s\n' /a /b > "$wt"
  printf '%s\n' \
    "/a${TAB}/a/dc.yml${TAB}proj-a" \
    "/c${TAB}/c/dc.yml${TAB}proj-c" \
    "/b${TAB}/b/dc.yml${TAB}proj-b" > "$st"
  out=$(match_running_in_worktrees "$wt" "$st")
  exp=$(printf '/a%s/a/dc.yml%sproj-a\n/b%s/b/dc.yml%sproj-b' "$TAB" "$TAB" "$TAB" "$TAB")
  eq "keeps only stacks whose dir is a worktree" "$out" "$exp"
)

# ---------------------------------------------------------------------------
echo "compute_default_project_name:"
(
  repo=$(new_repo cdpn)
  eq "main worktree -> repo basename" \
    "$(compute_default_project_name "$repo")" "$(basename "$repo")"

  git -C "$repo" worktree add -q "$repo/.claude/worktrees/Feat+X" -b wt-x >/dev/null 2>&1
  eq "sub worktree -> repo-cwd, lowercased & folded" \
    "$(compute_default_project_name "$repo/.claude/worktrees/Feat+X")" \
    "$(basename "$repo")-feat-x"

  mkdir -p "$TMP/plain/My Dir"
  eq "non-git -> cwd basename, folded" \
    "$(compute_default_project_name "$TMP/plain/My Dir")" "my-dir"
)

# ---------------------------------------------------------------------------
echo "resolve_branch_of_path:"
(
  repo=$(new_repo rbop)
  cur=$(git -C "$repo" rev-parse --abbrev-ref HEAD)
  eq "returns current branch" "$(resolve_branch_of_path "$repo")" "$cur"

  sha=$(git -C "$repo" rev-parse --short HEAD)
  git -C "$repo" checkout -q --detach HEAD
  eq "detached HEAD -> short sha" "$(resolve_branch_of_path "$repo")" "$sha"

  eq "missing dir -> empty" "$(resolve_branch_of_path "$TMP/does-not-exist")" ""
)

# ---------------------------------------------------------------------------
echo "list_worktree_paths:"
(
  repo=$(new_repo lwp)
  git -C "$repo" worktree add -q "$repo/.claude/worktrees/w1" -b w1 >/dev/null 2>&1
  git -C "$repo" worktree add -q "$repo/.claude/worktrees/w2" -b w2 >/dev/null 2>&1
  n=$(list_worktree_paths "$repo" | wc -l | tr -d ' ')
  eq "lists main + added worktrees" "$n" "3"
  has=$(list_worktree_paths "$repo" | grep -c '/w1$')
  eq "includes an added worktree path" "$has" "1"

  eq "non-git dir -> empty" "$(list_worktree_paths "$TMP/nowhere")" ""
)

# ---------------------------------------------------------------------------
echo "_list_stacks_tsv (docker/jq isolated):"
if command -v jq >/dev/null 2>&1; then
  (
    docker() {
      printf '%s\n' "$*" > "$TMP/docker.args"
      cat <<'JSON'
[{"Name":"projx","Status":"running(2)","ConfigFiles":"/repo/wt/x/docker-compose.yml,/repo/wt/x/override.yml"}]
JSON
    }
    out=$(_list_stacks_tsv "")
    exp=$(printf '/repo/wt/x%s/repo/wt/x/docker-compose.yml%sprojx%srunning(2)' "$TAB" "$TAB" "$TAB")
    eq "derives dir, first config, name, status" "$out" "$exp"

    _list_stacks_tsv "--all" > /dev/null
    case "$(cat "$TMP/docker.args")" in
      *--all*) ok "passes --all through to docker compose ls" ;;
      *)       bad "passes --all through to docker compose ls" "$(cat "$TMP/docker.args")" "...--all..." ;;
    esac
  )
else
  printf '  skip - jq not installed\n'
fi

# ---------------------------------------------------------------------------
echo "find_running_stacks_for_repo:"
(
  repo=$(new_repo frsr)
  git -C "$repo" worktree add -q "$repo/.claude/worktrees/w1" -b w1 >/dev/null 2>&1
  w1=$(list_worktree_paths "$repo" | grep '/w1$')

  # Stub the docker-backed lister: one stack in-repo, one elsewhere.
  list_running_stacks_tsv() {
    printf '%s\n' \
      "$w1${TAB}$w1/dc.yml${TAB}proj-w1" \
      "/elsewhere/repo${TAB}/elsewhere/repo/dc.yml${TAB}proj-other"
  }
  out=$(find_running_stacks_for_repo "$repo")
  eq "matches only stacks inside this repo's worktrees" \
    "$out" "$w1${TAB}$w1/dc.yml${TAB}proj-w1"
)

# ---------------------------------------------------------------------------
echo "find_orphan_stacks_for_repo:"
(
  repo=$(new_repo fosr)
  base="$repo/.claude/worktrees"

  # A registered worktree whose directory we then delete (git keeps it listed
  # as prunable) -> orphan via the registered-path branch.
  git -C "$repo" worktree add -q "$base/registered-gone" -b regone >/dev/null 2>&1
  reg=$(list_worktree_paths "$repo" | grep '/registered-gone$')
  rm -rf "$reg"

  # A worktree under the base that git no longer knows about -> orphan via the
  # path-prefix branch.
  gone="$base/base-gone"

  # A worktree that still exists on disk -> NOT an orphan.
  alive="$base/alive"
  mkdir -p "$alive"

  # A stack belonging to some other repo -> NOT an orphan.
  other="/somewhere/other-repo/wt/x"

  _list_stacks_tsv() {
    printf '%s\n' \
      "$gone${TAB}$gone/dc.yml${TAB}proj-base-gone${TAB}running(2)" \
      "$reg${TAB}$reg/dc.yml${TAB}proj-registered-gone${TAB}created(3)" \
      "$alive${TAB}$alive/dc.yml${TAB}proj-alive${TAB}running(1)" \
      "$other${TAB}$other/dc.yml${TAB}proj-other-repo${TAB}running(1)"
  }

  out=$(find_orphan_stacks_for_repo "$repo" | sort)
  exp=$(printf 'proj-base-gone%srunning(2)%s%s\nproj-registered-gone%screated(3)%s%s' \
    "$TAB" "$TAB" "$gone" "$TAB" "$TAB" "$reg" | sort)
  eq "detects missing dirs (registered + under base), excludes alive & other repo" \
    "$out" "$exp"
)

# ---------------------------------------------------------------------------
echo
pass=$(grep -c '^p' "$RESULTS")
fail=$(grep -c '^f' "$RESULTS")
printf 'passed: %s  failed: %s\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
