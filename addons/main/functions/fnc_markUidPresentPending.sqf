params ["_uid", ["_name", ""]];

if (!isServer) exitWith {};
if (_uid isEqualTo "") exitWith {};
if (!(missionNamespace getVariable ["AASE_presenceTrackingActive", false]) && {!(missionNamespace getVariable ["AASE_presenceFinalized", false])}) exitWith {};

private _now = serverTime;
private _ledger = missionNamespace getVariable ["AASE_presenceByUid", createHashMap];
private _record = _ledger getOrDefault [_uid, createHashMap];
private _wasKnown = count _record > 0;

if (!_wasKnown) then {
    _record = createHashMapFromArray [
        ["uid", _uid],
        ["name", _name],
        ["state", "present"],
        ["active_since", _now],
        ["attended_seconds", 0],
        ["present_at_start", false],
        ["present_at_end", false],
        ["joined_after_start", true],
        ["first_seen_at", _now],
        ["last_seen_at", _now],
        ["disconnect_count", 0],
        ["reconnect_count", 0],
        ["last_disconnect_at", -1],
        ["last_reconnect_at", _now],
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
    if (_name isNotEqualTo "") then {
        _record set ["name", _name];
    };
    _record set ["last_seen_at", _now];
};

_ledger set [_uid, _record];
missionNamespace setVariable ["AASE_presenceByUid", _ledger, false];
