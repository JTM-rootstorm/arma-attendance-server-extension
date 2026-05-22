params ["_operationId"];

private _mission = [] call AASE_fnc_buildMissionPayload;
private _requestId = format ["arma3:finish:%1:%2", _operationId, round diag_tickTime];

createHashMapFromArray [
    ["request_id", _requestId],
    ["payload_version", 1],
    ["mission", _mission],
    ["source", createHashMapFromArray [
        ["kind", "arma3-addon"],
        ["addon", "aase_main"],
        ["extension", "arma_attendance"],
        ["stats_source", "arma_getPlayerScores_delta"]
    ]],
    ["operation_id", _operationId],
    ["players", [true] call AASE_fnc_buildPlayersSnapshot],
    ["attendance_records", [] call AASE_fnc_buildAttendanceRecords]
]
