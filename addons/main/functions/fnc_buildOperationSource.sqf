params [
    ["_sourceKind", "scripted"],
    ["_sourceMeta", createHashMap]
];

private _detail = _sourceMeta getOrDefault ["source_detail", ""];
if (_detail isEqualTo "") then {
    _detail = _sourceMeta getOrDefault ["entrypoint_detail", ""];
};

private _automation = _sourceKind in [
    "named_trigger",
    "delayed_auto_start",
    "mission_end_fallback"
];

private _source = createHashMapFromArray [
    ["kind", "arma3-addon"],
    ["entrypoint", _sourceKind],
    ["entrypoint_detail", _detail],
    ["addon", "arma_attendance"],
    ["extension", "arma_attendance"],
    ["automation", _automation]
];

{
    private _key = _x;
    if !(_key in ["source_detail", "entrypoint_detail", "delete_logic"]) then {
        _source set [_key, _y];
    };
} forEach _sourceMeta;

_source
