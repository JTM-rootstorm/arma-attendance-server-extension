#!/usr/bin/env python3

import json
import math
import sys


def new_record(uid, name, now, present_at_start):
    return {
        "uid": uid,
        "name": name,
        "state": "present",
        "active_since": now,
        "attended_seconds": 0,
        "present_at_start": present_at_start,
        "present_at_end": False,
        "joined_after_start": not present_at_start,
        "first_seen_at": now,
        "last_seen_at": now,
        "disconnect_count": 0,
        "reconnect_count": 0,
        "last_disconnect_at": -1,
        "last_reconnect_at": -1,
    }


def present(ledger, uid, name, now, present_at_start=False):
    record = ledger.get(uid)
    if record is None:
        ledger[uid] = new_record(uid, name, now, present_at_start)
        return
    if record["state"] != "present":
        record["state"] = "present"
        record["active_since"] = now
        record["reconnect_count"] += 1
        record["last_reconnect_at"] = now
    if present_at_start:
        record["present_at_start"] = True
        record["joined_after_start"] = False
    if name:
        record["name"] = name
    record["last_seen_at"] = now


def absent(ledger, uid, name, now, reason):
    record = ledger.get(uid)
    if record is None:
        record = {
            "uid": uid,
            "name": name,
            "state": "absent_paused",
            "active_since": -1,
            "attended_seconds": 0,
            "present_at_start": False,
            "present_at_end": False,
            "joined_after_start": True,
            "first_seen_at": now,
            "last_seen_at": now,
            "disconnect_count": 0,
            "reconnect_count": 0,
            "last_disconnect_at": -1,
            "last_reconnect_at": -1,
        }
        ledger[uid] = record
    if record["state"] == "present" and record["active_since"] >= 0:
        record["attended_seconds"] += now - record["active_since"]
    if name:
        record["name"] = name
    record["state"] = "absent_paused"
    record["active_since"] = -1
    record["last_seen_at"] = now
    if reason == "disconnect":
        record["disconnect_count"] += 1
        record["last_disconnect_at"] = now


def finalize(ledger, operation_start, operation_end, threshold):
    operation_seconds = max(0, operation_end - operation_start)
    records = {}
    for uid, record in ledger.items():
        attended_seconds = record["attended_seconds"]
        if record["state"] == "present":
            record["present_at_end"] = True
            attended_seconds += operation_end - record["active_since"]
        attended_seconds = max(0, min(attended_seconds, operation_seconds))
        ratio = attended_seconds / operation_seconds if operation_seconds else 0
        status = "absent"
        if ratio >= 0.999:
            status = "full"
        elif ratio >= threshold:
            status = "partial"
        records[uid] = {
            "attended_seconds": attended_seconds,
            "present_at_start": record["present_at_start"],
            "present_at_end": record["present_at_end"],
            "joined_after_start": record["joined_after_start"],
            "disconnect_count": record["disconnect_count"],
            "reconnect_count": record["reconnect_count"],
            "attendance_ratio": ratio,
            "attendance_status": status,
            "attendance_credit": ratio >= threshold,
        }
    return records


def assert_close(case_name, field, got, expected):
    if isinstance(expected, float):
        if not math.isclose(got, expected, rel_tol=0.0001, abs_tol=0.0001):
            raise AssertionError(f"{case_name}: expected {field}={expected}, got {got}")
        return
    if got != expected:
        raise AssertionError(f"{case_name}: expected {field}={expected!r}, got {got!r}")


def run_case(case):
    ledger = {}
    start = case["operation_start"]
    end = case["operation_end"]
    threshold = case.get("threshold", 0.5)
    for event in case["events"]:
        kind = event["type"]
        uid = event["uid"]
        name = event.get("name", "")
        at = event["at"]
        if kind == "present_from_unit":
            present(ledger, uid, name, at, event.get("present_at_start", False))
        elif kind == "pending_present":
            present(ledger, uid, name, at, False)
        elif kind == "absent":
            absent(ledger, uid, name, at, event.get("reason", "disconnect"))
        else:
            raise AssertionError(f"{case['name']}: unknown event type {kind}")
    records = finalize(ledger, start, end, threshold)
    for uid, expected in case["expect"].items():
        record = records.get(uid)
        if record is None:
            raise AssertionError(f"{case['name']}: missing record for {uid}")
        for field, value in expected.items():
            assert_close(case["name"], f"{uid}.{field}", record.get(field), value)


def main():
    with open(sys.argv[1], "r", encoding="utf-8") as handle:
        cases = json.load(handle)
    for case in cases:
        run_case(case)
    print(f"validated {len(cases)} presence ledger cases")


if __name__ == "__main__":
    main()
