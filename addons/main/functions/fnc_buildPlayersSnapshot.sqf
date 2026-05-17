params [["_includeStats", false]];

private _players = [];
{
    private _snapshot = [_x, _includeStats] call AASE_fnc_buildPlayerSnapshot;
    if (count _snapshot > 0) then {
        _players pushBack _snapshot;
    };
} forEach allPlayers;

_players
