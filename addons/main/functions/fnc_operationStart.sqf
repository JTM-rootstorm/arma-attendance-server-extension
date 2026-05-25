params [
    ["_sourceKind", "scripted"],
    ["_sourceMeta", createHashMap]
];

if (!isServer) exitWith {""};

if (missionNamespace getVariable ["AASE_operationActive", false]) exitWith {
    [format ["Operation start skipped because an operation is already active. source=%1", _sourceKind], "WARN"] call TCWA3_fnc_log;
    ""
};

private _payload = [_sourceKind, _sourceMeta] call TCWA3_fnc_buildOperationStartPayload;
private _payloadJson = [_payload] call TCWA3_fnc_encodeJson;
private _result = ["operation_start", [_payloadJson]] call TCWA3_fnc_callExtension;
private _operationId = [_result, "operation_id"] call TCWA3_fnc_extractJsonStringField;

if (_operationId isNotEqualTo "") then {
    private _mission = _payload get "mission";
    missionNamespace setVariable ["AASE_operationActive", true, false];
    missionNamespace setVariable ["AASE_operationId", _operationId, false];
    missionNamespace setVariable ["AASE_operationStartRequestId", _payload get "request_id", false];
    missionNamespace setVariable ["AASE_operationMissionUid", _mission getOrDefault ["mission_uid", ""], false];
    missionNamespace setVariable ["AASE_operationStartSource", _payload get "source", false];
    [_operationId, 0.5] call TCWA3_fnc_presenceInit;
    [format ["Operation started: %1 source=%2", _operationId, _sourceKind], "INFO"] call TCWA3_fnc_log;
} else {
    [format ["Operation start did not return operation_id: %1", _result], "ERROR"] call TCWA3_fnc_log;
};

_result
