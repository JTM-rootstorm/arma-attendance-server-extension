if (missionNamespace getVariable ["AASE_automationSettingsRegistered", false]) exitWith {};

private _category = ["Arma Attendance", "Automation"];
private _global = 2;

[
    "AASE_autoStartMode",
    "LIST",
    ["Auto start mode", "How Arma Attendance starts operation tracking automatically."],
    _category,
    [[0, 1, 2], ["Disabled", "Named trigger", "Delay + min players"], 0],
    _global,
    {},
    true
] call CBA_fnc_addSetting;

[
    "AASE_autoFinishMode",
    "LIST",
    ["Auto finish mode", "How Arma Attendance finishes operation tracking automatically."],
    _category,
    [[0, 1], ["Disabled", "Named trigger"], 0],
    _global,
    {},
    true
] call CBA_fnc_addSetting;

[
    "AASE_startTriggerName",
    "EDITBOX",
    ["Start trigger name", "Mission namespace variable name for the vanilla trigger that starts attendance."],
    _category,
    "aase_start_trigger",
    _global,
    {},
    true
] call CBA_fnc_addSetting;

[
    "AASE_finishTriggerName",
    "EDITBOX",
    ["Finish trigger name", "Mission namespace variable name for the vanilla trigger that finishes attendance."],
    _category,
    "aase_finish_trigger",
    _global,
    {},
    true
] call CBA_fnc_addSetting;

[
    "AASE_autoStartDelaySeconds",
    "SLIDER",
    ["Auto start delay", "Seconds to wait before delayed auto-start can begin."],
    _category,
    [0, 3600, 300, 0],
    _global,
    {},
    true
] call CBA_fnc_addSetting;

[
    "AASE_autoStartMinPlayers",
    "SLIDER",
    ["Auto start minimum players", "Minimum non-headless player count required for delayed auto-start."],
    _category,
    [0, 120, 1, 0],
    _global,
    {},
    true
] call CBA_fnc_addSetting;

[
    "AASE_triggerPollSeconds",
    "SLIDER",
    ["Trigger poll seconds", "Seconds between named trigger automation checks."],
    _category,
    [1, 60, 5, 0],
    _global,
    {},
    true
] call CBA_fnc_addSetting;

[
    "AASE_enableMissionEndFallback",
    "CHECKBOX",
    ["Mission-end fallback", "Attempt to finish an active operation if the mission ends first."],
    _category,
    false,
    _global,
    {},
    true
] call CBA_fnc_addSetting;

missionNamespace setVariable ["AASE_automationSettingsRegistered", true, false];
