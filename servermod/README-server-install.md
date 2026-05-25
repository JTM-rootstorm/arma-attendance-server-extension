# TCWA3 Stats Tracker Server Install

Copy `@tcwa3_stats_tracker` to clients and the dedicated server. Copy `@tcwa3_stats_tracker_server` to the dedicated server only.

This is the compatibility release for the old `Arma Attendance` naming. The public folders and Workshop metadata are now TCWA3-facing, but the native extension files remain named `arma_attendance.*` so existing SQF `callExtension` calls continue to work.

Recommended launch flags:

```text
-mod=@CBA_A3;@tcwa3_stats_tracker -serverMod=@tcwa3_stats_tracker_server
```

## Config

```bash
install -d -m 700 /etc/tcwa3-stats-tracker
cp @tcwa3_stats_tracker_server/tcwa3_stats_tracker.example.toml /etc/tcwa3-stats-tracker/main.toml
chmod 600 /etc/tcwa3-stats-tracker/main.toml
export TCWA3_STATS_CONFIG_PATH=/etc/tcwa3-stats-tracker/main.toml
```

Edit the real config with the API base URL, API token, and server key. Keep this real config outside any Steam Workshop-managed folder so Workshop updates cannot overwrite it. `TCWA3_STATS_CONFIG_PATH` is preferred and checked before the backward-compatible `AASE_CONFIG_PATH`.

## Linux Diagnostics

Run these in the same Linux container or host that runs `arma3server_x64`:

```bash
file @tcwa3_stats_tracker_server/arma_attendance.so
ldd @tcwa3_stats_tracker_server/arma_attendance.so
ldd @tcwa3_stats_tracker_server/arma_attendance_x64.so
```

No `ldd` line should say `not found`.

## Smoke Flow

1. Start the dedicated server with CBA, `@tcwa3_stats_tracker`, and `@tcwa3_stats_tracker_server`.
2. Open Zeus.
3. Place `Stats: Debug API Poke`.
4. Place `Stats: Start Operation`.
5. Place `Stats: Finish Operation`.
6. Check the server RPT for compact JSON responses.
7. Check web API ingest/readback if available.

Queue files should live outside the Workshop folder:

```text
/var/lib/tcwa3-stats-tracker/main/queue.ndjson
/var/lib/tcwa3-stats-tracker/main/sent.ndjson
```

Queue files must not contain bearer tokens.
