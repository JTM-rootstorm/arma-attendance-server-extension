params ["_json", "_field"];

private _needle = format ['"%1"', _field];
private _keyIndex = _json find _needle;
if (_keyIndex < 0) exitWith {""};

private _tail = _json select [_keyIndex + count _needle];
private _colonIndex = _tail find ":";
if (_colonIndex < 0) exitWith {""};

private _afterColon = _tail select [_colonIndex + 1];
private _quoteIndex = _afterColon find '"';
if (_quoteIndex < 0) exitWith {""};

private _valueStart = _quoteIndex + 1;
private _valueTail = _afterColon select [_valueStart];
private _endQuoteIndex = _valueTail find '"';
if (_endQuoteIndex < 0) exitWith {""};

_valueTail select [0, _endQuoteIndex]
