if (!isServer) exitWith {};

if !(missionNamespace getVariable ["AASE_enableMissionEndFallback", false]) exitWith {};
if ((missionNamespace getVariable ["AASE_missionEndedEh", -1]) >= 0) exitWith {};

private _handlerId = addMissionEventHandler ["Ended", {
    params [["_endType", "UNKNOWN", [""]]];

    if (!isServer) exitWith {};
    if (!(missionNamespace getVariable ["AASE_enableMissionEndFallback", false])) exitWith {};
    if (!(missionNamespace getVariable ["AASE_operationActive", false])) exitWith {};

    private _upperEndType = toUpper _endType;
    private _outcome = "success";
    if (_upperEndType in ["LOSER", "KILLED"] || {(_upperEndType find "FAIL") >= 0}) then {
        _outcome = "failed";
    };

    [
        "mission_end_fallback",
        createHashMapFromArray [
            ["source_detail", "Mission Ended event handler"],
            ["reason", "mission_ended"],
            ["end_type", _endType]
        ],
        _outcome
    ] call TCWA3_fnc_operationFinish;
}];

missionNamespace setVariable ["AASE_missionEndedEh", _handlerId, false];
["Mission-end fallback registered.", "INFO"] call TCWA3_fnc_log;
