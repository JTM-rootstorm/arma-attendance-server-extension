if (!isServer) exitWith {};

if !(missionNamespace getVariable ["AASE_enableMissionEndFallback", false]) exitWith {};
if ((missionNamespace getVariable ["AASE_missionEndedEh", -1]) >= 0) exitWith {};

private _handlerId = addMissionEventHandler ["Ended", {
    if (!isServer) exitWith {};
    if (!(missionNamespace getVariable ["AASE_enableMissionEndFallback", false])) exitWith {};
    if (!(missionNamespace getVariable ["AASE_operationActive", false])) exitWith {};

    [
        "mission_end_fallback",
        createHashMapFromArray [
            ["source_detail", "Mission Ended event handler"],
            ["reason", "mission_ended"]
        ]
    ] call TCWA3_fnc_operationFinish;
}];

missionNamespace setVariable ["AASE_missionEndedEh", _handlerId, false];
["Mission-end fallback registered.", "INFO"] call TCWA3_fnc_log;
