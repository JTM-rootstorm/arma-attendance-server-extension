# TCWA3 Stats Tracker Workshop Package

This folder is the combined Workshop package for the TCWA3 Stats Tracker CBA
addon and native Arma extension. Load it with `-mod` on clients and dedicated
servers.

```text
@tcwa3_stats_tracker_server/
  addons/
    tcwa3_stats_tracker_main.pbo
    tcwa3_stats_tracker_server_publisher.pbo
  keys/
  tcwa3_stats_tracker.so
  tcwa3_stats_tracker_x64.so
  tcwa3_stats_tracker_x64.dll
  tcwa3_stats_tracker.example.toml
  arma_attendance.example.toml
  mod.cpp
  meta.cpp
  README-server-install.md
  README-workshop-server-extension.md
  checksums.sha256
```

The extension basename is `tcwa3_stats_tracker`. SQF calls the native binary
with `"tcwa3_stats_tracker" callExtension [...]`, while addon helper functions
use the `TCWA3_fnc_*` namespace. The `tcwa3_stats_tracker_main.pbo` file
contains runtime addon logic. The `tcwa3_stats_tracker_server_publisher.pbo`
file remains as a small Publisher marker.

## Config

Copy the template beside the loaded extension binary and edit the real values there:

```bash
cp @tcwa3_stats_tracker_server/tcwa3_stats_tracker.example.toml @tcwa3_stats_tracker_server/tcwa3_stats_tracker.toml
chmod 600 @tcwa3_stats_tracker_server/tcwa3_stats_tracker.toml
```

The extension checks `tcwa3_stats_tracker.toml` and `arma_attendance.toml` beside the loaded `.so`/`.dll` before external path environment variables. `TCWA3_STATS_CONFIG_PATH` and `AASE_CONFIG_PATH` remain supported for older launch scripts when no mod-folder config is present.

## Package Safety

The package audit blocks real TOML files, private BI keys, queue files, logs, bearer headers, and token-looking values. Only `*.example.toml` templates belong in this package.
