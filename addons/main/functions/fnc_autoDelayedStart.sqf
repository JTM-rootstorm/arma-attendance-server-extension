if (!isServer) exitWith {};

if (missionNamespace getVariable ["AASE_autoDelayedStartFired", false]) exitWith {};

private _handle = missionNamespace getVariable ["AASE_autoDelayedStartHandle", scriptNull];
if (!scriptDone _handle) exitWith {};

missionNamespace setVariable ["AASE_autoDelayedStartRunning", true, false];

_handle = [] spawn {
    waitUntil {time > 0};

    private _delaySeconds = missionNamespace getVariable ["AASE_autoStartDelaySeconds", 300];
    if (_delaySeconds < 0) then {
        _delaySeconds = 0;
    };

    private _minPlayers = missionNamespace getVariable ["AASE_autoStartMinPlayers", 1];
    if (_minPlayers < 0) then {
        _minPlayers = 0;
    };

    [format [
        "Delayed auto-start waiting: delaySeconds=%1 minPlayers=%2",
        _delaySeconds,
        _minPlayers
    ], "INFO"] call AASE_fnc_log;

    sleep _delaySeconds;

    waitUntil {
        private _operationActive = missionNamespace getVariable ["AASE_operationActive", false];
        private _playersReady = (count ([] call AASE_fnc_activePlayerUnits)) >= _minPlayers;
        _operationActive || {_playersReady}
    };

    if (missionNamespace getVariable ["AASE_operationActive", false]) exitWith {
        missionNamespace setVariable ["AASE_autoDelayedStartFired", true, false];
        missionNamespace setVariable ["AASE_autoDelayedStartRunning", false, false];
        ["Delayed auto-start skipped because an operation is already active.", "INFO"] call AASE_fnc_log;
    };

    private _playerCount = count ([] call AASE_fnc_activePlayerUnits);
    missionNamespace setVariable ["AASE_autoDelayedStartFired", true, false];
    missionNamespace setVariable ["AASE_autoDelayedStartRunning", false, false];

    [
        "delayed_auto_start",
        createHashMapFromArray [
            ["source_detail", format ["delay=%1 min_players=%2", _delaySeconds, _minPlayers]],
            ["delay_seconds", _delaySeconds],
            ["min_players", _minPlayers],
            ["player_count", _playerCount]
        ]
    ] call AASE_fnc_operationStart;
};

missionNamespace setVariable ["AASE_autoDelayedStartHandle", _handle, false];
