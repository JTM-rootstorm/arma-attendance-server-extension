if (!isServer) exitWith {};

{
    [_x] call AASE_fnc_scoreCaptureUnit;
} forEach ([] call AASE_fnc_activePlayerUnits);
