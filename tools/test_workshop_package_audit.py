#!/usr/bin/env python3
"""Self-test for the Workshop package audit rules."""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

import audit_workshop_package


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def expect_clean(package: Path) -> bool:
    findings = audit_workshop_package.audit(package)
    if findings:
        print(f"Expected clean package, got findings: {findings}", file=sys.stderr)
        return False
    return True


def expect_dirty(package: Path, needle: str) -> bool:
    findings = audit_workshop_package.audit(package)
    if not any(needle in finding for finding in findings):
        print(f"Expected finding containing {needle!r}, got: {findings}", file=sys.stderr)
        return False
    return True


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        clean = root / "@tcwa3_stats_tracker_server"
        write(clean / "addons" / "tcwa3_stats_tracker_server_publisher.pbo", "placeholder pbo\n")
        write(clean / "tcwa3_stats_tracker.example.toml", 'api_token = "aat_arma_server_REPLACE_WITH_REAL_TOKEN"\n')
        write(clean / "README-server-install.md", "TCWA3 Stats Tracker\n")
        write(clean / "checksums.sha256", "placeholder  README-server-install.md\n")
        if not expect_clean(clean):
            return 1

        missing_pbo = root / "missing-pbo"
        write(missing_pbo / "tcwa3_stats_tracker.example.toml", 'api_token = "aat_arma_server_REPLACE_WITH_REAL_TOKEN"\n')
        if not expect_dirty(missing_pbo, "addons/: missing Publisher marker PBO"):
            return 1

        real_config = root / "real-config"
        write(real_config / "addons" / "tcwa3_stats_tracker_server_publisher.pbo", "placeholder pbo\n")
        write(real_config / "tcwa3_stats_tracker.toml", "[http]\n")
        if not expect_dirty(real_config, "tcwa3_stats_tracker.toml"):
            return 1

        private_key = root / "private-key"
        write(private_key / "addons" / "tcwa3_stats_tracker_server_publisher.pbo", "placeholder pbo\n")
        write(private_key / "tcwa3.biprivatekey", "not a real key\n")
        if not expect_dirty(private_key, "tcwa3.biprivatekey"):
            return 1

        token = root / "token"
        write(token / "addons" / "tcwa3_stats_tracker_server_publisher.pbo", "placeholder pbo\n")
        write(token / "tcwa3_stats_tracker.example.toml", 'api_token = "' + "aat_" + 'fake_token"\n')
        if not expect_dirty(token, "api_token"):
            return 1

    print("[PASS] Workshop package audit self-test passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
