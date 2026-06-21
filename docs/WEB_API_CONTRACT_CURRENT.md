# Current Web API Contract For Extension Alignment

Aligned with the `arma-attendance-web` `web-frontend` branch contract.

This document captures only the API contract relevant to the Arma extension repo.

## Auth

All non-health extension-facing endpoints require:

```http
Authorization: Bearer <API_TOKEN>
Content-Type: application/json
```

Do not log this header or token.

The dedicated-server TOML stores the raw token only:

```toml
[http]
api_token = "aat_arma_server_REPLACE_WITH_REAL_TOKEN"
```

The native extension adds the `Bearer` scheme when building the HTTP header. Do
not put `Bearer ` in the config file.

The TOML `[server].server_key` is the stable server identity. The native
extension injects that configured value into operation start/finish payloads so
SQF cannot accidentally finish with a different server key than the one used to
start the operation.

## Health

```http
GET /health
```

Used by the extension `health` command. This does not require auth.

## Debug Poke

```http
POST /v1/debug/poke
```

Body:

```json
{
  "message": "hello from arma",
  "server_key": "main-unit-server"
}
```

This command remains the lowest-risk smoke path.

## Start Operation

```http
POST /v1/operations/start
```

Required fields:

```json
{
  "request_id": "string, 1-200 chars",
  "server_key": "string, 1-128 chars"
}
```

Optional accepted fields include `payload_version` and `mission`. The route uses passthrough validation, so extra fields are retained. Normalized attendance currently reads players from top-level `players`.

Recommended extension payload:

```json
{
  "request_id": "main-unit-server:start:2026-05-16T22-01-03Z:altis:mission-name",
  "server_key": "main-unit-server",
  "payload_version": 1,
  "mission": {
    "mission_uid": "altis:mission-name:server-time-or-generated-id",
    "mission_name": "Coop Night 12",
    "world_name": "Altis"
  },
  "source": {
    "kind": "arma3-addon",
    "entrypoint": "zeus_module",
    "entrypoint_detail": "Stats: Start Operation",
    "addon": "tcwa3_stats_tracker",
    "extension": "tcwa3_stats_tracker",
    "automation": false
  },
  "players": []
}
```

Expected success shape includes:

```json
{
  "ok": true,
  "operation_id": "uuid",
  "status": "started",
  "accepted": true,
  "idempotent": false,
  "normalized": {
    "players_seen": 0,
    "players_ignored_missing_uid": 0,
    "stats_seen": 0
  }
}
```

The extension must store `operation_id` after success so finish can target it.

## Finish Operation

```http
POST /v1/operations/:operation_id/finish
```

Required body fields:

```json
{
  "request_id": "string, 1-200 chars",
  "server_key": "string, 1-128 chars",
  "outcome": "success | failed"
}
```

Recommended extension payload:

```json
{
  "request_id": "main-unit-server:finish:<operation-id>:<time>",
  "server_key": "main-unit-server",
  "payload_version": 1,
  "outcome": "success",
  "mission": {
    "mission_uid": "same-or-compatible-id",
    "mission_name": "Coop Night 12",
    "world_name": "Altis"
  },
  "source": {
    "kind": "arma3-addon",
    "entrypoint": "zeus_module",
    "entrypoint_detail": "Stats: Finish Operation",
    "addon": "tcwa3_stats_tracker",
    "extension": "tcwa3_stats_tracker",
    "automation": false,
    "stats_source": "arma_getPlayerScores_delta"
  },
  "players": [
    {
      "player_uid": "76561198000000000",
      "name": "Example Player",
      "side": "WEST",
      "group": "Alpha 1-1",
      "role": "Rifleman",
      "unit_class": "B_Soldier_F",
      "vehicle_class": "",
      "stats": {
        "infantry_kills": 12,
        "vehicle_kills": 4,
        "player_kills": 0,
        "ai_kills": 12,
        "friendly_kills": 0,
        "deaths": 2
      },
      "scoreboard_stats": {
        "stats_source": "arma_getPlayerScores_delta",
        "infantry_kills": 12,
        "soft_vehicle_kills": 1,
        "armor_kills": 2,
        "ground_vehicle_kills": 3,
        "air_kills": 1,
        "all_vehicle_kills": 4,
        "deaths": 2,
        "score": 155,
        "baseline": [0, 0, 0, 0, 0, 0],
        "latest": [12, 1, 2, 1, 2, 155]
      }
    }
  ],
  "attendance_records": [
    {
      "player_uid": "76561198000000000",
      "name": "Example Player",
      "present_at_start": true,
      "present_at_end": true,
      "joined_after_start": false,
      "operation_seconds": 3600,
      "attended_seconds": 3600,
      "missed_seconds": 0,
      "attendance_ratio": 1,
      "attendance_percent": 100,
      "attendance_threshold": 0.5,
      "attendance_status": "full",
      "attendance_credit": true,
      "disconnect_count": 0,
      "reconnect_count": 0,
      "side": "WEST",
      "group": "Alpha 1-1",
      "role": "Rifleman",
      "unit_class": "B_Soldier_F",
      "vehicle_class": ""
    }
  ]
}
```

`outcome` is the operation result observed by the addon. Manual Zeus finish and
named finish trigger submissions send `"success"`. The mission-ended fallback
sends `"failed"` for standard Arma failure end types such as `LOSER` and
`KILLED`, and includes the original Arma end type as `source.end_type`.

Expected success shape is similar to start, with `status: "finished"` and `normalized.stats_seen` reflecting players with stats.

`players` remains the compatibility snapshot for players physically present at finish. `attendance_records` is the full operation ledger and should include every UID known to the server during the operation, including players who disconnected before finish.

Current web behavior treats every top-level finish `players[]` entry as present
at end. Players who disconnected before finish must be omitted from top-level
`players[]` and represented in `attendance_records[]` with
`present_at_end=false`.

## Normalized Player Fields

The web normalization accepts these UID and name fields:

```text
UID fields: player_uid, arma_uid, steam_id, uid
Name fields: name, player_name, display_name
```

Use `player_uid` and `name` for clarity. The addon sanitizes player names to
ASCII alphanumeric words separated by single spaces before sending them, so
quotes, control characters, symbols, and non-ASCII text cannot break the SQF
JSON payload boundary.

Metadata fields currently normalized:

```text
side or side_name
group or group_name
role or role_name
unit_class
vehicle_class
stats
```

Stats fields:

```text
infantry_kills
vehicle_kills
player_kills
ai_kills
friendly_kills
deaths
```

V1 addon stats are Arma scoreboard deltas from `getPlayerScores`. The addon
maps infantry, soft vehicle, armor, air, deaths, and score counters into the
six supported normalized fields and preserves the raw split under
`scoreboard_stats`. `vehicle_kills` intentionally includes soft + armor + air
scoreboard kills for current web compatibility. `player_kills` and
`friendly_kills` remain zero until a later event-level attribution sprint.

## Readback Diagnostics

Useful for local and CI contract checks:

```http
GET /v1/ingest-requests/:request_id
GET /v1/operations/:operation_id
GET /v1/operations/:operation_id/attendance
GET /v1/operations/:operation_id/payloads
GET /v1/operations?server_key=<server_key>&limit=10
```

These require bearer auth.

Native command mapping:

```text
ingest_request_get <request_id>       -> GET /v1/ingest-requests/:request_id
operation_get <operation_id>          -> GET /v1/operations/:operation_id
operation_attendance_get <operation_id> -> GET /v1/operations/:operation_id/attendance
operation_payloads_get <operation_id> -> GET /v1/operations/:operation_id/payloads
operation_list [limit]                -> GET /v1/operations?server_key=<configured-server-key>&limit=<limit>
```

Operation start and finish are queued before HTTP when the queue is enabled.
Network failures and 5xx responses remain retryable. Terminal 4xx validation
errors, including `server_key_mismatch`, are surfaced to SQF and removed from
the retry queue so they do not loop forever.
