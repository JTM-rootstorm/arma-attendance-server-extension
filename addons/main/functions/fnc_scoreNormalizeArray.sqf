params [["_scores", []]];

if !(_scores isEqualType []) then {
    _scores = [];
};

private _normalized = [];
for "_index" from 0 to 5 do {
    private _value = 0;
    if (_index < count _scores) then {
        private _candidate = _scores select _index;
        if (_candidate isEqualType 0) then {
            _value = floor _candidate;
        };
    };
    _normalized pushBack _value;
};

_normalized
