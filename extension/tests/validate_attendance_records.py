#!/usr/bin/env python3

import json
import sys


REQUIRED_FIELDS = {
    "player_uid",
    "name",
    "present_at_start",
    "present_at_end",
    "operation_seconds",
    "attended_seconds",
    "attendance_ratio",
    "attendance_status",
    "attendance_credit",
}


def main():
    with open(sys.argv[1], "r", encoding="utf-8") as handle:
        data = json.load(handle)
    payload = data.get("payload", data)
    records = payload.get("attendance_records")
    if not isinstance(records, list) or not records:
        raise SystemExit("attendance_records must be a non-empty array")
    seen = set()
    for index, record in enumerate(records):
        if not isinstance(record, dict):
            raise SystemExit(f"attendance_records[{index}] must be an object")
        missing = sorted(REQUIRED_FIELDS - set(record))
        if missing:
            raise SystemExit(f"attendance_records[{index}] missing fields: {', '.join(missing)}")
        uid = str(record["player_uid"]).strip()
        if not uid:
            raise SystemExit(f"attendance_records[{index}] has blank player_uid")
        if uid in seen:
            raise SystemExit(f"duplicate player_uid in attendance_records: {uid}")
        seen.add(uid)
        operation_seconds = record["operation_seconds"]
        attended_seconds = record["attended_seconds"]
        ratio = record["attendance_ratio"]
        if operation_seconds < 0 or attended_seconds < 0:
            raise SystemExit(f"attendance_records[{index}] has negative duration")
        if attended_seconds > operation_seconds:
            raise SystemExit(f"attendance_records[{index}] attended_seconds exceeds operation_seconds")
        if ratio < 0 or ratio > 1:
            raise SystemExit(f"attendance_records[{index}] attendance_ratio outside 0..1")
    print(f"validated {len(records)} attendance records")


if __name__ == "__main__":
    main()
