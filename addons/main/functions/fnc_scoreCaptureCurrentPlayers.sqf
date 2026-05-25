if (!isServer) exitWith {};

{
    [_x] call TCWA3_fnc_scoreCaptureUnit;
} forEach ([] call TCWA3_fnc_activePlayerUnits);
