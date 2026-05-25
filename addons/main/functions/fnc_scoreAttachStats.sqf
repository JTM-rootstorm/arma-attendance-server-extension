params ["_target", "_uid"];

if !(_target isEqualType createHashMap) exitWith {_target};
if (_uid isEqualTo "") exitWith {_target};

private _bundle = [_uid] call TCWA3_fnc_scoreStatsForUid;
_target set ["stats", _bundle get "stats"];
_target set ["scoreboard_stats", _bundle get "scoreboard_stats"];

_target
