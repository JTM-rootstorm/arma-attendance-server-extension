params [
    ["_sourceKind", "scripted"],
    ["_sourceMeta", createHashMap]
];

private _mission = [] call AASE_fnc_buildMissionPayload;
private _missionUid = _mission getOrDefault ["mission_uid", format ["%1:%2", worldName, round diag_tickTime]];
private _requestId = format ["arma3:start:%1:%2", _missionUid, round diag_tickTime];
private _source = [_sourceKind, _sourceMeta] call AASE_fnc_buildOperationSource;

createHashMapFromArray [
    ["request_id", _requestId],
    ["payload_version", 1],
    ["mission", _mission],
    ["source", _source],
    ["players", [false] call AASE_fnc_buildPlayersSnapshot]
]
