if (!isServer) exitWith {};

private _triggerHandle = missionNamespace getVariable ["AASE_autoTriggerWatcherHandle", scriptNull];
if (!scriptDone _triggerHandle) then {
    terminate _triggerHandle;
};

private _delayHandle = missionNamespace getVariable ["AASE_autoDelayedStartHandle", scriptNull];
if (!scriptDone _delayHandle) then {
    terminate _delayHandle;
};

missionNamespace setVariable ["AASE_autoTriggerWatcherHandle", scriptNull, false];
missionNamespace setVariable ["AASE_autoDelayedStartHandle", scriptNull, false];
missionNamespace setVariable ["AASE_autoTriggerWatcherRunning", false, false];
missionNamespace setVariable ["AASE_autoDelayedStartRunning", false, false];
missionNamespace setVariable ["AASE_autoStartTriggerFired", false, false];
missionNamespace setVariable ["AASE_autoFinishTriggerFired", false, false];
missionNamespace setVariable ["AASE_autoDelayedStartFired", false, false];
