params ["_logic", "_units", "_activated"];

if (!isServer) exitWith {};
if (!_activated) exitWith {};

private _result = [] call AASE_fnc_operationFinish;
[format ["Finish operation result: %1", _result], "INFO"] call AASE_fnc_log;

if (!isNull _logic) then {
    deleteVehicle _logic;
};
