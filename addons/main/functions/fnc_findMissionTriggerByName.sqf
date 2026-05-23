params [["_name", ""]];

if (_name isEqualTo "") exitWith {objNull};

private _trigger = missionNamespace getVariable [_name, objNull];
if (isNull _trigger) exitWith {objNull};

_trigger
