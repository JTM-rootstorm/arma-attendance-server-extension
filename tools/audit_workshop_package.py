#!/usr/bin/env python3
"""Audit a complete TCWA3 server package for contents, checksums, and secrets."""
from __future__ import annotations
import argparse, hashlib, re, sys
from pathlib import Path

REQUIRED = {
    "addons/tcwa3_stats_tracker_main.pbo", "addons/tcwa3_stats_tracker_server_publisher.pbo",
    "tcwa3_stats_tracker.so", "tcwa3_stats_tracker_x64.so", "tcwa3_stats_tracker_x64.dll",
    "tcwa3_stats_tracker.example.toml", "arma_attendance.example.toml",
    "README-server-install.md", "README-server-install.txt", "README-workshop-server-extension.md", "checksums.sha256",
}
FORBIDDEN_NAMES = {".env", "arma_attendance.toml", "tcwa3_stats_tracker.toml"}
FORBIDDEN_SUFFIXES = {".biprivatekey", ".hemttprivatekey", ".log", ".ndjson"}
SECRET_PATTERNS = (re.compile(r"Authorization:\s*Bearer\s+\S+", re.I), re.compile("BEGIN " + r"[A-Z ]*" + "PRIV" + "ATE KEY"),
                   re.compile(r'api_token\s*=\s*"aat_(?!arma_server_REPLACE_WITH_REAL_TOKEN)[^"]+"'))

def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""): value.update(block)
    return value.hexdigest()

def audit(root: Path, *, unsigned_preview: bool = False, allow_linux_only: bool = False) -> list[str]:
    findings: list[str] = []
    required = REQUIRED - ({"tcwa3_stats_tracker_x64.dll"} if allow_linux_only else set())
    for name in sorted(required):
        if not (root / name).is_file(): findings.append(f"{name}: missing required artifact")
    if not unsigned_preview and not any((root / "keys").glob("*.bikey")): findings.append("keys/: missing public .bikey")
    files = [item for item in root.rglob("*") if item.is_file()]
    for path in sorted(files):
        rel = path.relative_to(root).as_posix()
        if path.name in FORBIDDEN_NAMES or path.name.startswith(".env") or path.suffix in FORBIDDEN_SUFFIXES or (path.suffix == ".toml" and not path.name.endswith(".example.toml")):
            findings.append(f"{rel}: forbidden private/runtime file"); continue
        if path.suffix.lower() in {".json", ".md", ".py", ".sqf", ".toml", ".txt", ".xml", ".yml", ".yaml"}:
            text = path.read_text(encoding="utf-8", errors="replace")
            for pattern in SECRET_PATTERNS:
                if pattern.search(text): findings.append(f"{rel}: matched forbidden pattern {pattern.pattern!r}")
    checksum_file = root / "checksums.sha256"
    if checksum_file.is_file():
        entries: dict[str, str] = {}
        for line in checksum_file.read_text().splitlines():
            parts = line.split(maxsplit=1)
            if len(parts) != 2: findings.append("checksums.sha256: malformed entry"); continue
            name = parts[1].lstrip("*").removeprefix("./")
            if name == "checksums.sha256": findings.append("checksums.sha256: must not include itself")
            entries[name] = parts[0]
        actual = {p.relative_to(root).as_posix() for p in files if p != checksum_file}
        if set(entries) != actual:
            for name in sorted(actual - set(entries)): findings.append(f"checksums.sha256: missing entry for {name}")
            for name in sorted(set(entries) - actual): findings.append(f"checksums.sha256: unexpected entry for {name}")
        for name in sorted(set(entries) & actual):
            if entries[name].lower() != digest(root / name): findings.append(f"checksums.sha256: mismatch for {name}")
    return findings

def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__); parser.add_argument("--unsigned-preview", action="store_true"); parser.add_argument("--allow-linux-only", action="store_true"); parser.add_argument("package", type=Path)
    args = parser.parse_args(argv[1:]); findings = audit(args.package.resolve(), unsigned_preview=args.unsigned_preview, allow_linux_only=args.allow_linux_only)
    if findings:
        print("[FAIL] Workshop package audit:", file=sys.stderr)
        for finding in findings: print(f"  - {finding}", file=sys.stderr)
        return 1
    print(f"[PASS] Workshop package audit passed: {args.package}"); return 0
if __name__ == "__main__": raise SystemExit(main(sys.argv))
