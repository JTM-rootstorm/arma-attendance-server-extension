params ["_unit", ["_presentAtStart", false]];

if (!isServer) exitWith {};
if (isNull _unit) exitWith {};
if (!isPlayer _unit) exitWith {};
if (!(missionNamespace getVariable ["AASE_presenceTrackingActive", false]) && {!(missionNamespace getVariable ["AASE_presenceFinalized", false])}) exitWith {};

private _uid = getPlayerUID _unit;
if (_uid isEqualTo "") exitWith {};

private _now = serverTime;
private _ledger = missionNamespace getVariable ["AASE_presenceByUid", createHashMap];
private _record = _ledger getOrDefault [_uid, createHashMap];
private _wasKnown = count _record > 0;

if (!_wasKnown) then {
    private _joinedAfterStart = true;
    if (_presentAtStart) then {
        _joinedAfterStart = false;
    };

    _record = createHashMapFromArray [
        ["uid", _uid],
        ["name", name _unit],
        ["state", "present"],
        ["active_since", _now],
        ["attended_seconds", 0],
        ["present_at_start", _presentAtStart],
        ["present_at_end", false],
        ["joined_after_start", _joinedAfterStart],
        ["first_seen_at", _now],
        ["last_seen_at", _now],
        ["disconnect_count", 0],
        ["reconnect_count", 0],
        ["last_disconnect_at", -1],
        ["last_reconnect_at", -1],
        ["side", ""],
        ["group", ""],
        ["role", ""],
        ["unit_class", ""],
        ["vehicle_class", ""]
    ];
} else {
    if ((_record getOrDefault ["state", "unknown"]) isNotEqualTo "present") then {
        _record set ["state", "present"];
        _record set ["active_since", _now];
        _record set ["reconnect_count", (_record getOrDefault ["reconnect_count", 0]) + 1];
        _record set ["last_reconnect_at", _now];
    };

    if (_presentAtStart) then {
        _record set ["present_at_start", true];
        _record set ["joined_after_start", false];
    };
};

private _vehicle = vehicle _unit;
private _vehicleClass = "";
if (_vehicle isNotEqualTo _unit) then {
    _vehicleClass = typeOf _vehicle;
};

private _role = getText (configOf _unit >> "displayName");
if (_role isEqualTo "") then {
    _role = typeOf _unit;
};

_record set ["name", name _unit];
_record set ["last_seen_at", _now];
_record set ["side", str (side (group _unit))];
_record set ["group", groupId (group _unit)];
_record set ["role", _role];
_record set ["unit_class", typeOf _unit];
_record set ["vehicle_class", _vehicleClass];

_ledger set [_uid, _record];
missionNamespace setVariable ["AASE_presenceByUid", _ledger, false];
