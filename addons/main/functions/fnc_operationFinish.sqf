params [
    ["_sourceKind", "scripted"],
    ["_sourceMeta", createHashMap]
];

if (!isServer) exitWith {""};

private _operationId = missionNamespace getVariable ["AASE_operationId", ""];
if (_operationId isEqualTo "") exitWith {
    [format ["Operation finish skipped because no operation is active. source=%1", _sourceKind], "WARN"] call TCWA3_fnc_log;
    ""
};

[] call TCWA3_fnc_presenceFinalizeForEnd;

private _payload = [_operationId, _sourceKind, _sourceMeta] call TCWA3_fnc_buildOperationFinishPayload;
private _payloadJson = [_payload] call TCWA3_fnc_encodeJson;
private _result = ["operation_finish", [_operationId, _payloadJson]] call TCWA3_fnc_callExtension;
private _accepted = (_result find '"ok":true') >= 0 && {(_result find '"accepted":true') >= 0};

if (_accepted) then {
    missionNamespace setVariable ["AASE_operationActive", false, false];
    missionNamespace setVariable ["AASE_operationId", "", false];
    missionNamespace setVariable ["AASE_operationStartRequestId", "", false];
    missionNamespace setVariable ["AASE_operationMissionUid", "", false];
    missionNamespace setVariable ["AASE_operationStartSource", createHashMap, false];
    [] call TCWA3_fnc_presenceStopLoop;
    [format ["Operation finished: %1 source=%2", _operationId, _sourceKind], "INFO"] call TCWA3_fnc_log;
} else {
    [format ["Operation finish failed; keeping active operation state: %1", _result], "ERROR"] call TCWA3_fnc_log;
};

_result
