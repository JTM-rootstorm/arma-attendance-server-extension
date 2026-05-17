private _mission = [] call AASE_fnc_buildMissionPayload;
private _missionUid = _mission getOrDefault ["mission_uid", format ["%1:%2", worldName, round diag_tickTime]];
private _requestId = format ["arma3:start:%1:%2", _missionUid, round diag_tickTime];

createHashMapFromArray [
    ["request_id", _requestId],
    ["payload_version", 1],
    ["mission", _mission],
    ["source", createHashMapFromArray [
        ["kind", "arma3-addon"],
        ["addon", "aase_main"]
    ]],
    ["players", [false] call AASE_fnc_buildPlayersSnapshot]
]
