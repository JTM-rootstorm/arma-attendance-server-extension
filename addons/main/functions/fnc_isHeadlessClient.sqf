params ["_unit"];

if (isNull _unit) exitWith {false};

(_unit isKindOf "HeadlessClient_F") || {_unit in (entities "HeadlessClient_F")}
