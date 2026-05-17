if (!isServer) exitWith {};

private _handle = missionNamespace getVariable ["AASE_presenceLoopHandle", scriptNull];
if (!scriptDone _handle) exitWith {};

_handle = [] spawn {
    while {missionNamespace getVariable ["AASE_presenceTrackingActive", false]} do {
        private _seenNow = createHashMap;

        {
            private _uid = getPlayerUID _x;
            if (_uid isNotEqualTo "") then {
                _seenNow set [_uid, true];
                [_x, false] call AASE_fnc_markPlayerPresentFromUnit;
            };
        } forEach allPlayers;

        private _ledger = missionNamespace getVariable ["AASE_presenceByUid", createHashMap];
        {
            private _uid = _x;
            private _record = _y;
            if ((_record getOrDefault ["state", "unknown"]) isEqualTo "present") then {
                if (!(_seenNow getOrDefault [_uid, false])) then {
                    [_uid, _record getOrDefault ["name", ""], "reconcile_missing"] call AASE_fnc_markPlayerAbsent;
                };
            };
        } forEach _ledger;

        sleep (missionNamespace getVariable ["AASE_presenceReconcileSeconds", 30]);
    };
};

missionNamespace setVariable ["AASE_presenceLoopHandle", _handle, false];
