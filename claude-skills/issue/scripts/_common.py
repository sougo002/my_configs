"""issue 操作 script の共通ユーティリティ。

repo の検証、gh コマンドの subprocess 実行、GraphQL 実行、本文(file/stdin)の取得を提供する。
リポジトリ非依存。owner / project などの既定値は持たない（呼び出し側が渡す）。
"""

import json
import re
import subprocess
import sys

_REPO_RE = re.compile(r"^[\w.-]+/[\w.-]+$")


def validate_repo(repo: str) -> str:
    """`owner/repo` 形式を検証して返す。"""
    if not _REPO_RE.match(repo):
        raise SystemExit(f"--repo は OWNER/REPO 形式で指定してください: {repo!r}")
    return repo


def run_gh(args: list[str]) -> str:
    """gh コマンドを実行し stdout を返す。失敗時は stderr を出して終了。"""
    result = subprocess.run(["gh", *args], capture_output=True, text=True)
    if result.returncode != 0:
        sys.stderr.write(result.stderr)
        raise SystemExit(result.returncode or 1)
    return result.stdout


def graphql(query: str) -> dict:
    """gh api graphql を叩いてパース済み JSON(dict) を返す。"""
    return json.loads(run_gh(["api", "graphql", "-f", f"query={query}"]))


def read_body(args) -> str | None:
    """--body-file または stdin から本文を読む。どちらも無ければ None。"""
    if getattr(args, "body_file", None):
        with open(args.body_file) as f:
            return f.read()
    if not sys.stdin.isatty():
        data = sys.stdin.read()
        return data if data.strip() else None
    return None


def add_to_project(owner: str, project_number: str, urls: list[str]) -> None:
    """issue URL を GitHub Project に追加する（冪等）。"""
    for url in urls:
        run_gh(["project", "item-add", str(project_number), "--owner", owner, "--url", url])
