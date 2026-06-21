# CI and Release Packaging

Phase 0 CI proves three things without private key material:

- HEMTT can check and build the addon skeleton.
- Linux produces `tcwa3_stats_tracker.so` and `tcwa3_stats_tracker_x64.so`.
- Windows produces `tcwa3_stats_tracker_x64.dll`.
- Payload examples and static one-shot Zeus module cleanup checks pass.
- Linux artifacts do not depend on server-provided `libcurl`, `libstdc++`, or `libgcc_s`.
- Linux artifacts are built in an Ubuntu 20.04 container and audited to avoid requiring GLIBC newer than 2.31.
- Windows artifacts are built with the static vcpkg triplet and static MSVC runtime so the Workshop server package does not need extra curl, TLS, or runtime DLLs beside `tcwa3_stats_tracker_x64.dll`.
- Windows artifacts are checked with `tools/verify-windows-dll-static.ps1`, which fails CI if `dumpbin /dependents` shows curl, TLS, compression, or MSVC runtime DLL dependencies.

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

The full release script runs `hemtt release --no-archive` for the runtime addon
and server-extension Publisher marker addon, builds the Linux extension, copies
freshly generated public `.bikey` files, audits the combined package, writes
checksums, and creates `dist/tcwa3-stats-tracker-v0.1.0-sprint1.zip` by
default. The Workshop assembly script builds only
`dist/workshop-server-extension/@tcwa3_stats_tracker_server` and runs the same
package audit.

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
  README-server-install.md
  README-workshop-server-extension.md
  README-server-install.txt
  checksums.sha256
```

Clients and the dedicated server load this one folder with `-mod`. Clients will
download the extension binaries, but only the dedicated server calls the native
extension. The small Publisher marker PBO exists so Arma 3 Publisher has package
metadata; runtime logic lives in `tcwa3_stats_tracker_main.pbo`.
The TCWA3 rebrand uses the `tcwa3_stats_tracker` addon namespace, SQF
callExtension basename, and native binary basename. See
[WORKSHOP_SERVER_EXTENSION.md](WORKSHOP_SERVER_EXTENSION.md) for the Workshop
package and multi-server SteamCMD update flow.

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

The extension first looks for `tcwa3_stats_tracker.toml` or `arma_attendance.toml` beside the loaded `.so`/`.dll`. `TCWA3_STATS_CONFIG_PATH` and `AASE_CONFIG_PATH` remain supported as fallbacks for hosts that can safely read external paths.

Operation start and finish submissions use a local NDJSON queue when enabled. The default queue files are `arma_attendance_queue.ndjson` and `arma_attendance_queue.sent.ndjson` beside the loaded extension binary unless overridden in TOML or with `AASE_QUEUE_FILE` and `AASE_QUEUE_SENT_FILE`. Relative queue paths are resolved beside the loaded extension binary. Queue records store request bodies and metadata, never bearer tokens.

## Windows Load Diagnostics

If Windows logs `Call extension 'tcwa3_stats_tracker' could not be loaded: The specified module could not be found`, confirm the server Workshop package was assembled from a CI artifact built after the static Windows packaging change. That message usually means Windows found `tcwa3_stats_tracker_x64.dll` but could not load one of its dependent DLLs. The intended release artifact should be self-contained and should not require extra vcpkg, curl, OpenSSL, zlib, or MSVC runtime DLLs in the server mod folder.

The Windows CI lane enforces this by running:

```powershell
./tools/verify-windows-dll-static.ps1 -SearchRoot build/extension-windows
```

The verifier allows normal Windows system DLLs, but rejects dependencies such as `libcurl*.dll`, `libssl*.dll`, `libcrypto*.dll`, `zlib*.dll`, `zstd*.dll`, `brotli*.dll`, `nghttp2*.dll`, `msvcp*.dll`, and `vcruntime*.dll`.
