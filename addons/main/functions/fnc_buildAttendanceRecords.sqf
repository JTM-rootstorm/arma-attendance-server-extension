private _ledger = missionNamespace getVariable ["AASE_presenceByUid", createHashMap];
private _startedAt = missionNamespace getVariable ["AASE_operationStartedAt", serverTime];
private _endedAt = missionNamespace getVariable ["AASE_operationEndedAt", serverTime];
if (_endedAt < _startedAt) then {
    _endedAt = serverTime;
};

private _operationSeconds = _endedAt - _startedAt;
if (_operationSeconds < 0) then {
    _operationSeconds = 0;
};

private _threshold = missionNamespace getVariable ["AASE_attendanceThreshold", 0.5];
private _records = [];

{
    private _record = _y;
    private _attendedSeconds = _record getOrDefault ["attended_seconds", 0];
    if ((_record getOrDefault ["state", "unknown"]) isEqualTo "present") then {
        private _activeSince = _record getOrDefault ["active_since", _endedAt];
        if (_activeSince >= 0) then {
            _attendedSeconds = _attendedSeconds + (_endedAt - _activeSince);
        };
    };
    if (_attendedSeconds < 0) then {
        _attendedSeconds = 0;
    };
    if (_attendedSeconds > _operationSeconds) then {
        _attendedSeconds = _operationSeconds;
    };

    private _attendanceRatio = 0;
    if (_operationSeconds > 0) then {
        _attendanceRatio = _attendedSeconds / _operationSeconds;
    };

    private _attendanceStatus = "absent";
    if (_attendanceRatio >= 0.999) then {
        _attendanceStatus = "full";
    } else {
        if (_attendanceRatio >= _threshold) then {
            _attendanceStatus = "partial";
        };
    };

    private _lastDisconnectAt = _record getOrDefault ["last_disconnect_at", -1];
    private _lastDisconnectOffset = -1;
    if (_lastDisconnectAt >= 0) then {
        _lastDisconnectOffset = _lastDisconnectAt - _startedAt;
    };

    private _lastReconnectAt = _record getOrDefault ["last_reconnect_at", -1];
    private _lastReconnectOffset = -1;
    if (_lastReconnectAt >= 0) then {
        _lastReconnectOffset = _lastReconnectAt - _startedAt;
    };

    _records pushBack createHashMapFromArray [
        ["player_uid", _record getOrDefault ["uid", _x]],
        ["name", _record getOrDefault ["name", ""]],
        ["present_at_start", _record getOrDefault ["present_at_start", false]],
        ["present_at_end", _record getOrDefault ["present_at_end", false]],
        ["joined_after_start", _record getOrDefault ["joined_after_start", false]],
        ["operation_seconds", _operationSeconds],
        ["attended_seconds", _attendedSeconds],
        ["missed_seconds", _operationSeconds - _attendedSeconds],
        ["attendance_ratio", _attendanceRatio],
        ["attendance_percent", _attendanceRatio * 100],
        ["attendance_status", _attendanceStatus],
        ["attendance_credit", _attendanceRatio >= _threshold],
        ["disconnect_count", _record getOrDefault ["disconnect_count", 0]],
        ["reconnect_count", _record getOrDefault ["reconnect_count", 0]],
        ["first_seen_offset", (_record getOrDefault ["first_seen_at", _startedAt]) - _startedAt],
        ["last_seen_offset", (_record getOrDefault ["last_seen_at", _endedAt]) - _startedAt],
        ["last_disconnect_offset", _lastDisconnectOffset],
        ["last_reconnect_offset", _lastReconnectOffset],
        ["side", _record getOrDefault ["side", ""]],
        ["group", _record getOrDefault ["group", ""]],
        ["role", _record getOrDefault ["role", ""]],
        ["unit_class", _record getOrDefault ["unit_class", ""]],
        ["vehicle_class", _record getOrDefault ["vehicle_class", ""]]
    ];
} forEach _ledger;

_records
