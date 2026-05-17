# Arma Attendance Server Install

Copy `@arma_attendance` to clients and the dedicated server. Copy `@arma_attendance_server` to the dedicated server only.

Recommended launch flags:

```text
-mod=@CBA_A3;@arma_attendance -serverMod=@arma_attendance_server
```

## Config

```bash
cp @arma_attendance_server/arma_attendance.example.toml @arma_attendance_server/arma_attendance.toml
chmod 600 @arma_attendance_server/arma_attendance.toml
```

Edit the real config with the API base URL, API token, and server key. If your server manager stores config elsewhere, set `AASE_CONFIG_PATH` to the absolute TOML file path.

## Linux Diagnostics

Run these in the same Linux container or host that runs `arma3server_x64`:

```bash
file @arma_attendance_server/arma_attendance.so
ldd @arma_attendance_server/arma_attendance.so
ldd @arma_attendance_server/arma_attendance_x64.so
```

No `ldd` line should say `not found`.

## Smoke Flow

1. Start the dedicated server with CBA, `@arma_attendance`, and `@arma_attendance_server`.
2. Open Zeus.
3. Place `Attendance: Debug API Poke`.
4. Place `Attendance: Start Operation`.
5. Place `Attendance: Finish Operation`.
6. Check the server RPT for compact JSON responses.
7. Check web API ingest/readback if available.

Queue files live beside the extension by default:

```text
arma_attendance_queue.ndjson
arma_attendance_queue.sent.ndjson
```

Queue files must not contain bearer tokens.
