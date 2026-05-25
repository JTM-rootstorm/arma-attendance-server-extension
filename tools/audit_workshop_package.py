#!/usr/bin/env python3
"""Audit TCWA3 Stats Tracker Workshop package contents for secrets."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


TEXT_SUFFIXES = {
    ".cpp",
    ".hpp",
    ".h",
    ".json",
    ".md",
    ".py",
    ".sqf",
    ".toml",
    ".txt",
    ".xml",
    ".yml",
    ".yaml",
}

FORBIDDEN_EXACT_NAMES = {
    ".env",
    "arma_attendance.toml",
    "tcwa3_stats_tracker.toml",
}

FORBIDDEN_SUFFIXES = {
    ".biprivatekey",
    ".hemttprivatekey",
    ".log",
    ".ndjson",
}

SECRET_PATTERNS = (
    re.compile(r"Authorization:\s*Bearer\s+\S+", re.IGNORECASE),
    re.compile("BEGIN " + r"[A-Z ]*" + "PRIV" + "ATE KEY"),
    re.compile(r'api_token\s*=\s*"aat_(?!arma_server_REPLACE_WITH_REAL_TOKEN)[^"]+"'),
)


def is_env_file(path: Path) -> bool:
    return path.name == ".env" or path.name.startswith(".env.")


def is_forbidden_file(path: Path) -> str | None:
    name = path.name
    if name in FORBIDDEN_EXACT_NAMES or is_env_file(path):
        return "real config or environment file"
    if any(name.endswith(suffix) for suffix in FORBIDDEN_SUFFIXES):
        return "private key, queue, or log file"
    if name.endswith(".toml") and not name.endswith(".example.toml"):
        return "non-example TOML file"
    return None


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def audit(root: Path) -> list[str]:
    findings: list[str] = []
    for path in sorted(item for item in root.rglob("*") if item.is_file()):
        relative = path.relative_to(root)
        if reason := is_forbidden_file(path):
            findings.append(f"{relative}: forbidden {reason}")
            continue

        if path.suffix.lower() not in TEXT_SUFFIXES:
            continue

        text = read_text(path)
        for pattern in SECRET_PATTERNS:
            if pattern.search(text):
                findings.append(f"{relative}: matched forbidden pattern {pattern.pattern!r}")
    return findings


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package", type=Path, help="Workshop package directory to audit")
    args = parser.parse_args(argv[1:])

    package = args.package.resolve()
    if not package.exists() or not package.is_dir():
        print(f"Package directory does not exist: {package}", file=sys.stderr)
        return 2

    findings = audit(package)
    if findings:
        print("[FAIL] Workshop package audit found forbidden content:", file=sys.stderr)
        for finding in findings:
            print(f"  - {finding}", file=sys.stderr)
        return 1

    print(f"[PASS] Workshop package audit passed: {package}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
