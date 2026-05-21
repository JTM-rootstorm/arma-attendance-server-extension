# Presence Ledger

The addon keeps a server-only UID-keyed presence ledger while an operation is active. The ledger starts after the web API accepts `operation_start` and returns an `operation_id`.

Tracked state is keyed by Arma UID and records:

- first and last seen offsets
- present-at-start and present-at-end flags
- attended seconds and missed seconds
- attendance threshold, ratio, percent, status, and credit
- disconnect and reconnect counts
- latest side, group, role, unit class, and vehicle class metadata
- canonical stats: `infantry_kills`, `vehicle_kills`, `player_kills`,
  `ai_kills`, `friendly_kills`, and `deaths`

`PlayerConnected` marks a UID present as soon as the server sees the connection event. `PlayerDisconnected` closes the active interval without removing the UID. A periodic server reconcile loop also scans `allPlayers` so late joins and missed events converge before finish.

At finish, the addon finalizes every known UID into top-level `attendance_records` and keeps the existing top-level `players` array for the physically present-at-end snapshot with stats. The native extension does not calculate attendance; it forwards the JSON payload to the web API.

Stats stay UID-keyed in the same ledger, so respawn and reconnect do not drop
accumulated counters. Missing stats default to zero in both top-level finish
`players[]` snapshots and `attendance_records[]`.

The attendance threshold defaults to `0.5`. Records at or above the threshold receive `attendance_credit: true`, full-operation records receive `attendance_status: "full"`, threshold-passing partial records receive `"partial"`, and below-threshold records receive `"absent"`.
