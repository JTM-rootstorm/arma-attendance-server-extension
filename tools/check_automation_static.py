#!/usr/bin/env python3
"""Static checks for TCWA3 Stats Tracker CBA automation wiring."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


REQUIRED_SETTINGS = (
    "AASE_autoStartMode",
    "AASE_autoFinishMode",
    "AASE_startTriggerName",
    "AASE_finishTriggerName",
    "AASE_autoStartDelaySeconds",
    "AASE_autoStartMinPlayers",
    "AASE_triggerPollSeconds",
    "AASE_enableMissionEndFallback",
)

REQUIRED_FUNCTIONS = (
    "autoInit",
    "registerAutomationSettings",
    "startAutomation",
    "stopAutomation",
    "autoTriggerWatcher",
    "autoDelayedStart",
    "autoMissionEndFallback",
    "missionEndOutcome",
    "findMissionTriggerByName",
    "deleteModuleLogic",
    "buildOperationSource",
)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace") if path.exists() else ""


def bad(message: str) -> bool:
    print(f"[FAIL] {message}", file=sys.stderr)
    return False


def tracked_files(root: Path) -> list[Path]:
    try:
        result = subprocess.run(
            ["git", "ls-files"],
            cwd=root,
            check=True,
            text=True,
            capture_output=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return []

    return [root / line for line in result.stdout.splitlines() if line]


def validate_registration(root: Path) -> bool:
    ok = True
    funcs = root / "addons" / "main" / "functions"
    xeh_prep = read(root / "addons" / "main" / "XEH_PREP.hpp")
    config = read(root / "addons" / "main" / "config.cpp")

    for function in REQUIRED_FUNCTIONS:
        filename = f"fnc_{function}.sqf"
        if not (funcs / filename).exists():
            ok = bad(f"Missing automation function file: {filename}") and ok
        if filename not in xeh_prep:
            ok = bad(f"Missing XEH_PREP compile entry for {filename}") and ok
        if f"class {function}" not in config:
            ok = bad(f"Missing CfgFunctions entry for {function}") and ok

    if ok:
        print("[OK] automation functions are registered")
    return ok


def validate_xeh_prep_compile_shape(root: Path) -> bool:
    xeh_prep = read(root / "addons" / "main" / "XEH_PREP.hpp")
    ok = True

    if "compileScript" in xeh_prep:
        ok = bad("XEH_PREP must pass function file paths to CBA_fnc_compileFunction, not compiled code") and ok

    compile_lines = [
        line.strip()
        for line in xeh_prep.splitlines()
        if "CBA_fnc_compileFunction" in line
    ]
    if not compile_lines:
        ok = bad("XEH_PREP has no CBA_fnc_compileFunction entries") and ok

    for line in compile_lines:
        match = re.match(
            r'^\["\\x\\tcwa3_stats_tracker\\addons\\main\\functions\\fnc_(\w+)\.sqf",\s*QFUNC\((\w+)\)\]\s+call\s+CBA_fnc_compileFunction;$',
            line,
        )
        if not match:
            ok = bad(f"Malformed XEH_PREP compile entry: {line}") and ok
            continue
        if match.group(1) != match.group(2):
            ok = bad(f"XEH_PREP compile entry path/name mismatch: {line}") and ok

    if ok:
        print("[OK] XEH_PREP compile entries pass file paths to CBA")
    return ok


def validate_xeh_bootstrap(root: Path) -> bool:
    config = read(root / "addons" / "main" / "config.cpp")
    preinit = read(root / "addons" / "main" / "XEH_preInit.sqf")
    ok = True

    for needle in (
        "class Extended_PreInit_EventHandlers",
        "class tcwa3_stats_tracker_main",
        "XEH_preInit.sqf",
    ):
        if needle not in config:
            ok = bad(f"Missing CBA preInit bootstrap wiring: {needle}") and ok
    for needle in (
        "TCWA3_fnc_autoInit",
        "FUNC(registerAutomationSettings)",
        "TCWA3 Stats Tracker addon initialized.",
    ):
        if needle not in preinit:
            ok = bad(f"XEH_preInit.sqf missing bootstrap call/log: {needle}") and ok

    if ok:
        print("[OK] automation XEH bootstrap is wired")
    return ok


def validate_settings(root: Path) -> bool:
    text = read(root / "addons" / "main" / "functions" / "fnc_registerAutomationSettings.sqf")
    ok = True
    for setting in REQUIRED_SETTINGS:
        if setting not in text:
            ok = bad(f"Missing CBA setting registration: {setting}") and ok
    if '"AASE_autoStartMode"' in text and '["Disabled", "Named trigger", "Delay + min players"], 0' not in text:
        ok = bad("AASE_autoStartMode does not default to Disabled") and ok
    if '"AASE_autoFinishMode"' in text and '["Disabled", "Named trigger"], 0' not in text:
        ok = bad("AASE_autoFinishMode does not default to Disabled") and ok
    if '"AASE_enableMissionEndFallback"' in text and "false" not in text:
        ok = bad("AASE_enableMissionEndFallback should default to false") and ok
    if ok:
        print("[OK] automation settings are present with safe defaults")
    return ok


def validate_automation_calls(root: Path) -> bool:
    funcs = root / "addons" / "main" / "functions"
    trigger_text = read(funcs / "fnc_autoTriggerWatcher.sqf")
    delayed_text = read(funcs / "fnc_autoDelayedStart.sqf")
    fallback_text = read(funcs / "fnc_autoMissionEndFallback.sqf")
    outcome_text = read(funcs / "fnc_missionEndOutcome.sqf")
    source_text = read(funcs / "fnc_buildOperationSource.sqf")
    ok = True

    for needle in ("TCWA3_fnc_operationStart", "TCWA3_fnc_operationFinish", "triggerActivated"):
        if needle not in trigger_text:
            ok = bad(f"Trigger watcher missing {needle}") and ok
    if re.search(r"\bcreate(Vehicle|Unit)\b", trigger_text):
        ok = bad("Trigger watcher must not spawn modules or objects") and ok
    if "TCWA3_fnc_operationStart" not in delayed_text or "delayed_auto_start" not in delayed_text:
        ok = bad("Delayed auto-start must call operationStart with delayed_auto_start source") and ok
    if "TCWA3_fnc_operationFinish" not in fallback_text or "mission_end_fallback" not in fallback_text:
        ok = bad("Mission-end fallback must call operationFinish with mission_end_fallback source") and ok
    for needle in ("params", "_endType", "TCWA3_fnc_missionEndOutcome", "\"end_type\""):
        if needle not in fallback_text:
            ok = bad(f"Mission-end fallback missing failure outcome wiring: {needle}") and ok
    for needle in ("LOSER", "KILLED", "\"FAIL\"", "\"failed\"", "AASE_failedMissionEndTypes"):
        if needle not in outcome_text:
            ok = bad(f"Mission-end outcome helper missing failure classification: {needle}") and ok
    if '"outcome"' not in read(funcs / "fnc_buildOperationFinishPayload.sqf"):
        ok = bad("Finish payload must include top-level outcome") and ok
    if "[true] call TCWA3_fnc_autoMissionEndFallback" not in read(funcs / "fnc_operationStart.sqf"):
        ok = bad("Operation start must force-register mission-end fallback for active operations") and ok
    if "AASE_missionEndFallbackForced" not in fallback_text:
        ok = bad("Mission-end fallback must support forced registration for active operations") and ok
    for source_kind in ("zeus_module", "named_trigger", "delayed_auto_start", "mission_end_fallback"):
        if source_kind not in source_text:
            ok = bad(f"Source metadata helper missing {source_kind}") and ok

    if ok:
        print("[OK] automation entrypoints call shared operation functions")
    return ok


def validate_modules(root: Path) -> bool:
    funcs = root / "addons" / "main" / "functions"
    ok = True
    for path in funcs.glob("fnc_module*.sqf"):
        text = read(path)
        if "TCWA3_fnc_deleteModuleLogic" not in text and "deleteVehicle" not in text:
            ok = bad(f"Module wrapper may not delete logic object: {path}") and ok
    if ok:
        print("[OK] module wrappers clean up logic objects")
    return ok


def validate_secrets(root: Path) -> bool:
    ok = True
    secret_patterns = (
        re.compile(r"BEGIN .*PRIVATE"),
        re.compile(r"aat_arma_server_(?!REPLACE_WITH_REAL_TOKEN)[A-Za-z0-9_-]+"),
    )
    text_suffixes = {".cpp", ".hpp", ".h", ".md", ".py", ".sqf", ".toml", ".txt", ".xml", ".yml", ".yaml"}
    self_path = Path(__file__).resolve()
    for path in tracked_files(root):
        if path.resolve() == self_path:
            continue
        if path.name.endswith((".biprivatekey", ".hemttprivatekey")):
            ok = bad(f"Private signing key is tracked: {path.relative_to(root)}") and ok
            continue
        if path.suffix.lower() not in text_suffixes:
            continue
        text = read(path)
        for pattern in secret_patterns:
            if pattern.search(text):
                ok = bad(f"Possible secret pattern {pattern.pattern!r} in {path.relative_to(root)}") and ok
    if ok:
        print("[OK] tracked text files do not contain private key/token patterns")
    return ok


def main(argv: list[str]) -> int:
    root = Path(argv[1]) if len(argv) > 1 else Path.cwd()
    checks = (
        validate_registration(root),
        validate_xeh_prep_compile_shape(root),
        validate_xeh_bootstrap(root),
        validate_settings(root),
        validate_automation_calls(root),
        validate_modules(root),
        validate_secrets(root),
    )
    if all(checks):
        print("[PASS] automation static checks complete")
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
