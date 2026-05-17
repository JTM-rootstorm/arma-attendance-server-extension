if (!isServer) exitWith {};

if (missionNamespace getVariable ["AASE_presenceHandlersRegistered", false]) exitWith {};

private _connectedId = addMissionEventHandler ["PlayerConnected", {
    params ["_networkId", "_uid", "_name"];

    if (!isServer) exitWith {};
    if (_uid isEqualTo "") exitWith {};

    [_uid, _name] call AASE_fnc_markUidPresentPending;
}];

private _disconnectedId = addMissionEventHandler ["PlayerDisconnected", {
    params ["_networkId", "_uid", "_name"];

    if (!isServer) exitWith {};
    if (_uid isEqualTo "") exitWith {};

    [_uid, _name, "disconnect"] call AASE_fnc_markPlayerAbsent;
}];

missionNamespace setVariable ["AASE_presenceHandlersRegistered", true, false];
missionNamespace setVariable ["AASE_presenceConnectedHandler", _connectedId, false];
missionNamespace setVariable ["AASE_presenceDisconnectedHandler", _disconnectedId, false];
