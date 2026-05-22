#!/usr/bin/env python3
import json
import sys
from pathlib import Path


CANONICAL_STATS = {
    "infantry_kills",
    "vehicle_kills",
    "player_kills",
    "ai_kills",
    "friendly_kills",
    "deaths",
}
SCOREBOARD_FIELDS = {
    "stats_source",
    "infantry_kills",
    "soft_vehicle_kills",
    "armor_kills",
    "ground_vehicle_kills",
    "air_kills",
    "all_vehicle_kills",
    "deaths",
    "score",
    "baseline",
    "latest",
}


def bad(path, msg):
    print(f"[FAIL] {path}: {msg}", file=sys.stderr)
    return False


def validate_stats(path, owner, stats):
    ok = True
    if not isinstance(stats, dict):
        return bad(path, f"{owner}.stats must be an object")
    missing = sorted(CANONICAL_STATS - set(stats))
    if missing:
        ok = bad(path, f"{owner}.stats missing {', '.join(missing)}")
    for field, value in stats.items():
        if field not in CANONICAL_STATS:
            ok = bad(path, f"{owner}.stats has non-canonical field {field}")
        if not isinstance(value, int) or value < 0:
            ok = bad(path, f"{owner}.stats.{field} must be a non-negative integer")
    return ok


def validate_scoreboard_stats(path, owner, scoreboard_stats):
    ok = True
    if not isinstance(scoreboard_stats, dict):
        return bad(path, f"{owner}.scoreboard_stats must be an object")
    missing = sorted(SCOREBOARD_FIELDS - set(scoreboard_stats))
    if missing:
        ok = bad(path, f"{owner}.scoreboard_stats missing {', '.join(missing)}")
    if scoreboard_stats.get("stats_source") != "arma_getPlayerScores_delta":
        ok = bad(path, f"{owner}.scoreboard_stats.stats_source must be arma_getPlayerScores_delta")
    for field in SCOREBOARD_FIELDS - {"stats_source", "baseline", "latest"}:
        value = scoreboard_stats.get(field)
        if not isinstance(value, int) or value < 0:
            ok = bad(path, f"{owner}.scoreboard_stats.{field} must be a non-negative integer")
    for field in ("baseline", "latest"):
        value = scoreboard_stats.get(field)
        if not isinstance(value, list) or len(value) != 6:
            ok = bad(path, f"{owner}.scoreboard_stats.{field} must be a six-value array")
    return ok


def validate(path):
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    ok = True
    for field in ("request_id", "server_key"):
        if not data.get(field):
            ok = bad(path, f"missing {field}")
    if data.get("payload_version") != 1:
        ok = bad(path, "payload_version must be 1")
    if not isinstance(data.get("mission", {}), dict):
        ok = bad(path, "mission must be an object")
    if not isinstance(data.get("source", {}), dict):
        ok = bad(path, "source must be an object")

    for index, player in enumerate(data.get("players", [])):
        owner = f"players[{index}]"
        if not isinstance(player, dict):
            ok = bad(path, f"{owner} must be an object")
            continue
        if not player.get("player_uid"):
            ok = bad(path, f"{owner} missing player_uid")
        if not player.get("name"):
            ok = bad(path, f"{owner} missing name")
        if player.get("present_at_end") is False:
            ok = bad(path, f"{owner} has present_at_end=false; use attendance_records")
        if "stats" in player:
            ok = validate_stats(path, owner, player["stats"]) and ok
        if "scoreboard_stats" in player:
            ok = validate_scoreboard_stats(path, owner, player["scoreboard_stats"]) and ok

    for index, record in enumerate(data.get("attendance_records", [])):
        owner = f"attendance_records[{index}]"
        if not isinstance(record, dict):
            ok = bad(path, f"{owner} must be an object")
            continue
        if not record.get("player_uid"):
            ok = bad(path, f"{owner} missing player_uid")
        for field in ("operation_seconds", "attended_seconds", "missed_seconds", "attendance_ratio"):
            if field not in record:
                ok = bad(path, f"{owner} missing {field}")
            elif not isinstance(record[field], (int, float)):
                ok = bad(path, f"{owner}.{field} must be numeric")
        if "attendance_threshold" not in record:
            ok = bad(path, f"{owner} missing attendance_threshold")
        if "stats" in record:
            ok = validate_stats(path, owner, record["stats"]) and ok
        if "scoreboard_stats" in record:
            ok = validate_scoreboard_stats(path, owner, record["scoreboard_stats"]) and ok

    if ok:
        print(f"[OK] {path}")
    return ok


def main(argv):
    if len(argv) < 2:
        print("Usage: validate_payloads.py <json> [...]", file=sys.stderr)
        return 2
    ok = True
    for path in argv[1:]:
        try:
            ok = validate(path) and ok
        except Exception as exc:  # noqa: BLE001 - command-line diagnostics.
            ok = bad(path, str(exc)) and ok
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
