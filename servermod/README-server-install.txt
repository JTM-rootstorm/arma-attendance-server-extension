1. Copy @arma_attendance to server and clients.
2. Copy @arma_attendance_server to the dedicated server only.
3. Copy @arma_attendance/keys/*.bikey into the server's keys directory if your server layout uses a central keys folder.
4. Verify @arma_attendance_server contains arma_attendance_x64.so on Linux dedicated servers.
5. Copy @arma_attendance_server/arma_attendance.example.toml to @arma_attendance_server/arma_attendance.toml.
6. Edit arma_attendance.toml with the real API base URL, API token, and server key.
7. Launch with:
   -mod=@CBA_A3;@arma_attendance -serverMod=@arma_attendance_server
8. In Zeus, place Attendance: Debug API Poke.
9. Check the server RPT for the JSON response.
