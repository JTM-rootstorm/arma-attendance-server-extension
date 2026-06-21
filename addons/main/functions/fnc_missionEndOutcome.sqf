params [["_endType", "UNKNOWN"]];

private _endTypeText = if (_endType isEqualType "") then {_endType} else {str _endType};
private _upperEndType = toUpper _endTypeText;
private _configuredFailures = missionNamespace getVariable ["AASE_failedMissionEndTypes", []];
private _failureEndTypes = [
    "LOSER",
    "KILLED",
    "DEAD",
    "DEATH",
    "FAIL",
    "FAILED",
    "FAILURE",
    "DEFEAT",
    "DEFEATED"
];

{
    private _configuredEndType = if (_x isEqualType "") then {_x} else {str _x};
    _failureEndTypes pushBackUnique (toUpper _configuredEndType);
} forEach _configuredFailures;

private _failed = _upperEndType in _failureEndTypes;
{
    if ((_upperEndType find _x) >= 0) exitWith {
        _failed = true;
    };
} forEach ["FAIL", "LOSER", "LOSE", "LOST", "KILL", "DEAD", "DEATH", "DEFEAT"];

if (_failed) exitWith {"failed"};
"success"
