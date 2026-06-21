if (!isServer) exitWith {};

private _handle = missionNamespace getVariable ["AASE_autoTriggerWatcherHandle", scriptNull];
if (!scriptDone _handle) exitWith {};

missionNamespace setVariable ["AASE_autoTriggerWatcherRunning", true, false];
missionNamespace setVariable ["AASE_autoStartTriggerFired", false, false];
missionNamespace setVariable ["AASE_autoFinishTriggerFired", false, false];
missionNamespace setVariable ["AASE_autoMissingTriggerNames", createHashMap, false];

_handle = [] spawn {
    while {missionNamespace getVariable ["AASE_autoTriggerWatcherRunning", false]} do {
        private _autoStartMode = missionNamespace getVariable ["AASE_autoStartMode", 0];
        private _autoFinishMode = missionNamespace getVariable ["AASE_autoFinishMode", 0];
        private _pollSeconds = missionNamespace getVariable ["AASE_triggerPollSeconds", 5];
        if (_pollSeconds < 1) then {
            _pollSeconds = 1;
        };

        private _missing = missionNamespace getVariable ["AASE_autoMissingTriggerNames", createHashMap];

        if (_autoStartMode isEqualTo 1 && {!(missionNamespace getVariable ["AASE_autoStartTriggerFired", false])}) then {
            private _startName = missionNamespace getVariable ["AASE_startTriggerName", "aase_start_trigger"];
            private _startTrigger = [_startName] call TCWA3_fnc_findMissionTriggerByName;
            if (isNull _startTrigger) then {
                if !(_missing getOrDefault [_startName, false]) then {
                    [format ["Named start trigger not found yet: %1", _startName], "WARN"] call TCWA3_fnc_log;
                    _missing set [_startName, true];
                };
            } else {
                if (triggerActivated _startTrigger) then {
                    missionNamespace setVariable ["AASE_autoStartTriggerFired", true, false];
                    if (missionNamespace getVariable ["AASE_operationActive", false]) then {
                        [format ["Named start trigger %1 activated, but operation is already active.", _startName], "WARN"] call TCWA3_fnc_log;
                    } else {
                        [
                            "named_trigger",
                            createHashMapFromArray [
                                ["source_detail", _startName],
                                ["trigger_name", _startName],
                                ["trigger_net_id", netId _startTrigger]
                            ]
                        ] call TCWA3_fnc_operationStart;
                    };
                };
            };
        };

        if (_autoFinishMode isEqualTo 1 && {!(missionNamespace getVariable ["AASE_autoFinishTriggerFired", false])}) then {
            private _finishName = missionNamespace getVariable ["AASE_finishTriggerName", "aase_finish_trigger"];
            private _finishTrigger = [_finishName] call TCWA3_fnc_findMissionTriggerByName;
            if (isNull _finishTrigger) then {
                if !(_missing getOrDefault [_finishName, false]) then {
                    [format ["Named finish trigger not found yet: %1", _finishName], "WARN"] call TCWA3_fnc_log;
                    _missing set [_finishName, true];
                };
            } else {
                if (triggerActivated _finishTrigger) then {
                    missionNamespace setVariable ["AASE_autoFinishTriggerFired", true, false];
                    if (!(missionNamespace getVariable ["AASE_operationActive", false])) then {
                        [format ["Named finish trigger %1 activated before an operation was active.", _finishName], "WARN"] call TCWA3_fnc_log;
                    } else {
                        [
                            "named_trigger",
                            createHashMapFromArray [
                                ["source_detail", _finishName],
                                ["trigger_name", _finishName],
                                ["trigger_net_id", netId _finishTrigger]
                            ],
                            "success"
                        ] call TCWA3_fnc_operationFinish;
                    };
                };
            };
        };

        missionNamespace setVariable ["AASE_autoMissingTriggerNames", _missing, false];
        sleep _pollSeconds;
    };
};

missionNamespace setVariable ["AASE_autoTriggerWatcherHandle", _handle, false];
[format [
    "Named trigger automation watcher started: start=%1 finish=%2 poll=%3",
    missionNamespace getVariable ["AASE_startTriggerName", "aase_start_trigger"],
    missionNamespace getVariable ["AASE_finishTriggerName", "aase_finish_trigger"],
    missionNamespace getVariable ["AASE_triggerPollSeconds", 5]
], "INFO"] call TCWA3_fnc_log;
