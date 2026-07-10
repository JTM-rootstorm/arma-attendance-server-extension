#!/usr/bin/env python3
"""Behavioral self-tests for strict Workshop package auditing."""
from __future__ import annotations
import shutil, tempfile
from pathlib import Path
import audit_workshop_package as audit

def write(path: Path, data: str = "fixture\n") -> None:
    path.parent.mkdir(parents=True, exist_ok=True); path.write_text(data, encoding="utf-8")

def complete(root: Path) -> None:
    for name in audit.REQUIRED - {"checksums.sha256"}: write(root / name)
    write(root / "keys/test.bikey")
    checksums = []
    for path in sorted(p for p in root.rglob("*") if p.is_file()):
        checksums.append(f"{audit.digest(path)}  {path.relative_to(root).as_posix()}")
    write(root / "checksums.sha256", "\n".join(checksums) + "\n")

def expect(root: Path, needle: str | None = None) -> None:
    findings = audit.audit(root)
    if needle is None and findings: raise AssertionError(findings)
    if needle is not None and not any(needle in item for item in findings): raise AssertionError((needle, findings))

def main() -> int:
    with tempfile.TemporaryDirectory() as temporary:
        base = Path(temporary); clean = base / "clean"; complete(clean); expect(clean)
        for name, needle in [("tcwa3_stats_tracker_x64.dll", "missing required artifact"), ("tcwa3_stats_tracker_x64.so", "missing required artifact"), ("README-server-install.txt", "missing required artifact")]:
            case = base / name.replace(".", "-"); shutil.copytree(clean, case); (case / name).unlink(); expect(case, needle)
        wrong = base / "wrong"; shutil.copytree(clean, wrong); write(wrong / "README-server-install.md", "changed\n"); expect(wrong, "mismatch")
        extra = base / "extra"; shutil.copytree(clean, extra); write(extra / "unexpected.txt"); expect(extra, "missing entry")
        private = base / "private"; shutil.copytree(clean, private); write(private / "secret.biprivatekey"); expect(private, "forbidden")
        token = base / "token"; shutil.copytree(clean, token); write(token / "leak.txt", "Authorization: Bearer nope"); expect(token, "forbidden pattern")
    print("[PASS] Workshop package audit self-test passed"); return 0
if __name__ == "__main__": raise SystemExit(main())
