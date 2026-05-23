params [["_name", ""], ["_fallback", ""]];

private _sanitized = [];
private _lastWasSpace = true;

{
    private _isDigit = _x >= 48 && {_x <= 57};
    private _isUpper = _x >= 65 && {_x <= 90};
    private _isLower = _x >= 97 && {_x <= 122};

    if (_isDigit || {_isUpper || {_isLower}}) then {
        _sanitized pushBack _x;
        _lastWasSpace = false;
    } else {
        if (!_lastWasSpace) then {
            _sanitized pushBack 32;
            _lastWasSpace = true;
        };
    };
} forEach toArray _name;

private _count = count _sanitized;
if (_count > 0 && {(_sanitized select (_count - 1)) isEqualTo 32}) then {
    _sanitized deleteAt (_count - 1);
};

private _result = toString _sanitized;
if (_result isEqualTo "") exitWith {_fallback};

_result
