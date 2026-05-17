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

{
    [_x, true] call AASE_fnc_markPlayerPresentFromUnit;
} forEach allPlayers;

[] call AASE_fnc_presenceRegisterHandlers;
[] call AASE_fnc_presenceStartLoop;

[format ["Presence ledger initialized for operation %1.", _operationId], "INFO"] call AASE_fnc_log;
