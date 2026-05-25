# TCWA3 Stats Tracker Workshop Server Extension

The TCWA3 Stats Tracker release is split into two Workshop items:

```text
TCWA3 Stats Tracker
  Public client/server addon with CBA dependency, Zeus modules, automation SQF, tcwa3_stats_tracker_main.pbo, signatures, and public key.

TCWA3 Stats Tracker Server Extension
  Hidden or unlisted server-only package with native extension binaries, metadata, example config, readmes, and checksums.
```

Load the public addon with `-mod` and the server-only package with `-serverMod`:

```bash
export TCWA3_STATS_CONFIG_PATH="/etc/tcwa3-stats-tracker/main.toml"

./arma3server_x64 \
  -mod=@CBA_A3\;@tcwa3_stats_tracker \
  -serverMod=@tcwa3_stats_tracker_server \
  -profiles=profiles/main
```

The server extension package uses the native binary basename `tcwa3_stats_tracker`:

```text
@tcwa3_stats_tracker_server/
  addons/
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

The `addons/` PBO is an inert Publisher marker so Arma 3 Publisher can upload the server-only Workshop item. Runtime behavior still comes from the native extension files and the public client/server addon.

## Config

Real config must live outside Steam Workshop-managed folders so updates cannot overwrite server-specific secrets:

```bash
install -d -m 700 /etc/tcwa3-stats-tracker
cp @tcwa3_stats_tracker_server/tcwa3_stats_tracker.example.toml /etc/tcwa3-stats-tracker/main.toml
chmod 600 /etc/tcwa3-stats-tracker/main.toml
```

The native extension searches in this order:

```text
TCWA3_STATS_CONFIG_PATH
AASE_CONFIG_PATH
tcwa3_stats_tracker.toml beside the loaded extension
arma_attendance.toml beside the loaded extension
```

`TCWA3_STATS_CONFIG_PATH` is preferred for new deployments. `AASE_CONFIG_PATH` remains supported for migration.

## SteamCMD Multi-Server Updates

Use one shared Workshop cache and per-server symlinks:

```text
/srv/steamcmd/steamapps/workshop/content/107410/
  <client_item_id>/
  <server_extension_item_id>/

/srv/arma3/instances/main/
  @tcwa3_stats_tracker -> /srv/steamcmd/steamapps/workshop/content/107410/<client_item_id>
  @tcwa3_stats_tracker_server -> /srv/steamcmd/steamapps/workshop/content/107410/<server_extension_item_id>
  profiles/

/srv/arma3/instances/training/
  @tcwa3_stats_tracker -> /srv/steamcmd/steamapps/workshop/content/107410/<client_item_id>
  @tcwa3_stats_tracker_server -> /srv/steamcmd/steamapps/workshop/content/107410/<server_extension_item_id>
  profiles/
```

Each server should use a unique external config and `server_key`:

```text
/etc/tcwa3-stats-tracker/main.toml
/etc/tcwa3-stats-tracker/training.toml
/etc/tcwa3-stats-tracker/events.toml
```

Example update flow:

```bash
steamcmd +force_install_dir /srv/steamcmd \
  +login "$STEAM_USERNAME" \
  +workshop_download_item 107410 "$TCWA3_CLIENT_ITEM_ID" validate \
  +workshop_download_item 107410 "$TCWA3_SERVER_EXTENSION_ITEM_ID" validate \
  +quit

ln -sfn /srv/steamcmd/steamapps/workshop/content/107410/"$TCWA3_CLIENT_ITEM_ID" /srv/arma3/instances/main/@tcwa3_stats_tracker
ln -sfn /srv/steamcmd/steamapps/workshop/content/107410/"$TCWA3_SERVER_EXTENSION_ITEM_ID" /srv/arma3/instances/main/@tcwa3_stats_tracker_server

test -f /srv/arma3/instances/main/@tcwa3_stats_tracker_server/tcwa3_stats_tracker_x64.so
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
