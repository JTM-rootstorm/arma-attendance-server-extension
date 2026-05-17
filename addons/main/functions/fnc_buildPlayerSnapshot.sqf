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
    _snapshot set ["stats", createHashMapFromArray [
        ["infantry_kills", 0],
        ["vehicle_kills", 0],
        ["player_kills", 0],
        ["ai_kills", 0],
        ["friendly_kills", 0],
        ["deaths", 0]
    ]];
};

_snapshot
