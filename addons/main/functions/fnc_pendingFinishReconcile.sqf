if (!isServer) exitWith {};
if (missionNamespace getVariable ["AASE_pendingFinishReconcileRunning", false]) exitWith {};
missionNamespace setVariable ["AASE_pendingFinishReconcileRunning", true, false];

while {(missionNamespace getVariable ["AASE_operationState", "inactive"]) isEqualTo "finish_pending"} do {
    private _requestId = missionNamespace getVariable ["AASE_pendingFinishRequestId", ""];
    if (_requestId isEqualTo "") exitWith {};
    ["queue_flush", []] call TCWA3_fnc_callExtension;
    private _result = ["queue_result_consume", [_requestId]] call TCWA3_fnc_callExtension;
    if ((_result find '"found":true') >= 0) exitWith {
        missionNamespace setVariable ["AASE_operationState", "finished", false];
        missionNamespace setVariable ["AASE_operationActive", false, false];
        missionNamespace setVariable ["AASE_operationId", "", false];
        missionNamespace setVariable ["AASE_pendingFinishRequestId", "", false];
        missionNamespace setVariable ["AASE_pendingFinishPayload", createHashMap, false];
        [] call TCWA3_fnc_presenceStopLoop;
        ["Queued operation finish reconciled and local state cleared.", "INFO"] call TCWA3_fnc_log;
    };
    uiSleep 15;
};
missionNamespace setVariable ["AASE_pendingFinishReconcileRunning", false, false];
