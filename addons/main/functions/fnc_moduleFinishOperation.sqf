params ["_logic", "_units", "_activated"];

private _cleanup = {
    params ["_moduleLogic"];
    if (!isNull _moduleLogic) then {
        deleteVehicle _moduleLogic;
    };
};

if (!isServer) exitWith {
    [_logic] call _cleanup;
};

if (!_activated) exitWith {
    [_logic] call _cleanup;
};

private _result = [] call AASE_fnc_operationFinish;
[format ["Finish operation result: %1", _result], "INFO"] call AASE_fnc_log;

[_logic] call _cleanup;

_result
