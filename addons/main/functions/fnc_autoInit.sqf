if (!isServer) exitWith {};
if (missionNamespace getVariable ["AASE_automationInitialized", false]) exitWith {};

missionNamespace setVariable ["AASE_automationInitialized", true, false];
[] call AASE_fnc_startAutomation;
