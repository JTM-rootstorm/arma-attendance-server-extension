params ["_uid", ["_name", ""], "_stat"];

if (!isServer) exitWith {};
if (!(missionNamespace getVariable ["AASE_presenceTrackingActive", false])) exitWith {};
if (_uid isEqualTo "") exitWith {};

_name = [_name] call TCWA3_fnc_sanitizePlayerName;
private _validStats = [
    "infantry_kills",
    "vehicle_kills",
    "player_kills",
    "ai_kills",
    "friendly_kills",
    "deaths"
];
if !(_stat in _validStats) exitWith {};

private _ledger = missionNamespace getVariable ["AASE_presenceByUid", createHashMap];
private _record = _ledger getOrDefault [_uid, createHashMap];

if ((count _record) isEqualTo 0) then {
    private _now = serverTime;
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

private _stats = _record getOrDefault ["stats", createHashMapFromArray [
    ["infantry_kills", 0],
    ["vehicle_kills", 0],
    ["player_kills", 0],
    ["ai_kills", 0],
    ["friendly_kills", 0],
    ["deaths", 0]
]];

_stats set [_stat, (_stats getOrDefault [_stat, 0]) + 1];
_record set ["stats", _stats];
if (_name isNotEqualTo "") then {
    _record set ["name", _name];
};

_ledger set [_uid, _record];
missionNamespace setVariable ["AASE_presenceByUid", _ledger, false];
