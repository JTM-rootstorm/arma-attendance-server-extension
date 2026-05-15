params ["_command", ["_args", []]];

if (!isServer) exitWith { "" };

private _isExtensionFailure = {
    params ["_candidate"];

    _candidate isEqualType []
        && {count _candidate >= 2}
        && {
            ((_candidate select 1) < 0)
                || {count _candidate >= 3 && {(_candidate select 2) > 0}}
        }
};

private _extensionNames = ["arma_attendance", "arma_attendance_x64"];
private _result = "";

{
    _result = _x callExtension [_command, _args];

    [format ["callExtension extension=%1 command=%2 result=%3", _x, _command, _result], "DEBUG"] call AASE_fnc_log;

    if (!([_result] call _isExtensionFailure)) exitWith {};
} forEach _extensionNames;

if ([_result] call _isExtensionFailure) then {
    [
        "Extension lookup failed. Verify @arma_attendance_server is loaded with -serverMod and contains arma_attendance.so/arma_attendance_x64.so on Linux or arma_attendance_x64.dll on Windows.",
        "ERROR"
    ] call AASE_fnc_log;
};

_result
