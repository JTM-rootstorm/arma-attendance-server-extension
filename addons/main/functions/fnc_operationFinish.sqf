params [
    ["_sourceKind", "scripted"],
    ["_sourceMeta", createHashMap],
    ["_outcome", "success"]
];

if (!isServer) exitWith {""};

if !(_outcome in ["success", "failed"]) then {
    _outcome = "success";
};

private _operationId = missionNamespace getVariable ["AASE_operationId", ""];
private _state = missionNamespace getVariable ["AASE_operationState", "inactive"];
if (_state isEqualTo "finish_pending") exitWith {
    ["Operation finish skipped because the immutable finish snapshot is already pending.", "WARN"] call TCWA3_fnc_log;
    missionNamespace getVariable ["AASE_pendingFinishResult", ""]
};
if (_operationId isEqualTo "") exitWith {
    [format ["Operation finish skipped because no operation is active. source=%1", _sourceKind], "WARN"] call TCWA3_fnc_log;
    ""
};

[] call TCWA3_fnc_presenceFinalizeForEnd;

private _payload = [_operationId, _sourceKind, _sourceMeta, _outcome] call TCWA3_fnc_buildOperationFinishPayload;
private _existingRequestId = missionNamespace getVariable ["AASE_pendingFinishRequestId", ""];
if (_existingRequestId isNotEqualTo "") then {_payload set ["request_id", _existingRequestId];};
private _payloadJson = [_payload] call TCWA3_fnc_encodeJson;
private _result = ["operation_finish", [_operationId, _payloadJson]] call TCWA3_fnc_callExtension;
private _status = [_result, "status"] call TCWA3_fnc_extractJsonStringField;
private _accepted = (_result find '"ok":true') >= 0
    && {
        ((_result find '"accepted":true') >= 0)
            || {_status in ["finished", "failed"]}
    };

if (_accepted) then {
    missionNamespace setVariable ["AASE_operationActive", false, false];
    missionNamespace setVariable ["AASE_operationState", "finished", false];
    missionNamespace setVariable ["AASE_operationId", "", false];
    missionNamespace setVariable ["AASE_operationStartRequestId", "", false];
    missionNamespace setVariable ["AASE_operationMissionUid", "", false];
    missionNamespace setVariable ["AASE_operationStartSource", createHashMap, false];
    [] call TCWA3_fnc_presenceStopLoop;
    [format ["Operation finish accepted: %1 outcome=%2 source=%3", _operationId, _outcome, _sourceKind], "INFO"] call TCWA3_fnc_log;
} else {
    if ((_result find '"queued":true') >= 0) then {
        missionNamespace setVariable ["AASE_operationState", "finish_pending", false];
        missionNamespace setVariable ["AASE_pendingFinishRequestId", _payload get "request_id", false];
        missionNamespace setVariable ["AASE_pendingFinishPayload", _payload, false];
        missionNamespace setVariable ["AASE_pendingFinishOutcome", _outcome, false];
        missionNamespace setVariable ["AASE_pendingFinishCreatedAt", serverTime, false];
        missionNamespace setVariable ["AASE_pendingFinishResult", _result, false];
        [] spawn TCWA3_fnc_pendingFinishReconcile;
        [format ["Operation finish durably queued with stable request_id=%1", _payload get "request_id"], "WARN"] call TCWA3_fnc_log;
    } else {
        missionNamespace setVariable ["AASE_operationState", "active", false];
        missionNamespace setVariable ["AASE_presenceFinalized", false, false];
        missionNamespace setVariable ["AASE_operationEndedAt", -1, false];
        missionNamespace setVariable ["AASE_presenceTrackingActive", true, false];
        [] call TCWA3_fnc_presenceStartLoop;
        [format ["Operation finish persistence failed; attendance tracking resumed: %1", _result], "ERROR"] call TCWA3_fnc_log;
    };
};

_result
