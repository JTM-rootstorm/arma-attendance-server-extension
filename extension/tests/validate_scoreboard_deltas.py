#!/usr/bin/env python3
"""Validate scoreboard delta mapping for Arma Attendance.

Usage:
    python3 validate-scoreboard-deltas.py templates/tests/scoreboard-delta-cases.json
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


def normalize_scores(value: Any) -> list[int]:
    if not isinstance(value, list):
        value = []
    scores: list[int] = []
    for item in value[:6]:
        if isinstance(item, bool):
            scores.append(0)
        elif isinstance(item, (int, float)):
            scores.append(int(item))
        else:
            scores.append(0)
    while len(scores) < 6:
        scores.append(0)
    return scores


def delta_scores(baseline: Any, latest: Any) -> dict[str, Any]:
    base = normalize_scores(baseline)
    last = normalize_scores(latest)
    delta = [max(0, last[i] - base[i]) for i in range(6)]

    infantry, soft, armor, air, deaths, score = delta
    ground = soft + armor
    all_vehicles = soft + armor + air

    stats = {
        "infantry_kills": infantry,
        "vehicle_kills": all_vehicles,
        "player_kills": 0,
        "ai_kills": infantry,
        "friendly_kills": 0,
        "deaths": deaths,
    }

    scoreboard_stats = {
        "infantry_kills": infantry,
        "soft_vehicle_kills": soft,
        "armor_kills": armor,
        "ground_vehicle_kills": ground,
        "air_kills": air,
        "all_vehicle_kills": all_vehicles,
        "deaths": deaths,
        "score": score,
    }

    return {"stats": stats, "scoreboard_stats": scoreboard_stats}


def assert_subset(actual: dict[str, Any], expected: dict[str, Any], path: str) -> list[str]:
    errors: list[str] = []
    for key, expected_value in expected.items():
        current_path = f"{path}.{key}"
        if key not in actual:
            errors.append(f"missing {current_path}")
            continue
        actual_value = actual[key]
        if isinstance(expected_value, dict):
            if not isinstance(actual_value, dict):
                errors.append(f"{current_path}: expected dict, got {type(actual_value).__name__}")
            else:
                errors.extend(assert_subset(actual_value, expected_value, current_path))
        elif actual_value != expected_value:
            errors.append(f"{current_path}: expected {expected_value!r}, got {actual_value!r}")
    return errors


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate-scoreboard-deltas.py <cases.json>", file=sys.stderr)
        return 2

    cases_path = Path(sys.argv[1])
    data = json.loads(cases_path.read_text(encoding="utf-8"))
    cases = data.get("cases", [])
    if not isinstance(cases, list):
        print("cases.json must contain a list at key 'cases'", file=sys.stderr)
        return 2

    failures: list[str] = []
    for case in cases:
        name = case.get("name", "<unnamed>")
        actual = delta_scores(case.get("baseline"), case.get("latest"))
        expected = case.get("expected", {})
        errors = assert_subset(actual, expected, name)
        failures.extend(errors)

    if failures:
        print("Scoreboard delta validation failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"Validated {len(cases)} scoreboard delta cases.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
