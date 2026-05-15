# Arma Attendance Server Extension

Phase 0 proves the minimal server-side path between an Arma 3 Zeus module and the external Arma Attendance web API:

```text
CBA addon -> Zeus debug module -> server SQF -> callExtension -> native extension -> HTTP API poke
```

This repository owns only the Arma addon wrapper, Zeus/debug module plumbing, native server extension, CI, and release packaging. The website, API implementation, database, dashboards, and login flow are external to this repo.

Phase 0 intentionally does not collect attendance, Steam IDs, player data, kills, deaths, vehicle kills, or mission framework events.

## Packages

The client/server addon and server-only extension are packaged separately:

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

Recommended dedicated server launch shape:

```text
-mod=@CBA_A3;@arma_attendance -serverMod=@arma_attendance_server
```

If the RPT says `Call extension 'arma_attendance' could not be loaded`, verify that both `arma_attendance.so` and `arma_attendance_x64.so` are present in `@arma_attendance_server`. Then run `ldd @arma_attendance_server/arma_attendance_x64.so` inside the same Linux container that runs `arma3server_x64`. Any `not found` dependency will prevent Arma from loading the extension. If dependencies are present, also confirm the container has glibc 2.31 or newer with `ldd --version`.

## Local Validation

```bash
export HEMTT_BI_TOOLS="/mnt/game_one/SteamLibrary/steamapps/common/Arma 3 Tools/"
hemtt check
hemtt build

cmake -S extension -B build/extension-linux -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build/extension-linux --config RelWithDebInfo
ctest --test-dir build/extension-linux --output-on-failure
```

The native extension reads config from environment variables first, then from `arma_attendance.toml` beside the extension binary when discoverable. Commit only `servermod/arma_attendance.example.toml`; keep real tokens and server config out of git.
