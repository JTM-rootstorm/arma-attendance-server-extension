params [
    ["_logic", objNull, [objNull]],
    ["_units", [], [[]]],
    ["_activated", true, [true]]
];

if (!isServer) exitWith {
    [_logic] call TCWA3_fnc_deleteModuleLogic;
};

if (!_activated) exitWith {
    [_logic] call TCWA3_fnc_deleteModuleLogic;
};

private _result = [
    "zeus_module",
    createHashMapFromArray [
        ["source_detail", "Stats: Finish Operation"],
        ["logic_net_id", netId _logic]
    ]
] call TCWA3_fnc_operationFinish;
[format ["Finish operation result: %1", _result], "INFO"] call TCWA3_fnc_log;

[_logic] call TCWA3_fnc_deleteModuleLogic;

_result
