if (!isServer) exitWith {""};

private _operationId = missionNamespace getVariable ["AASE_operationId", ""];
if (_operationId isEqualTo "") exitWith {
    ["Operation finish skipped because no operation is active.", "WARN"] call AASE_fnc_log;
    ""
};

[] call AASE_fnc_presenceFinalizeForEnd;

private _payload = [_operationId] call AASE_fnc_buildOperationFinishPayload;
private _payloadJson = [_payload] call CBA_fnc_encodeJSON;
private _result = ["operation_finish", [_operationId, _payloadJson]] call AASE_fnc_callExtension;
private _accepted = (_result find '"ok":true') >= 0 && {(_result find '"accepted":true') >= 0};

if (_accepted) then {
    missionNamespace setVariable ["AASE_operationActive", false, false];
    missionNamespace setVariable ["AASE_operationId", "", false];
    missionNamespace setVariable ["AASE_operationStartRequestId", "", false];
    missionNamespace setVariable ["AASE_operationMissionUid", "", false];
    [] call AASE_fnc_presenceStopLoop;
    [format ["Operation finished: %1", _operationId], "INFO"] call AASE_fnc_log;
} else {
    [format ["Operation finish failed; keeping active operation state: %1", _result], "ERROR"] call AASE_fnc_log;
};

_result
