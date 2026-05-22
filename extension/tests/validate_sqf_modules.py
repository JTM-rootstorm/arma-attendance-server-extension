#!/usr/bin/env python3
import sys
from pathlib import Path


MODULES = (
    "addons/main/functions/fnc_moduleStartOperation.sqf",
    "addons/main/functions/fnc_moduleFinishOperation.sqf",
)


def validate_module_cleanup(root, relative):
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


def validate_operation_json(root):
    checks = {
        "addons/main/XEH_PREP.hpp": [
            ("encodeJson compile", "fnc_encodeJson.sqf"),
        ],
        "addons/main/config.cpp": [
            ("encodeJson CfgFunctions entry", "class encodeJson"),
        ],
        "addons/main/functions/fnc_encodeJson.sqf": [
            ("HashMap object encoding", 'case "HASHMAP"'),
            ("array encoding", 'case "ARRAY"'),
            ("quote escaping", "case 34"),
            ("backslash escaping", "case 92"),
        ],
        "addons/main/functions/fnc_callExtension.sqf": [
            ("callExtension tuple unwrap", "_result select 0"),
        ],
        "addons/main/functions/fnc_operationStart.sqf": [
            ("operation start uses local JSON encoder", "AASE_fnc_encodeJson"),
        ],
        "addons/main/functions/fnc_operationFinish.sqf": [
            ("operation finish uses local JSON encoder", "AASE_fnc_encodeJson"),
        ],
    }
    forbidden = {
        "addons/main/functions/fnc_operationStart.sqf": [
            ("operation start must not use CBA HashMap JSON encoding", "CBA_fnc_encodeJSON"),
        ],
        "addons/main/functions/fnc_operationFinish.sqf": [
            ("operation finish must not use CBA HashMap JSON encoding", "CBA_fnc_encodeJSON"),
        ],
    }

    ok = True
    for relative, required in checks.items():
        path = root / relative
        text = path.read_text(encoding="utf-8")
        for name, needle in required:
            if needle not in text:
                print(f"[FAIL] {relative}: missing {name}", file=sys.stderr)
                ok = False
        for name, needle in forbidden.get(relative, []):
            if needle in text:
                print(f"[FAIL] {relative}: {name}", file=sys.stderr)
                ok = False

    if ok:
        print("[OK] SQF operation JSON bridge")
    return ok


def main(argv):
    root = Path(argv[1]) if len(argv) > 1 else Path.cwd()
    ok = True
    for module in MODULES:
        ok = validate_module_cleanup(root, module) and ok
    ok = validate_operation_json(root) and ok
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
