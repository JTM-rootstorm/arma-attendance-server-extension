if (!isServer) exitWith {};
if (missionNamespace getVariable ["AASE_pendingStartReconcileRunning", false]) exitWith {};
missionNamespace setVariable ["AASE_pendingStartReconcileRunning", true, false];

while {(missionNamespace getVariable ["AASE_operationState", "inactive"]) isEqualTo "start_pending"} do {
    private _requestId = missionNamespace getVariable ["AASE_pendingStartRequestId", ""];
    if (_requestId isEqualTo "") exitWith {};
    ["queue_flush", []] call TCWA3_fnc_callExtension;
    private _result = ["queue_result_consume", [_requestId]] call TCWA3_fnc_callExtension;
    private _operationId = [_result, "operation_id"] call TCWA3_fnc_extractJsonStringField;
    if (_operationId isNotEqualTo "") exitWith {
        missionNamespace setVariable ["AASE_operationId", _operationId, false];
        missionNamespace setVariable ["AASE_operationState", "active", false];
        missionNamespace setVariable ["AASE_pendingStartRequestId", "", false];
        [true] call TCWA3_fnc_autoMissionEndFallback;
        [format ["Queued operation start reconciled: %1", _operationId], "INFO"] call TCWA3_fnc_log;
    };
    uiSleep 15;
};
missionNamespace setVariable ["AASE_pendingStartReconcileRunning", false, false];
