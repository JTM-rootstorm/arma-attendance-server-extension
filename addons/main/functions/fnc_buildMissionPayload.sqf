private _missionName = missionName;
if (_missionName isEqualTo "") then {
    _missionName = briefingName;
};
if (_missionName isEqualTo "") then {
    _missionName = "unknown-mission";
};

private _missionUid = missionNamespace getVariable ["AASE_operationMissionUid", ""];
if (_missionUid isEqualTo "") then {
    _missionUid = format ["%1:%2:%3", worldName, _missionName, round diag_tickTime];
};

createHashMapFromArray [
    ["mission_uid", _missionUid],
    ["mission_name", _missionName],
    ["world_name", worldName]
]
