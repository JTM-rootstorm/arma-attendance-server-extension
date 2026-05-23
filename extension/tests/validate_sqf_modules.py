#!/usr/bin/env python3
import sys
from pathlib import Path


MODULES = (
    "addons/main/functions/fnc_moduleDebugPoke.sqf",
    "addons/main/functions/fnc_moduleStartOperation.sqf",
    "addons/main/functions/fnc_moduleFinishOperation.sqf",
)


def validate_module_cleanup(root, relative):
    path = root / relative
    text = path.read_text(encoding="utf-8")
    helper_cleanup = "AASE_fnc_deleteModuleLogic" in text
    checks = {
        "cleanup helper": helper_cleanup or "private _cleanup" in text,
        "delete logic": helper_cleanup or "deleteVehicle _moduleLogic" in text,
        "non-server cleanup": "if (!isServer) exitWith" in text and (helper_cleanup or "[_logic] call _cleanup" in text),
        "inactive cleanup": "if (!_activated) exitWith" in text and (text.count("AASE_fnc_deleteModuleLogic") >= 3 or text.count("[_logic] call _cleanup") >= 3),
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


def validate_player_name_sanitizer(root):
    checks = {
        "addons/main/XEH_PREP.hpp": [
            ("sanitizePlayerName compile", "fnc_sanitizePlayerName.sqf"),
        ],
        "addons/main/config.cpp": [
            ("sanitizePlayerName CfgFunctions entry", "class sanitizePlayerName"),
        ],
        "addons/main/functions/fnc_sanitizePlayerName.sqf": [
            ("digit allowance", "_x >= 48"),
            ("uppercase allowance", "_x >= 65"),
            ("lowercase allowance", "_x >= 97"),
            ("fallback handling", "_fallback"),
        ],
        "addons/main/functions/fnc_buildPlayerSnapshot.sqf": [
            ("snapshot name sanitization", "AASE_fnc_sanitizePlayerName"),
        ],
        "addons/main/functions/fnc_markPlayerPresentFromUnit.sqf": [
            ("presence name sanitization", "AASE_fnc_sanitizePlayerName"),
        ],
        "addons/main/functions/fnc_scoreCaptureUnit.sqf": [
            ("score capture name sanitization", "AASE_fnc_sanitizePlayerName"),
        ],
        "addons/main/functions/fnc_markPlayerAbsent.sqf": [
            ("absence name sanitization", "AASE_fnc_sanitizePlayerName"),
        ],
        "addons/main/functions/fnc_markUidPresentPending.sqf": [
            ("pending reconnect name sanitization", "AASE_fnc_sanitizePlayerName"),
        ],
        "addons/main/functions/fnc_incrementPresenceStat.sqf": [
            ("stat name sanitization", "AASE_fnc_sanitizePlayerName"),
        ],
        "addons/main/functions/fnc_buildAttendanceRecords.sqf": [
            ("attendance record name sanitization", "AASE_fnc_sanitizePlayerName"),
        ],
    }
    forbidden = {
        "addons/main/functions/fnc_buildPlayerSnapshot.sqf": [
            ("snapshot must not send raw player name", '["name", name _unit]'),
        ],
        "addons/main/functions/fnc_markPlayerPresentFromUnit.sqf": [
            ("presence record must not store raw player name", '["name", name _unit]'),
            ("presence update must not store raw player name", '_record set ["name", name _unit]'),
        ],
        "addons/main/functions/fnc_scoreCaptureUnit.sqf": [
            ("score capture must not store raw player name", '["name", name _unit]'),
        ],
    }

    ok = True
    for relative, required in checks.items():
        text = (root / relative).read_text(encoding="utf-8")
        for name, needle in required:
            if needle not in text:
                print(f"[FAIL] {relative}: missing {name}", file=sys.stderr)
                ok = False
        for name, needle in forbidden.get(relative, []):
            if needle in text:
                print(f"[FAIL] {relative}: {name}", file=sys.stderr)
                ok = False

    if ok:
        print("[OK] SQF player name sanitization")
    return ok


def validate_headless_client_filter(root):
    checks = {
        "addons/main/XEH_PREP.hpp": [
            ("isHeadlessClient compile", "fnc_isHeadlessClient.sqf"),
            ("activePlayerUnits compile", "fnc_activePlayerUnits.sqf"),
        ],
        "addons/main/config.cpp": [
            ("isHeadlessClient CfgFunctions entry", "class isHeadlessClient"),
            ("activePlayerUnits CfgFunctions entry", "class activePlayerUnits"),
        ],
        "addons/main/functions/fnc_isHeadlessClient.sqf": [
            ("HeadlessClient_F detection", "HeadlessClient_F"),
            ("entities filter", 'entities "HeadlessClient_F"'),
        ],
        "addons/main/functions/fnc_activePlayerUnits.sqf": [
            ("allPlayers HC subtraction", 'allPlayers - (entities "HeadlessClient_F")'),
        ],
        "addons/main/functions/fnc_buildPlayersSnapshot.sqf": [
            ("snapshot loop uses active player filter", "AASE_fnc_activePlayerUnits"),
        ],
        "addons/main/functions/fnc_scoreCaptureCurrentPlayers.sqf": [
            ("score loop uses active player filter", "AASE_fnc_activePlayerUnits"),
        ],
        "addons/main/functions/fnc_presenceInit.sqf": [
            ("init loop uses active player filter", "AASE_fnc_activePlayerUnits"),
        ],
        "addons/main/functions/fnc_presenceStartLoop.sqf": [
            ("reconcile loop uses active player filter", "AASE_fnc_activePlayerUnits"),
        ],
        "addons/main/functions/fnc_presenceFinalizeForEnd.sqf": [
            ("finish loop uses active player filter", "AASE_fnc_activePlayerUnits"),
        ],
        "addons/main/functions/fnc_buildPlayerSnapshot.sqf": [
            ("snapshot rejects HC unit", "AASE_fnc_isHeadlessClient"),
        ],
        "addons/main/functions/fnc_markPlayerPresentFromUnit.sqf": [
            ("presence rejects HC unit", "AASE_fnc_isHeadlessClient"),
        ],
        "addons/main/functions/fnc_scoreCaptureUnit.sqf": [
            ("score capture rejects HC unit", "AASE_fnc_isHeadlessClient"),
        ],
        "addons/main/functions/fnc_presenceRegisterHandlers.sqf": [
            ("connect resolves active player unit", "AASE_fnc_activePlayerUnits"),
            ("disconnect skips HC unit", "AASE_fnc_isHeadlessClient"),
            ("disconnect skips unknown UID", "!(_uid in _ledger)"),
        ],
    }
    forbidden = {
        "addons/main/functions/fnc_buildPlayersSnapshot.sqf": [
            ("snapshot loop must not iterate raw allPlayers", "forEach allPlayers"),
        ],
        "addons/main/functions/fnc_scoreCaptureCurrentPlayers.sqf": [
            ("score loop must not iterate raw allPlayers", "forEach allPlayers"),
        ],
        "addons/main/functions/fnc_presenceInit.sqf": [
            ("init loop must not iterate raw allPlayers", "forEach allPlayers"),
        ],
        "addons/main/functions/fnc_presenceStartLoop.sqf": [
            ("reconcile loop must not iterate raw allPlayers", "forEach allPlayers"),
        ],
        "addons/main/functions/fnc_presenceFinalizeForEnd.sqf": [
            ("finish loop must not iterate raw allPlayers", "forEach allPlayers"),
        ],
        "addons/main/functions/fnc_presenceRegisterHandlers.sqf": [
            ("connect must not mark pending UID without unit classification", "AASE_fnc_markUidPresentPending"),
        ],
    }

    ok = True
    for relative, required in checks.items():
        text = (root / relative).read_text(encoding="utf-8")
        for name, needle in required:
            if needle not in text:
                print(f"[FAIL] {relative}: missing {name}", file=sys.stderr)
                ok = False
        for name, needle in forbidden.get(relative, []):
            if needle in text:
                print(f"[FAIL] {relative}: {name}", file=sys.stderr)
                ok = False

    if ok:
        print("[OK] SQF headless client filtering")
    return ok


def validate_scoreboard_stats(root):
    required_functions = (
        "scoreNormalizeArray",
        "scoreInit",
        "scoreCaptureUnit",
        "scoreCaptureCurrentPlayers",
        "scoreDelta",
        "scoreStatsForUid",
        "scoreAttachStats",
    )
    checks = {
        "addons/main/XEH_PREP.hpp": [(f"{name} compile", f"fnc_{name}.sqf") for name in required_functions],
        "addons/main/config.cpp": [(f"{name} CfgFunctions entry", f"class {name}") for name in required_functions],
        "addons/main/functions/fnc_scoreCaptureUnit.sqf": [
            ("getPlayerScores capture", "getPlayerScores _unit"),
            ("baseline preservation", "if !(_uid in _baselineByUid)"),
            ("latest snapshot", "_latestByUid set [_uid, _snapshot]"),
        ],
        "addons/main/functions/fnc_scoreDelta.sqf": [
            ("negative clamp", "if (_value < 0)"),
            ("vehicle mapping includes air", "_groundVehicles + _air"),
            ("stats source", "arma_getPlayerScores_delta"),
        ],
        "addons/main/functions/fnc_presenceInit.sqf": [
            ("score init", "AASE_fnc_scoreInit"),
            ("initial capture", "AASE_fnc_scoreCaptureCurrentPlayers"),
        ],
        "addons/main/functions/fnc_markPlayerPresentFromUnit.sqf": [
            ("late join capture", "AASE_fnc_scoreCaptureUnit"),
        ],
        "addons/main/functions/fnc_presenceStartLoop.sqf": [
            ("loop capture", "AASE_fnc_scoreCaptureUnit"),
        ],
        "addons/main/functions/fnc_presenceRegisterHandlers.sqf": [
            ("disconnect capture attempt", "AASE_fnc_scoreCaptureUnit"),
            ("experimental kill ledger disabled by default", "AASE_enableExperimentalKillLedger"),
        ],
        "addons/main/functions/fnc_presenceFinalizeForEnd.sqf": [
            ("finish capture", "AASE_fnc_scoreCaptureCurrentPlayers"),
        ],
        "addons/main/functions/fnc_buildPlayerSnapshot.sqf": [
            ("finish-present stat attach", "AASE_fnc_scoreAttachStats"),
        ],
        "addons/main/functions/fnc_buildAttendanceRecords.sqf": [
            ("attendance stat attach", "AASE_fnc_scoreAttachStats"),
        ],
    }

    ok = True
    for relative, required in checks.items():
        text = (root / relative).read_text(encoding="utf-8")
        for name, needle in required:
            if needle not in text:
                print(f"[FAIL] {relative}: missing {name}", file=sys.stderr)
                ok = False
    if ok:
        print("[OK] SQF scoreboard stats wiring")
    return ok


def main(argv):
    root = Path(argv[1]) if len(argv) > 1 else Path.cwd()
    ok = True
    for module in MODULES:
        ok = validate_module_cleanup(root, module) and ok
    ok = validate_operation_json(root) and ok
    ok = validate_player_name_sanitizer(root) and ok
    ok = validate_headless_client_filter(root) and ok
    ok = validate_scoreboard_stats(root) and ok
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
