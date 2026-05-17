if (!isServer) exitWith {""};

if (missionNamespace getVariable ["AASE_operationActive", false]) exitWith {
    ["Operation start skipped because an operation is already active.", "WARN"] call AASE_fnc_log;
    ""
};

private _payload = [] call AASE_fnc_buildOperationStartPayload;
private _payloadJson = [_payload] call CBA_fnc_encodeJSON;
private _result = ["operation_start", [_payloadJson]] call AASE_fnc_callExtension;
private _operationId = [_result, "operation_id"] call AASE_fnc_extractJsonStringField;

if (_operationId isNotEqualTo "") then {
    private _mission = _payload get "mission";
    missionNamespace setVariable ["AASE_operationActive", true, false];
    missionNamespace setVariable ["AASE_operationId", _operationId, false];
    missionNamespace setVariable ["AASE_operationStartRequestId", _payload get "request_id", false];
    missionNamespace setVariable ["AASE_operationMissionUid", _mission getOrDefault ["mission_uid", ""], false];
    [_operationId, 0.5] call AASE_fnc_presenceInit;
    [format ["Operation started: %1", _operationId], "INFO"] call AASE_fnc_log;
} else {
    [format ["Operation start did not return operation_id: %1", _result], "ERROR"] call AASE_fnc_log;
};

_result
