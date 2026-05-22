params ["_uid"];

private _baselineByUid = missionNamespace getVariable ["AASE_scoreBaselineByUid", createHashMap];
private _latestByUid = missionNamespace getVariable ["AASE_scoreLatestByUid", createHashMap];

private _baselineSnapshot = _baselineByUid getOrDefault [_uid, createHashMap];
private _latestSnapshot = _latestByUid getOrDefault [_uid, createHashMap];
private _baseline = [_baselineSnapshot getOrDefault ["scores", []]] call AASE_fnc_scoreNormalizeArray;
private _latest = [_latestSnapshot getOrDefault ["scores", _baseline]] call AASE_fnc_scoreNormalizeArray;
private _delta = [];

for "_index" from 0 to 5 do {
    private _value = (_latest select _index) - (_baseline select _index);
    if (_value < 0) then {
        _value = 0;
    };
    _delta pushBack _value;
};

private _infantry = _delta select 0;
private _soft = _delta select 1;
private _armor = _delta select 2;
private _air = _delta select 3;
private _deaths = _delta select 4;
private _score = _delta select 5;
private _groundVehicles = _soft + _armor;
private _allVehicles = _groundVehicles + _air;

createHashMapFromArray [
    ["stats", createHashMapFromArray [
        ["infantry_kills", _infantry],
        ["vehicle_kills", _allVehicles],
        ["player_kills", 0],
        ["ai_kills", _infantry],
        ["friendly_kills", 0],
        ["deaths", _deaths]
    ]],
    ["scoreboard_stats", createHashMapFromArray [
        ["stats_source", "arma_getPlayerScores_delta"],
        ["infantry_kills", _infantry],
        ["soft_vehicle_kills", _soft],
        ["armor_kills", _armor],
        ["ground_vehicle_kills", _groundVehicles],
        ["air_kills", _air],
        ["all_vehicle_kills", _allVehicles],
        ["deaths", _deaths],
        ["score", _score],
        ["baseline", _baseline],
        ["latest", _latest]
    ]]
]
