params ["_logic", "_units", "_activated"];

if (!isServer) exitWith {
    [_logic] call AASE_fnc_deleteModuleLogic;
};

if (!_activated) exitWith {
    [_logic] call AASE_fnc_deleteModuleLogic;
};

private _result = [
    "zeus_module",
    createHashMapFromArray [
        ["source_detail", "Stats: Start Operation"],
        ["logic_net_id", netId _logic]
    ]
] call AASE_fnc_operationStart;
[format ["Start operation result: %1", _result], "INFO"] call AASE_fnc_log;

[_logic] call AASE_fnc_deleteModuleLogic;

_result
