params ["_logic", "_units", "_activated"];

if (!isServer) exitWith {};
if (!_activated) exitWith {};

private _message = format [
    "hello from Arma server: mission=%1 world=%2 tick=%3",
    missionName,
    worldName,
    diag_tickTime
];

private _result = [_message] call AASE_fnc_poke;

[format ["Debug API poke result: %1", _result], "INFO"] call AASE_fnc_log;
