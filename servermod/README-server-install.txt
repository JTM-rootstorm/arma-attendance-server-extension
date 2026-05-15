1. Copy @arma_attendance to server and clients.
2. Copy @arma_attendance_server to the dedicated server only.
3. Copy @arma_attendance/keys/*.bikey into the server's keys directory if your server layout uses a central keys folder.
4. Verify @arma_attendance_server contains arma_attendance.so and arma_attendance_x64.so on Linux dedicated servers.
5. In the same Linux container that runs arma3server_x64, run:
   ldd @arma_attendance_server/arma_attendance_x64.so
   If any dependency prints "not found", the extension cannot load until that dependency is installed or bundled.
6. In the same Linux container, run:
   ldd --version
   The packaged Linux extension is built for glibc 2.31 or newer.
7. Copy @arma_attendance_server/arma_attendance.example.toml to @arma_attendance_server/arma_attendance.toml. If your server manager stores config elsewhere, set AASE_CONFIG_PATH to that absolute file path.
8. Edit arma_attendance.toml with the real API base URL, API token, and server key.
9. Launch with:
   -mod=@CBA_A3;@arma_attendance -serverMod=@arma_attendance_server
10. In Zeus, place Attendance: Debug API Poke.
11. Check the server RPT for the JSON response.
