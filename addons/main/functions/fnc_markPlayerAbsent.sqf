params ["_uid", ["_name", ""], ["_reason", "disconnect"]];

if (!isServer) exitWith {};
if (_uid isEqualTo "") exitWith {};

private _now = serverTime;
private _ledger = missionNamespace getVariable ["AASE_presenceByUid", createHashMap];
private _record = _ledger getOrDefault [_uid, createHashMap];
private _wasKnown = count _record > 0;

if (!_wasKnown) then {
    _record = createHashMapFromArray [
        ["uid", _uid],
        ["name", _name],
        ["state", "absent_paused"],
        ["active_since", -1],
        ["attended_seconds", 0],
        ["present_at_start", false],
        ["present_at_end", false],
        ["joined_after_start", true],
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
};

private _wasPresent = (_record getOrDefault ["state", "unknown"]) isEqualTo "present";

if (_wasPresent) then {
    private _activeSince = _record getOrDefault ["active_since", _now];
    if (_activeSince >= 0) then {
        private _attendedSeconds = _record getOrDefault ["attended_seconds", 0];
        _record set ["attended_seconds", _attendedSeconds + (_now - _activeSince)];
    };
};

if (_name isNotEqualTo "") then {
    _record set ["name", _name];
};

_record set ["state", "absent_paused"];
_record set ["active_since", -1];
if (_wasPresent || {_reason isNotEqualTo "operation_end"}) then {
    _record set ["last_seen_at", _now];
};

if (_reason isEqualTo "disconnect") then {
    _record set ["disconnect_count", (_record getOrDefault ["disconnect_count", 0]) + 1];
    _record set ["last_disconnect_at", _now];
};

_ledger set [_uid, _record];
missionNamespace setVariable ["AASE_presenceByUid", _ledger, false];
