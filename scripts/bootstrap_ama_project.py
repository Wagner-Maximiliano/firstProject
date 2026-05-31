#!/usr/bin/env python3
"""Bootstrap AMA support files into a target repository.

This helper is intentionally lightweight and safe for existing repositories.
It copies the small project-local AMA files into the target repo without
copying the framework itself.

Examples:
  python3 scripts/bootstrap_ama_project.py --repo /path/to/repo --mode existing
  python3 scripts/bootstrap_ama_project.py --repo . --mode new --force
"""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

TEMPLATE_ROOT = Path(__file__).resolve().parents[1] / "templates" / "project-ama"
DEFAULT_FILES = [
    ".ama/PROJECT_BRIEF.md",
    ".ama/STATE.md",
    ".ama/config.yaml",
    ".github/ama-labels.json",
    ".github/ISSUE_TEMPLATE/ama-task.yml",
    ".github/PULL_REQUEST_TEMPLATE.md",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Bootstrap AMA support files into a project repo")
    parser.add_argument("--repo", required=True, help="Path to the target git repository")
    parser.add_argument(
        "--mode",
        choices=["new", "existing"],
        default="existing",
        help="Whether AMA is being added to a new or existing repository",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite existing AMA-managed files if they already exist",
    )
    return parser.parse_args()


def ensure_git_repo(repo: Path) -> None:
    if not repo.exists():
        raise SystemExit(f"Target repo does not exist: {repo}")
    if not (repo / ".git").exists():
        raise SystemExit(f"Target path is not a git repository: {repo}")


def copy_file(src: Path, dst: Path, force: bool) -> str:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists() and not force:
        return f"skip  {dst}"
    shutil.copy2(src, dst)
    return f"write {dst}"


def stamp_mode(repo: Path, mode: str) -> None:
    config_path = repo / ".ama" / "config.yaml"
    if not config_path.exists():
        return
    content = config_path.read_text(encoding="utf-8")
    content = content.replace("repo_mode: existing", f"repo_mode: {mode}")
    config_path.write_text(content, encoding="utf-8")


def main() -> None:
    args = parse_args()
    repo = Path(args.repo).resolve()
    ensure_git_repo(repo)

    if not TEMPLATE_ROOT.exists():
        raise SystemExit(f"Template root missing: {TEMPLATE_ROOT}")

    results = []
    for rel in DEFAULT_FILES:
        src = TEMPLATE_ROOT / rel
        dst = repo / rel
        results.append(copy_file(src, dst, args.force))

    stamp_mode(repo, args.mode)

    print("AMA bootstrap complete")
    print(f"Target repo: {repo}")
    print(f"Mode: {args.mode}")
    print("Files:")
    for line in results:
        print(f"- {line}")
    print("Next steps:")
    print("- Fill in .ama/PROJECT_BRIEF.md")
    print("- Review .ama/config.yaml")
    print("- Apply .github/ama-labels.json to GitHub with scripts/bootstrap_github_labels.py")
    print("- Start planning with the AMA planner profile")


if __name__ == "__main__":
    main()
