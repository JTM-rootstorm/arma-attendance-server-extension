#!/usr/bin/env python3

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import argparse
import json
from urllib.parse import unquote, urlparse


OPERATION_ID = "00000000-0000-4000-8000-000000000001"
requests_by_id = {}
operations = {}


def remove_prefix(value, prefix):
    if value.startswith(prefix):
        return value[len(prefix) :]
    return value


def remove_suffix(value, suffix):
    if value.endswith(suffix):
        return value[: -len(suffix)]
    return value


class Handler(BaseHTTPRequestHandler):
    def _json(self, status, payload):
        body = json.dumps(payload, separators=(",", ":")).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urlparse(self.path).path
        if path == "/health":
            self._json(200, {"ok": True, "service": "arma-attendance-api", "version": "contract-mock"})
            return
        if not self._authorized():
            self._json(401, {"ok": False, "error": {"code": "unauthorized"}})
            return
        if path.startswith("/v1/ingest-requests/"):
            request_id = unquote(remove_prefix(path, "/v1/ingest-requests/"))
            saved = requests_by_id.get(request_id)
            if saved is None:
                self._json(404, {"ok": False, "error": {"code": "ingest_request_not_found"}})
                return
            self._json(200, {"ok": True, "ingest_request": saved})
            return
        if path.startswith("/v1/operations/") and path.endswith("/attendance"):
            operation_id = remove_suffix(remove_prefix(path, "/v1/operations/"), "/attendance").strip("/")
            if operation_id not in operations:
                self._json(404, {"ok": False, "error": {"code": "operation_not_found"}})
                return
            self._json(200, {"ok": True, "operation_id": operation_id, "attendance": []})
            return
        if path.startswith("/v1/operations/"):
            operation_id = remove_prefix(path, "/v1/operations/").strip("/")
            operation = operations.get(operation_id)
            if operation is None:
                self._json(404, {"ok": False, "error": {"code": "operation_not_found"}})
                return
            self._json(200, {"ok": True, "operation": operation})
            return
        self._json(404, {"ok": False, "error": "not_found"})

    def do_POST(self):
        path = urlparse(self.path).path
        if not self._authorized():
            self._json(401, {"ok": False, "error": {"code": "unauthorized"}})
            return

        if path == "/v1/debug/poke":
            payload = self._payload()
            self._json(
                200,
                {
                    "ok": True,
                    "received": True,
                    "reply": "poke accepted",
                    "echo": payload,
                },
            )
            return

        if path == "/v1/operations/start":
            payload = self._payload()
            request_id = payload.get("request_id")
            if not request_id or not payload.get("server_key"):
                self._json(400, {"ok": False, "error": {"code": "validation_failed"}})
                return
            attendance_error = self._attendance_records_error(payload)
            if attendance_error:
                self._json(
                    400,
                    {
                        "ok": False,
                        "error": {"code": "attendance_records_invalid", "message": attendance_error},
                    },
                )
                return
            if request_id in requests_by_id:
                response = dict(requests_by_id[request_id]["response"])
                response["idempotent"] = True
                self._json(200, response)
                return
            response = self._operation_response("started", payload)
            operations[OPERATION_ID] = {
                "id": OPERATION_ID,
                "status": "started",
                "server_key": payload.get("server_key"),
                "raw_start_payload": payload,
            }
            requests_by_id[request_id] = {
                "request_id": request_id,
                "operation_id": OPERATION_ID,
                "endpoint": "/v1/operations/start",
                "payload": payload,
                "response": response,
            }
            self._json(200, response)
            return

        if path.startswith("/v1/operations/") and path.endswith("/finish"):
            operation_id = remove_suffix(remove_prefix(path, "/v1/operations/"), "/finish").strip("/")
            if operation_id not in operations:
                self._json(404, {"ok": False, "error": {"code": "operation_not_found"}})
                return
            payload = self._payload()
            request_id = payload.get("request_id")
            if not request_id or not payload.get("server_key"):
                self._json(400, {"ok": False, "error": {"code": "validation_failed"}})
                return
            if request_id in requests_by_id:
                response = dict(requests_by_id[request_id]["response"])
                response["idempotent"] = True
                self._json(200, response)
                return
            response = self._operation_response("finished", payload, operation_id)
            operations[operation_id]["status"] = "finished"
            operations[operation_id]["raw_end_payload"] = payload
            requests_by_id[request_id] = {
                "request_id": request_id,
                "operation_id": operation_id,
                "endpoint": "/v1/operations/:operation_id/finish",
                "payload": payload,
                "response": response,
            }
            self._json(200, response)
            return

        self._json(404, {"ok": False, "error": "not_found"})

    def _authorized(self):
        return self.headers.get("Authorization", "") == "Bearer dev-token"

    def _payload(self):
        length = int(self.headers.get("Content-Length", "0"))
        return json.loads(self.rfile.read(length) or b"{}")

    def _operation_response(self, status, payload, operation_id=OPERATION_ID):
        stats_seen = 0
        for player in payload.get("players", []):
            if isinstance(player, dict) and isinstance(player.get("stats"), dict):
                stats_seen += 1
        return {
            "ok": True,
            "operation_id": operation_id,
            "status": status,
            "accepted": True,
            "idempotent": False,
            "normalized": {
                "players_seen": len(payload.get("players", [])),
                "players_ignored_missing_uid": 0,
                "stats_seen": stats_seen if status == "finished" else 0,
            },
        }

    def _attendance_records_error(self, payload):
        records = payload.get("attendance_records")
        if records is None:
            return None
        if not isinstance(records, list):
            return "attendance_records must be an array"
        required_fields = {
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
        for index, record in enumerate(records):
            if not isinstance(record, dict):
                return f"attendance_records[{index}] must be an object"
            missing = sorted(required_fields - set(record))
            if missing:
                return f"attendance_records[{index}] missing {','.join(missing)}"
            if not str(record.get("player_uid", "")).strip():
                return f"attendance_records[{index}] missing player_uid"
            if record.get("attended_seconds", 0) < 0:
                return f"attendance_records[{index}] has negative attended_seconds"
            ratio = record.get("attendance_ratio", 0)
            if ratio < 0 or ratio > 1:
                return f"attendance_records[{index}] attendance_ratio outside 0..1"
        return None

    def log_message(self, format, *args):
        return


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=3000)
    args = parser.parse_args()
    ThreadingHTTPServer((args.host, args.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
