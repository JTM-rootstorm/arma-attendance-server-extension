# TCWA3 Stats Tracker Workshop Package

The TCWA3 Stats Tracker release ships as one Workshop item:

```text
TCWA3 Stats Tracker Server Extension
  Client/server CBA addon plus native extension binaries, metadata, example config, readmes, and checksums.
```

Load the combined package with `-mod` on clients and the dedicated server:

```bash
./arma3server_x64 \
  -mod=@CBA_A3\;@tcwa3_stats_tracker_server \
  -profiles=profiles/main
```

The package uses the native binary basename `tcwa3_stats_tracker`:

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

`tcwa3_stats_tracker_main.pbo` contains the runtime addon logic. The small
`tcwa3_stats_tracker_server_publisher.pbo` remains in the package as Publisher
metadata. Clients download the native extension files too, but only the
dedicated server calls them.

## Config

The preferred deployment keeps the real config beside the loaded native extension, because some hosts cannot read outside their mod folders:

```bash
cp @tcwa3_stats_tracker_server/tcwa3_stats_tracker.example.toml @tcwa3_stats_tracker_server/tcwa3_stats_tracker.toml
chmod 600 @tcwa3_stats_tracker_server/tcwa3_stats_tracker.toml
```

The native extension searches in this order:

```text
tcwa3_stats_tracker.toml beside the loaded extension
arma_attendance.toml beside the loaded extension
TCWA3_STATS_CONFIG_PATH
AASE_CONFIG_PATH
```

`TCWA3_STATS_CONFIG_PATH` and `AASE_CONFIG_PATH` remain supported for hosts that can safely read external paths, but the mod-folder config wins when present. Queue paths in TOML may be relative; relative queue paths are resolved beside the loaded `.so`/`.dll`.

## SteamCMD Multi-Server Updates

Use one shared Workshop cache for downloads. Copy or overlay the combined
folder per server so each instance can keep its own writable config and queue
files beside the native extension:

```text
/srv/steamcmd/steamapps/workshop/content/107410/
  <server_extension_item_id>/

/srv/arma3/instances/main/
  @tcwa3_stats_tracker_server/
    addons/tcwa3_stats_tracker_main.pbo
    tcwa3_stats_tracker_x64.so
    tcwa3_stats_tracker.toml
    tcwa3_stats_tracker_queue.ndjson
  profiles/

/srv/arma3/instances/training/
  @tcwa3_stats_tracker_server/
    addons/tcwa3_stats_tracker_main.pbo
    tcwa3_stats_tracker_x64.so
    tcwa3_stats_tracker.toml
    tcwa3_stats_tracker_queue.ndjson
  profiles/
```

Each server should use a unique config and `server_key`. Prefer one copied config per server extension folder:

```text
/srv/arma3/instances/main/@tcwa3_stats_tracker_server/tcwa3_stats_tracker.toml
/srv/arma3/instances/training/@tcwa3_stats_tracker_server/tcwa3_stats_tracker.toml
/srv/arma3/instances/events/@tcwa3_stats_tracker_server/tcwa3_stats_tracker.toml
```

Example update flow:

```bash
steamcmd +force_install_dir /srv/steamcmd \
  +login "$STEAM_USERNAME" \
  +workshop_download_item 107410 "$TCWA3_SERVER_EXTENSION_ITEM_ID" validate \
  +quit

rsync -a --delete \
  --exclude 'tcwa3_stats_tracker.toml' \
  --exclude 'arma_attendance.toml' \
  --exclude '*.ndjson' \
  /srv/steamcmd/steamapps/workshop/content/107410/"$TCWA3_SERVER_EXTENSION_ITEM_ID"/ \
  /srv/arma3/instances/main/@tcwa3_stats_tracker_server/

test -f /srv/arma3/instances/main/@tcwa3_stats_tracker_server/tcwa3_stats_tracker_x64.so
test -f /srv/arma3/instances/main/@tcwa3_stats_tracker_server/addons/tcwa3_stats_tracker_main.pbo
ldd /srv/arma3/instances/main/@tcwa3_stats_tracker_server/tcwa3_stats_tracker_x64.so
```

Some environments require a Steam account that owns Arma 3 for Workshop downloads. Plan for authenticated SteamCMD and Steam Guard instead of assuming anonymous pulls.

## Local Assembly and Audit

Build the native extension first, then assemble the server Workshop package:

```bash
cmake -S extension -B build/extension-linux -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/extension-linux --config RelWithDebInfo
tools/assemble_workshop_server_extension.sh
```

The assembly script runs `tools/audit_workshop_package.py` before reporting success. The audit rejects real TOML config, private BI keys, queue files, logs, bearer headers, and token-looking values. Only example TOML files belong in the Workshop package.

## Manual GitHub Workflow

`.github/workflows/workshop-server-extension-upload.yml` is `workflow_dispatch` only. It always builds Linux and Windows native artifacts, assembles `@tcwa3_stats_tracker_server`, audits the package, and uploads the package as a GitHub Actions artifact.

Steam Workshop upload is gated by the `upload_to_workshop` input and these repository secrets:

```text
STEAM_USERNAME
STEAM_PASSWORD
STEAM_WORKSHOP_SERVER_EXTENSION_ITEM_ID
STEAM_TOTP_SECRET
```

The workflow uses Arma 3 `appId` `107410`. Pull requests and normal pushes never upload to Workshop.
