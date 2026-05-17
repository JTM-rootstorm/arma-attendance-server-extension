if (!isServer) exitWith {};

if (missionNamespace getVariable ["AASE_presenceFinalized", false]) exitWith {};

private _endedAt = missionNamespace getVariable ["AASE_operationEndedAt", -1];
if (_endedAt < 0) then {
    _endedAt = serverTime;
    missionNamespace setVariable ["AASE_operationEndedAt", _endedAt, false];
};

private _presentAtEnd = createHashMap;
{
    private _uid = getPlayerUID _x;
    if (_uid isNotEqualTo "") then {
        _presentAtEnd set [_uid, true];
        [_x, false] call AASE_fnc_markPlayerPresentFromUnit;
    };
} forEach allPlayers;

private _ledger = missionNamespace getVariable ["AASE_presenceByUid", createHashMap];
{
    private _uid = _x;
    private _record = _y;
    _record set ["present_at_end", _presentAtEnd getOrDefault [_uid, false]];
    _ledger set [_uid, _record];
} forEach _ledger;

{
    [_x, _y getOrDefault ["name", ""], "operation_end"] call AASE_fnc_markPlayerAbsent;
} forEach _ledger;

{
    _y set ["state", "finalized"];
    _ledger set [_x, _y];
} forEach _ledger;

missionNamespace setVariable ["AASE_presenceByUid", _ledger, false];
missionNamespace setVariable ["AASE_presenceFinalized", true, false];
[] call AASE_fnc_presenceStopLoop;
