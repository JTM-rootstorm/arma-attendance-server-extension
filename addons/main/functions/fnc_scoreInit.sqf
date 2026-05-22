if (!isServer) exitWith {};

missionNamespace setVariable ["AASE_scoreBaselineByUid", createHashMap, false];
missionNamespace setVariable ["AASE_scoreLatestByUid", createHashMap, false];
missionNamespace setVariable ["AASE_statsSource", "scoreboard", false];
missionNamespace setVariable ["AASE_enableExperimentalKillLedger", false, false];
