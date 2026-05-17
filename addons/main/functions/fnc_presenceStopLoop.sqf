if (!isServer) exitWith {};

missionNamespace setVariable ["AASE_presenceTrackingActive", false, false];

private _handle = missionNamespace getVariable ["AASE_presenceLoopHandle", scriptNull];
if (!scriptDone _handle) then {
    terminate _handle;
};
