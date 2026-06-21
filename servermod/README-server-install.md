# TCWA3 Stats Tracker Install

Copy `@tcwa3_stats_tracker_server` to clients and the dedicated server.

This release uses the TCWA3 naming scheme for public folders, Workshop metadata, SQF functions, and native extension files.

Recommended launch flags:

```text
-mod=@CBA_A3;@tcwa3_stats_tracker_server
```

The package includes both the CBA addon PBO and native extension files. Clients
download the extension binaries too, but only the dedicated server calls them.

## Config

```bash
cp @tcwa3_stats_tracker_server/tcwa3_stats_tracker.example.toml @tcwa3_stats_tracker_server/tcwa3_stats_tracker.toml
chmod 600 @tcwa3_stats_tracker_server/tcwa3_stats_tracker.toml
```

Edit the real config with the API base URL, API token, and server key. The extension prefers `tcwa3_stats_tracker.toml` or `arma_attendance.toml` beside the loaded `.so`/`.dll`, because some hosts cannot read outside mod folders. `TCWA3_STATS_CONFIG_PATH` and `AASE_CONFIG_PATH` remain supported as fallbacks for hosts that can safely read external paths.

## Linux Diagnostics

Run these in the same Linux container or host that runs `arma3server_x64`:

```bash
file @tcwa3_stats_tracker_server/tcwa3_stats_tracker.so
ldd @tcwa3_stats_tracker_server/tcwa3_stats_tracker.so
ldd @tcwa3_stats_tracker_server/tcwa3_stats_tracker_x64.so
```

No `ldd` line should say `not found`.

## Smoke Flow

1. Start the dedicated server with CBA and `@tcwa3_stats_tracker_server`.
2. Open Zeus.
3. Place `Stats: Debug API Poke`.
4. Place `Stats: Start Operation`.
5. Place `Stats: Finish Operation`.
6. Check the server RPT for compact JSON responses.
7. Check web API ingest/readback if available.

Queue files default beside the loaded extension binary. Relative queue paths in TOML are resolved beside the `.so`/`.dll`:

```text
@tcwa3_stats_tracker_server/tcwa3_stats_tracker_queue.ndjson
@tcwa3_stats_tracker_server/tcwa3_stats_tracker_queue.sent.ndjson
```

Queue files must not contain bearer tokens.
