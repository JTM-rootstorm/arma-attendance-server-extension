# CI and Release Packaging

Phase 0 CI proves three things without private key material:

- HEMTT can check and build the addon skeleton.
- Linux produces `arma_attendance.so` and `arma_attendance_x64.so`.
- Windows produces `arma_attendance_x64.dll`.
- Linux artifacts do not depend on server-provided `libcurl`, `libstdc++`, or `libgcc_s`.
- Linux artifacts are built in an Ubuntu 20.04 container and audited to avoid requiring GLIBC newer than 2.31.

CI preview artifacts are intentionally unsigned. Trusted local signing remains a manual step until the installed HEMTT key-reuse behavior is confirmed on the dev machine.

## Local Commands

```bash
export HEMTT_BI_TOOLS="/mnt/game_one/SteamLibrary/steamapps/common/Arma 3 Tools/"
hemtt check
hemtt build
cmake -S extension -B build/extension-linux -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/extension-linux --config RelWithDebInfo
ctest --test-dir build/extension-linux --output-on-failure
```

## Trusted Signing

Private BI signing keys must stay outside this repository. Locate local keys under:

```bash
$HOME/Documents/Programming/bikey
```

Before automating trusted signing, inspect the installed HEMTT behavior:

```bash
hemtt --help
hemtt keys --help
hemtt release --help
```

Only public `.bikey` files may be copied into release artifacts. Never copy `*.biprivatekey` or `*.hemttprivatekey` into the repo or package output.

## Release Shape

```text
@arma_attendance/
  addons/
  keys/
  mod.cpp
  meta.cpp

@arma_attendance_server/
  arma_attendance.so
  arma_attendance_x64.so
  arma_attendance_x64.dll
  arma_attendance.example.toml
  README-server-install.txt
```

The public addon may be loaded by clients and the server. The server extension package is dedicated-server only.

## Linux Load Diagnostics

If Arma logs `Call extension 'arma_attendance' could not be loaded`, it found a candidate extension but the dynamic loader rejected it. First verify `@arma_attendance_server` contains both Linux names:

```bash
ls -l @arma_attendance_server/arma_attendance.so @arma_attendance_server/arma_attendance_x64.so
```

Then, in the same container or host that runs `arma3server_x64`, run:

```bash
file @arma_attendance_server/arma_attendance_x64.so
ldd @arma_attendance_server/arma_attendance_x64.so
```

The file must be an x86-64 ELF shared object. No `ldd` line should say `not found`.

The extension reads `arma_attendance.toml` from the loaded extension directory, such as `@arma_attendance_server/arma_attendance.toml`. If a server manager requires storing the file somewhere else, set `AASE_CONFIG_PATH` to the absolute TOML file path.
