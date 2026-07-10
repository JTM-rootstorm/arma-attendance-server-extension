params [
    ["_sourceKind", "scripted"],
    ["_sourceMeta", createHashMap]
];

if (!isServer) exitWith {""};

private _state = missionNamespace getVariable ["AASE_operationState", "inactive"];
if !(_state in ["inactive", "finished"]) exitWith {
    [format ["Operation start skipped because state is %1. source=%2", _state, _sourceKind], "WARN"] call TCWA3_fnc_log;
    ""
};

private _payload = [_sourceKind, _sourceMeta] call TCWA3_fnc_buildOperationStartPayload;
private _payloadJson = [_payload] call TCWA3_fnc_encodeJson;
private _result = ["operation_start", [_payloadJson]] call TCWA3_fnc_callExtension;
private _operationId = [_result, "operation_id"] call TCWA3_fnc_extractJsonStringField;
private _requestId = _payload get "request_id";

if (_operationId isNotEqualTo "") then {
    private _mission = _payload get "mission";
    missionNamespace setVariable ["AASE_operationActive", true, false];
    missionNamespace setVariable ["AASE_operationState", "active", false];
    missionNamespace setVariable ["AASE_operationId", _operationId, false];
    missionNamespace setVariable ["AASE_operationStartRequestId", _payload get "request_id", false];
    missionNamespace setVariable ["AASE_operationMissionUid", _mission getOrDefault ["mission_uid", ""], false];
    missionNamespace setVariable ["AASE_operationStartSource", _payload get "source", false];
    [_operationId, 0.5] call TCWA3_fnc_presenceInit;
    [true] call TCWA3_fnc_autoMissionEndFallback;
    [format ["Operation started: %1 source=%2", _operationId, _sourceKind], "INFO"] call TCWA3_fnc_log;
} else {
    if ((_result find '"queued":true') >= 0) then {
        private _mission = _payload get "mission";
        missionNamespace setVariable ["AASE_operationState", "start_pending", false];
        missionNamespace setVariable ["AASE_operationActive", true, false];
        missionNamespace setVariable ["AASE_pendingStartRequestId", _requestId, false];
        missionNamespace setVariable ["AASE_operationStartRequestId", _requestId, false];
        missionNamespace setVariable ["AASE_operationMissionUid", _mission getOrDefault ["mission_uid", ""], false];
        missionNamespace setVariable ["AASE_operationStartSource", _payload get "source", false];
        [_requestId, 0.5] call TCWA3_fnc_presenceInit;
        missionNamespace setVariable ["AASE_operationState", "start_pending", false];
        [] spawn TCWA3_fnc_pendingStartReconcile;
        [format ["Operation start durably queued; provisional tracking active. request_id=%1", _requestId], "WARN"] call TCWA3_fnc_log;
    } else {
        [format ["Operation start failed before durable queueing: %1", _result], "ERROR"] call TCWA3_fnc_log;
    };
};

_result
