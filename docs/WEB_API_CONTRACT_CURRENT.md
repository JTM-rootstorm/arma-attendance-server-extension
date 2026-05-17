# Current Web API Contract For Extension Alignment

Verified against local `arma-attendance-web` commit `d9523d2`.

This document captures only the API contract relevant to the Arma extension repo.

## Auth

All non-health extension-facing endpoints require:

```http
Authorization: Bearer <API_TOKEN>
Content-Type: application/json
```

Do not log this header or token.

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
    "kind": "arma3-extension",
    "extension_version": "0.1.0",
    "addon_version": "0.1.0"
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
  "server_key": "string, 1-128 chars"
}
```

Recommended extension payload:

```json
{
  "request_id": "main-unit-server:finish:<operation-id>:<time>",
  "server_key": "main-unit-server",
  "payload_version": 1,
  "mission": {
    "mission_uid": "same-or-compatible-id",
    "mission_name": "Coop Night 12",
    "world_name": "Altis"
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
        "infantry_kills": 0,
        "vehicle_kills": 0,
        "player_kills": 0,
        "ai_kills": 0,
        "friendly_kills": 0,
        "deaths": 0
      }
    }
  ]
}
```

Expected success shape is similar to start, with `status: "finished"` and `normalized.stats_seen` reflecting players with stats.

## Normalized Player Fields

The web normalization accepts these UID and name fields:

```text
UID fields: player_uid, arma_uid, steam_id, uid
Name fields: name, player_name, display_name
```

Use `player_uid` and `name` for clarity.

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
