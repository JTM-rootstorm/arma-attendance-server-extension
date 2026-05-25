if (!isServer) exitWith {};

private _autoStartMode = missionNamespace getVariable ["AASE_autoStartMode", 0];
private _autoFinishMode = missionNamespace getVariable ["AASE_autoFinishMode", 0];
private _missionEndFallback = missionNamespace getVariable ["AASE_enableMissionEndFallback", false];

if (_autoStartMode isEqualTo 1 || {_autoFinishMode isEqualTo 1}) then {
    [] call TCWA3_fnc_autoTriggerWatcher;
};

if (_autoStartMode isEqualTo 2) then {
    [] call TCWA3_fnc_autoDelayedStart;
};

if (_missionEndFallback) then {
    [] call TCWA3_fnc_autoMissionEndFallback;
};

[
    format [
        "Automation initialized: startMode=%1 finishMode=%2 missionEndFallback=%3",
        _autoStartMode,
        _autoFinishMode,
        _missionEndFallback
    ],
    "INFO"
] call TCWA3_fnc_log;
