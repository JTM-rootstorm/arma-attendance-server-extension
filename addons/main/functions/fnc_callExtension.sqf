params ["_command", ["_args", []]];

if (!isServer) exitWith { "" };

private _result = "arma_attendance" callExtension [_command, _args];

[format ["callExtension command=%1 result=%2", _command, _result], "DEBUG"] call AASE_fnc_log;

if (_result isEqualType [] && {count _result >= 2} && {_result select 1 < 0}) then {
    [
        "Extension lookup failed. Verify @arma_attendance_server is loaded with -serverMod and contains arma_attendance_x64.so on Linux or arma_attendance_x64.dll on Windows.",
        "ERROR"
    ] call AASE_fnc_log;
};

_result
