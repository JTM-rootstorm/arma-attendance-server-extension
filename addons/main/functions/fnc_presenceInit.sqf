params [["_operationId", ""], ["_attendanceThreshold", 0.5]];

if (!isServer) exitWith {};

private _now = serverTime;
missionNamespace setVariable ["AASE_operationActive", true, false];
missionNamespace setVariable ["AASE_operationId", _operationId, false];
missionNamespace setVariable ["AASE_operationStartedAt", _now, false];
missionNamespace setVariable ["AASE_operationEndedAt", -1, false];
missionNamespace setVariable ["AASE_attendanceThreshold", _attendanceThreshold, false];
missionNamespace setVariable ["AASE_presenceByUid", createHashMap, false];
missionNamespace setVariable ["AASE_presenceReconcileSeconds", 30, false];
missionNamespace setVariable ["AASE_presenceTrackingActive", true, false];
missionNamespace setVariable ["AASE_presenceFinalized", false, false];

[] call TCWA3_fnc_scoreInit;
{
    [_x, true] call TCWA3_fnc_markPlayerPresentFromUnit;
} forEach ([] call TCWA3_fnc_activePlayerUnits);
[] call TCWA3_fnc_scoreCaptureCurrentPlayers;

[] call TCWA3_fnc_presenceRegisterHandlers;
[] call TCWA3_fnc_presenceStartLoop;

[format ["Presence ledger initialized for operation %1.", _operationId], "INFO"] call TCWA3_fnc_log;
