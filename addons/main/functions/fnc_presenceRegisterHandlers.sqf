if (!isServer) exitWith {};

if (missionNamespace getVariable ["AASE_presenceHandlersRegistered", false]) exitWith {};

private _connectedId = addMissionEventHandler ["PlayerConnected", {
    params ["_networkId", "_uid", "_name"];

    if (!isServer) exitWith {};
    if (_uid isEqualTo "") exitWith {};

    [_uid, _name] spawn {
        params ["_uid", "_name"];

        sleep 1;
        if (!isServer) exitWith {};
        if (!(missionNamespace getVariable ["AASE_presenceTrackingActive", false])) exitWith {};

        private _unit = objNull;
        {
            if ((getPlayerUID _x) isEqualTo _uid) exitWith {
                _unit = _x;
            };
        } forEach ([] call AASE_fnc_activePlayerUnits);

        if (isNull _unit) exitWith {};
        [_unit, false] call AASE_fnc_markPlayerPresentFromUnit;
    };
}];

private _disconnectedId = addMissionEventHandler ["PlayerDisconnected", {
    params ["_networkId", "_uid", "_name"];

    if (!isServer) exitWith {};
    if (_uid isEqualTo "") exitWith {};

    private _unit = objNull;
    {
        if ((getPlayerUID _x) isEqualTo _uid) exitWith {
            _unit = _x;
        };
    } forEach allPlayers;
    if (!isNull _unit && {[_unit] call AASE_fnc_isHeadlessClient}) exitWith {};

    private _ledger = missionNamespace getVariable ["AASE_presenceByUid", createHashMap];
    if ((isNull _unit) && {!(_uid in _ledger)}) exitWith {};

    if (!isNull _unit) then {
        [_unit] call AASE_fnc_scoreCaptureUnit;
    };

    [_uid, _name, "disconnect"] call AASE_fnc_markPlayerAbsent;
}];

private _entityKilledId = addMissionEventHandler ["EntityKilled", {
    params ["_killed", "_killer", "_instigator"];

    if (!isServer) exitWith {};
    if (!(missionNamespace getVariable ["AASE_presenceTrackingActive", false])) exitWith {};
    if (!(missionNamespace getVariable ["AASE_enableExperimentalKillLedger", false])) exitWith {};
    if (isNull _killed) exitWith {};

    if (isPlayer _killed && {!([_killed] call AASE_fnc_isHeadlessClient)}) then {
        private _killedUid = getPlayerUID _killed;
        if (_killedUid isNotEqualTo "") then {
            [_killedUid, name _killed, "deaths"] call AASE_fnc_incrementPresenceStat;
        };
    };

    private _killerUnit = _instigator;
    if (isNull _killerUnit) then {
        _killerUnit = _killer;
    };
    if (isNull _killerUnit) exitWith {};
    if ([_killerUnit] call AASE_fnc_isHeadlessClient) exitWith {};
    if (!isPlayer _killerUnit) exitWith {};
    if (_killerUnit isEqualTo _killed) exitWith {};

    private _killerUid = getPlayerUID _killerUnit;
    if (_killerUid isEqualTo "") exitWith {};

    [_killerUnit, false] call AASE_fnc_markPlayerPresentFromUnit;

    if (isPlayer _killed && {!([_killed] call AASE_fnc_isHeadlessClient)}) then {
        [_killerUid, name _killerUnit, "player_kills"] call AASE_fnc_incrementPresenceStat;
    } else {
        if (_killed isKindOf "Man") then {
            [_killerUid, name _killerUnit, "infantry_kills"] call AASE_fnc_incrementPresenceStat;
            [_killerUid, name _killerUnit, "ai_kills"] call AASE_fnc_incrementPresenceStat;
        } else {
            if ((_killed isKindOf "LandVehicle") || {_killed isKindOf "Air"} || {_killed isKindOf "Ship"}) then {
                [_killerUid, name _killerUnit, "vehicle_kills"] call AASE_fnc_incrementPresenceStat;
            };
        };
    };

    if ((side (group _killerUnit)) isEqualTo (side (group _killed))) then {
        [_killerUid, name _killerUnit, "friendly_kills"] call AASE_fnc_incrementPresenceStat;
    };
}];

missionNamespace setVariable ["AASE_presenceHandlersRegistered", true, false];
missionNamespace setVariable ["AASE_presenceConnectedHandler", _connectedId, false];
missionNamespace setVariable ["AASE_presenceDisconnectedHandler", _disconnectedId, false];
missionNamespace setVariable ["AASE_presenceEntityKilledHandler", _entityKilledId, false];
