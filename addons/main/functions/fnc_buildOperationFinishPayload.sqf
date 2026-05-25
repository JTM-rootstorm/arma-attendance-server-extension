params [
    "_operationId",
    ["_sourceKind", "scripted"],
    ["_sourceMeta", createHashMap]
];

private _mission = [] call TCWA3_fnc_buildMissionPayload;
private _requestId = format ["arma3:finish:%1:%2", _operationId, round diag_tickTime];
private _source = [_sourceKind, _sourceMeta] call TCWA3_fnc_buildOperationSource;
_source set ["stats_source", "arma_getPlayerScores_delta"];

createHashMapFromArray [
    ["request_id", _requestId],
    ["payload_version", 1],
    ["mission", _mission],
    ["source", _source],
    ["operation_id", _operationId],
    ["players", [true] call TCWA3_fnc_buildPlayersSnapshot],
    ["attendance_records", [] call TCWA3_fnc_buildAttendanceRecords]
]
