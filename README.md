# TCWA3 Stats Tracker Server Extension

Phase 0 proved the minimal server-side path between an Arma 3 Zeus module and the external TCWA3 Stats Tracker web API:

```text
CBA addon -> Zeus debug module -> server SQF -> callExtension -> native extension -> HTTP API poke
```

This repository owns only the Arma addon wrapper, Zeus/debug module plumbing, native server extension, CI, and release packaging. The website, API implementation, database, dashboards, and login flow are external to this repo.

The current sprint keeps that debug path intact while adding operation start/finish submission toward the web API documented in [docs/WEB_API_CONTRACT_CURRENT.md](docs/WEB_API_CONTRACT_CURRENT.md). Actual dedicated-server validation is not required for this sprint.

## Packages

The client/server addon and server-only extension are packaged separately:

```text
@tcwa3_stats_tracker/
  addons/
    tcwa3_stats_tracker_main.pbo
  keys/
  mod.cpp
  meta.cpp

@tcwa3_stats_tracker_server/
  addons/
    tcwa3_stats_tracker_server_publisher.pbo
  keys/
  tcwa3_stats_tracker.so
  tcwa3_stats_tracker_x64.so
  tcwa3_stats_tracker_x64.dll
  tcwa3_stats_tracker.example.toml
  arma_attendance.example.toml
  README-server-install.md
  README-workshop-server-extension.md
  README-server-install.txt
  checksums.sha256
```

Recommended dedicated server launch shape:

```text
-mod=@CBA_A3;@tcwa3_stats_tracker -serverMod=@tcwa3_stats_tracker_server
```

This is a compatibility-first rebrand from the previous `Arma Attendance` name. Public package names, client addon PBOs, SQF functions, and native extension binaries now use `TCWA3 Stats Tracker` / `tcwa3_stats_tracker` naming.

If the RPT says `Call extension 'tcwa3_stats_tracker' could not be loaded`, verify that both `tcwa3_stats_tracker.so` and `tcwa3_stats_tracker_x64.so` are present in `@tcwa3_stats_tracker_server`. Then run `ldd @tcwa3_stats_tracker_server/tcwa3_stats_tracker_x64.so` inside the same Linux container that runs `arma3server_x64`. Any `not found` dependency will prevent Arma from loading the extension. If dependencies are present, also confirm the container has glibc 2.31 or newer with `ldd --version`.

## Local Validation

See [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md) for the full local setup notes.

```bash
export HEMTT_BI_TOOLS="/mnt/game_one/SteamLibrary/steamapps/common/Arma 3 Tools/"
hemtt check
hemtt build

cmake -S extension -B build/extension-linux -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/extension-linux --config RelWithDebInfo
ctest --test-dir build/extension-linux --output-on-failure
tools/assemble_workshop_server_extension.sh
python3 tools/test_workshop_package_audit.py
```

The native extension first looks for `tcwa3_stats_tracker.toml` or `arma_attendance.toml` beside the loaded `.so`/`.dll`. `TCWA3_STATS_CONFIG_PATH` and `AASE_CONFIG_PATH` remain supported as fallbacks for hosts that can safely read external paths. Relative queue paths are resolved beside the loaded extension binary so config and queue state can stay inside the server mod folder. Commit only `servermod/*.example.toml`; keep real tokens, queue files, logs, and server config out of git and source archives.

## CBA Automation Settings

The addon registers server/global CBA settings under `TCWA3 Stats Tracker / Automation`.
Automation is manual-only by default:

```sqf
force AASE_autoStartMode = 0;
force AASE_autoFinishMode = 0;
force AASE_enableMissionEndFallback = false;
```

Server operators can later enable named trigger or delayed start automation with
CBA settings without changing API tokens or native extension configuration.
The Zeus modules remain available as manual controls for debug poke, operation
start, and operation finish. Manual finish sends operation `outcome: "success"`;
the mission-ended fallback sends `outcome: "failed"` for Arma failure end types
such as `LOSER` and `KILLED`, plus failure-like custom end names.

## Native Commands

The extension currently supports:

```text
version
reload_config
config
health
poke
operation_start
operation_finish
ingest_request_get
operation_get
operation_attendance_get
queue_status
queue_flush
queue_compact
```

`operation_start` accepts one JSON object argument or generates a minimal smoke payload with configured `server_key`. `operation_finish` accepts an operation ID plus optional JSON payload, or one JSON object containing `operation_id`; missing finish payload `outcome` defaults to `"success"`. Responses are compact JSON wrappers with `ok`, `command`, `http_status`, and the web API response body when available.

Operation start and finish submissions are written to a local NDJSON queue before send when queueing is enabled. `queue_flush` retries pending records, while `queue_status` reports pending and sent counts.
