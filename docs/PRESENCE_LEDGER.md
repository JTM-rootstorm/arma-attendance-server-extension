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

## Scoreboard Stats

V1 operation stats come from Arma's multiplayer scoreboard counters through
`getPlayerScores`. The addon stores UID-keyed scoreboard baselines and latest
snapshots while an operation is active:

- start-operation initialization captures a baseline and latest snapshot for
  players present at start
- late joiners receive their baseline the first time the presence loop sees
  their UID
- reconnects preserve the original baseline and resume latest updates
- disconnect handling attempts one last snapshot if the unit is still
  resolvable, otherwise the last periodic snapshot remains authoritative
- finish captures current players again before computing deltas

The normalized web-compatible `stats` object is computed from clamped deltas:

```text
infantry_kills = delta infantry
vehicle_kills = delta soft + delta armor + delta air
player_kills = 0
ai_kills = delta infantry
friendly_kills = 0
deaths = delta deaths
```

Detailed scoreboard split and the raw baseline/latest arrays are emitted under
`scoreboard_stats`, not inside normalized `stats`. The previous event-level
kill ledger remains disabled by default behind
`AASE_enableExperimentalKillLedger`; exact victim, weapon, and friendly-fire
attribution are future work.

The attendance threshold defaults to `0.5`. Records at or above the threshold receive `attendance_credit: true`, full-operation records receive `attendance_status: "full"`, threshold-passing partial records receive `"partial"`, and below-threshold records receive `"absent"`.
