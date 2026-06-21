if (!isServer) exitWith {};

params [["_force", false]];

if (_force) then {
    missionNamespace setVariable ["AASE_missionEndFallbackForced", true, false];
};

if (!(missionNamespace getVariable ["AASE_enableMissionEndFallback", false]) && {!_force}) exitWith {};
if ((missionNamespace getVariable ["AASE_missionEndedEh", -1]) >= 0) exitWith {};

private _handlerId = addMissionEventHandler ["Ended", {
    params [["_endType", "UNKNOWN"]];

    if (!isServer) exitWith {};
    private _fallbackEnabled = missionNamespace getVariable ["AASE_enableMissionEndFallback", false];
    private _fallbackForced = missionNamespace getVariable ["AASE_missionEndFallbackForced", false];
    if (!(_fallbackEnabled || _fallbackForced)) exitWith {};
    if (!(missionNamespace getVariable ["AASE_operationActive", false])) exitWith {};

    private _endTypeText = if (_endType isEqualType "") then {_endType} else {str _endType};
    private _outcome = [_endTypeText] call TCWA3_fnc_missionEndOutcome;

    [format ["Mission-end fallback finishing active operation: endType=%1 outcome=%2", _endTypeText, _outcome], "INFO"] call TCWA3_fnc_log;

    [
        "mission_end_fallback",
        createHashMapFromArray [
            ["source_detail", "Mission Ended event handler"],
            ["reason", "mission_ended"],
            ["end_type", _endTypeText]
        ],
        _outcome
    ] call TCWA3_fnc_operationFinish;
}];

missionNamespace setVariable ["AASE_missionEndedEh", _handlerId, false];
["Mission-end fallback registered.", "INFO"] call TCWA3_fnc_log;
