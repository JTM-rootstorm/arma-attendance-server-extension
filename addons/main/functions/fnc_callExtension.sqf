params ["_command", ["_args", []]];

if (!isServer) exitWith { "" };

private _result = "arma_attendance" callExtension [_command, _args];

[format ["callExtension command=%1 result=%2", _command, _result], "DEBUG"] call AASE_fnc_log;

_result
