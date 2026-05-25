# CI and Release Packaging

Phase 0 CI proves three things without private key material:

- HEMTT can check and build the addon skeleton.
- Linux produces `tcwa3_stats_tracker.so` and `tcwa3_stats_tracker_x64.so`.
- Windows produces `tcwa3_stats_tracker_x64.dll`.
- Payload examples and static one-shot Zeus module cleanup checks pass.
- Linux artifacts do not depend on server-provided `libcurl`, `libstdc++`, or `libgcc_s`.
- Linux artifacts are built in an Ubuntu 20.04 container and audited to avoid requiring GLIBC newer than 2.31.

CI preview artifacts are intentionally unsigned. Trusted local signing uses `hemtt release --no-archive`, which creates signed PBOs under `.hemttout/release` without copying private keys into the repo.

## Local Commands

```bash
export HEMTT_BI_TOOLS="/mnt/game_one/SteamLibrary/steamapps/common/Arma 3 Tools/"
hemtt check
hemtt build
cmake -S extension -B build/extension-linux -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/extension-linux --config RelWithDebInfo
ctest --test-dir build/extension-linux --output-on-failure
```

Release assembly:

```bash
tools/assemble_release.sh
tools/assemble_workshop_server_extension.sh
```

The full release script runs `hemtt release --no-archive` for a locally signed addon, builds the Linux extension, copies the freshly generated public `.bikey`, audits the server package, writes checksums, and creates `dist/tcwa3-stats-tracker-v0.1.0-sprint1.zip` by default. The Workshop server-extension assembly script builds only `dist/workshop-server-extension/@tcwa3_stats_tracker_server` and runs the same package audit.

## Trusted Signing

Private BI signing keys must stay outside this repository. Locate local keys under:

```bash
$HOME/Documents/Programming/bikey
```

The installed HEMTT behavior was checked with:

```bash
hemtt --help
hemtt keys --help
hemtt release --help
```

Only public `.bikey` files may be copied into release artifacts. Never copy `*.biprivatekey` or `*.hemttprivatekey` into the repo or package output.

## Release Shape

```text
@tcwa3_stats_tracker/
  addons/
    tcwa3_stats_tracker_main.pbo
  keys/
  mod.cpp
  meta.cpp

@tcwa3_stats_tracker_server/
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

The public addon may be loaded by clients and the server. The server extension package is dedicated-server only.
The TCWA3 rebrand uses the `tcwa3_stats_tracker` client addon namespace, SQF callExtension basename, and native binary basename. See [WORKSHOP_SERVER_EXTENSION.md](WORKSHOP_SERVER_EXTENSION.md) for the server-only Workshop package and multi-server SteamCMD update flow.

## Linux Load Diagnostics

If Arma logs `Call extension 'tcwa3_stats_tracker' could not be loaded`, it found a candidate extension but the dynamic loader rejected it. First verify `@tcwa3_stats_tracker_server` contains both Linux names:

```bash
ls -l @tcwa3_stats_tracker_server/tcwa3_stats_tracker.so @tcwa3_stats_tracker_server/tcwa3_stats_tracker_x64.so
```

Then, in the same container or host that runs `arma3server_x64`, run:

```bash
file @tcwa3_stats_tracker_server/tcwa3_stats_tracker_x64.so
ldd @tcwa3_stats_tracker_server/tcwa3_stats_tracker_x64.so
```

The file must be an x86-64 ELF shared object. No `ldd` line should say `not found`.

The extension prefers `TCWA3_STATS_CONFIG_PATH`, then `AASE_CONFIG_PATH`, then `tcwa3_stats_tracker.toml` and `arma_attendance.toml` beside the loaded extension. Real config should live outside Workshop-managed folders, such as `/etc/tcwa3-stats-tracker/main.toml`.

Operation start and finish submissions use a local NDJSON queue when enabled. The default queue files are `arma_attendance_queue.ndjson` and `arma_attendance_queue.sent.ndjson` beside the server process working directory unless overridden in TOML or with `AASE_QUEUE_FILE` and `AASE_QUEUE_SENT_FILE`. Queue records store request bodies and metadata, never bearer tokens.
