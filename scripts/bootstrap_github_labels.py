#!/usr/bin/env python3
"""Create or update AMA labels in a GitHub repository via the REST API.

Examples:
  export GITHUB_TOKEN=...
  python3 scripts/bootstrap_github_labels.py --repo owner/name
  python3 scripts/bootstrap_github_labels.py --repo owner/name --labels path/to/ama-labels.json
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

DEFAULT_LABELS = Path(__file__).resolve().parents[1] / "templates" / "project-ama" / ".github" / "ama-labels.json"
API_BASE = "https://api.github.com"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create or update AMA labels in GitHub")
    parser.add_argument("--repo", required=True, help="GitHub repository in owner/name form")
    parser.add_argument("--labels", default=str(DEFAULT_LABELS), help="Path to label JSON file")
    parser.add_argument("--token", default=os.environ.get("GITHUB_TOKEN", ""), help="GitHub token (defaults to GITHUB_TOKEN)")
    return parser.parse_args()


def request(method: str, url: str, token: str, data: dict | None = None) -> tuple[int, str]:
    body = None if data is None else json.dumps(data).encode("utf-8")
    req = urllib.request.Request(url, data=body, method=method)
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("X-GitHub-Api-Version", "2022-11-28")
    if body is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req) as response:
            return response.status, response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read().decode("utf-8")


def main() -> None:
    args = parse_args()
    if not args.token:
        raise SystemExit("Missing GitHub token. Set GITHUB_TOKEN or pass --token.")

    labels_path = Path(args.labels).resolve()
    labels = json.loads(labels_path.read_text(encoding="utf-8"))

    owner, repo = args.repo.split("/", 1)
    endpoint = f"{API_BASE}/repos/{owner}/{repo}/labels"

    created = 0
    updated = 0
    for label in labels:
        status, _ = request("POST", endpoint, args.token, label)
        if status == 201:
            created += 1
            print(f"created {label['name']}")
            continue
        if status == 422:
            patch_url = f"{endpoint}/{urllib.parse.quote(label['name'], safe='')}"
            status, response = request("PATCH", patch_url, args.token, label)
            if status == 200:
                updated += 1
                print(f"updated {label['name']}")
                continue
            print(f"failed  {label['name']} -> {status} {response}", file=sys.stderr)
            raise SystemExit(1)
        print(f"failed  {label['name']} -> {status}", file=sys.stderr)
        raise SystemExit(1)

    print(f"Done. created={created} updated={updated}")


if __name__ == "__main__":
    main()
