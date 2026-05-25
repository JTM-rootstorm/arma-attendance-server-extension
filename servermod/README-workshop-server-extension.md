# TCWA3 Stats Tracker Server Extension Workshop Package

This folder is the server-only Workshop package for the native Arma extension. It is meant to be hidden or unlisted on Steam Workshop and loaded with `-serverMod`, not `-mod`.

```text
@tcwa3_stats_tracker_server/
  arma_attendance.so
  arma_attendance_x64.so
  arma_attendance_x64.dll
  tcwa3_stats_tracker.example.toml
  arma_attendance.example.toml
  mod.cpp
  meta.cpp
  README-server-install.md
  README-workshop-server-extension.md
  checksums.sha256
```

The extension basename remains `arma_attendance` for this transition release. SQF still calls the native binary with `"arma_attendance" callExtension [...]`, while addon helper functions use the `TCWA3_fnc_*` namespace.

## External Config

Do not place real config in this Workshop folder. Store one config per dedicated server outside Steam-managed content and point the extension at it:

```bash
export TCWA3_STATS_CONFIG_PATH="/etc/tcwa3-stats-tracker/main.toml"
```

`AASE_CONFIG_PATH` remains supported for older launch scripts. `TCWA3_STATS_CONFIG_PATH` wins when both are present.

## Package Safety

The package audit blocks real TOML files, private BI keys, queue files, logs, bearer headers, and token-looking values. Only `*.example.toml` templates belong in this package.
