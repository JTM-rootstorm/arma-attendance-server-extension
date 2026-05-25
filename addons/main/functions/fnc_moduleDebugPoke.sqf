params ["_logic", "_units", "_activated"];

if (!isServer) exitWith {
    [_logic] call TCWA3_fnc_deleteModuleLogic;
};
if (!_activated) exitWith {
    [_logic] call TCWA3_fnc_deleteModuleLogic;
};

private _message = format [
    "hello from Arma server: mission=%1 world=%2 tick=%3",
    missionName,
    worldName,
    diag_tickTime
];

private _result = [_message] call TCWA3_fnc_poke;

[format ["Debug API poke result: %1", _result], "INFO"] call TCWA3_fnc_log;

[_logic] call TCWA3_fnc_deleteModuleLogic;

_result
