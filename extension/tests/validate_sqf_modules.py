#!/usr/bin/env python3
import sys
from pathlib import Path


MODULES = (
    "addons/main/functions/fnc_moduleStartOperation.sqf",
    "addons/main/functions/fnc_moduleFinishOperation.sqf",
)


def validate(root, relative):
    path = root / relative
    text = path.read_text(encoding="utf-8")
    checks = {
        "cleanup closure": "private _cleanup" in text,
        "deleteVehicle": "deleteVehicle _moduleLogic" in text,
        "non-server cleanup": "if (!isServer) exitWith" in text and "[_logic] call _cleanup" in text,
        "inactive cleanup": "if (!_activated) exitWith" in text and text.count("[_logic] call _cleanup") >= 3,
        "result return": text.rstrip().endswith("_result"),
    }
    ok = True
    for name, passed in checks.items():
        if not passed:
            print(f"[FAIL] {relative}: missing {name}", file=sys.stderr)
            ok = False
    if ok:
        print(f"[OK] {relative}")
    return ok


def main(argv):
    root = Path(argv[1]) if len(argv) > 1 else Path.cwd()
    ok = True
    for module in MODULES:
        ok = validate(root, module) and ok
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
