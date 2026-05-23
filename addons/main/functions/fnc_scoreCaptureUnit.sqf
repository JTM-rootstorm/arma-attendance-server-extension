params ["_unit"];

if (!isServer) exitWith {false};
if (isNull _unit) exitWith {false};
if ([_unit] call AASE_fnc_isHeadlessClient) exitWith {false};
if (!isPlayer _unit) exitWith {false};

private _uid = getPlayerUID _unit;
if (_uid isEqualTo "") exitWith {false};

private _playerName = [name _unit] call AASE_fnc_sanitizePlayerName;
private _scores = [getPlayerScores _unit] call AASE_fnc_scoreNormalizeArray;
private _snapshot = createHashMapFromArray [
    ["uid", _uid],
    ["name", _playerName],
    ["captured_at", serverTime],
    ["scores", _scores],
    ["score_source", "getPlayerScores"]
];

private _baselineByUid = missionNamespace getVariable ["AASE_scoreBaselineByUid", createHashMap];
private _latestByUid = missionNamespace getVariable ["AASE_scoreLatestByUid", createHashMap];

if !(_uid in _baselineByUid) then {
    _baselineByUid set [_uid, _snapshot];
};

_latestByUid set [_uid, _snapshot];

missionNamespace setVariable ["AASE_scoreBaselineByUid", _baselineByUid, false];
missionNamespace setVariable ["AASE_scoreLatestByUid", _latestByUid, false];

true
