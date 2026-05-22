params ["_unit", ["_includeStats", false]];

private _uid = getPlayerUID _unit;
if (_uid isEqualTo "") exitWith {createHashMap};

private _vehicle = vehicle _unit;
private _vehicleClass = "";
if (_vehicle isNotEqualTo _unit) then {
    _vehicleClass = typeOf _vehicle;
};

private _role = getText (configOf _unit >> "displayName");
if (_role isEqualTo "") then {
    _role = typeOf _unit;
};

private _snapshot = createHashMapFromArray [
    ["player_uid", _uid],
    ["name", name _unit],
    ["side", str (side (group _unit))],
    ["group", groupId (group _unit)],
    ["role", _role],
    ["unit_class", typeOf _unit],
    ["vehicle_class", _vehicleClass]
];

if (_includeStats) then {
    [_snapshot, _uid] call AASE_fnc_scoreAttachStats;
} else {
    private _baselineByUid = missionNamespace getVariable ["AASE_scoreBaselineByUid", createHashMap];
    private _baseline = _baselineByUid getOrDefault [_uid, createHashMap];
    if (count _baseline > 0) then {
        _snapshot set ["scoreboard_baseline", _baseline getOrDefault ["scores", []]];
    };
};

_snapshot
