#include "script_component.hpp"

class CfgPatches {
    class tcwa3_stats_tracker_main {
        name = "TCWA3 Stats Tracker";
        units[] = {"AASE_Module_DebugPoke", "AASE_Module_StartOperation", "AASE_Module_FinishOperation"};
        weapons[] = {};
        requiredVersion = 2.18;
        requiredAddons[] = {"cba_main", "cba_settings", "cba_xeh", "A3_Modules_F_Curator"};
        author = "JTM-rootstorm";
    };
};

class CfgFactionClasses {
    class AASE_Modules {
        displayName = "TCWA3 Stats Tracker";
        priority = 2;
        side = 7;
    };
};

class CfgFunctions {
    class TCWA3 {
        class main {
            tag = "TCWA3";
            class log {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_log.sqf";
            };
            class encodeJson {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_encodeJson.sqf";
            };
            class sanitizePlayerName {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_sanitizePlayerName.sqf";
            };
            class isHeadlessClient {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_isHeadlessClient.sqf";
            };
            class activePlayerUnits {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_activePlayerUnits.sqf";
            };
            class callExtension {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_callExtension.sqf";
            };
            class poke {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_poke.sqf";
            };
            class moduleDebugPoke {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_moduleDebugPoke.sqf";
            };
            class buildMissionPayload {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_buildMissionPayload.sqf";
            };
            class buildPlayerSnapshot {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_buildPlayerSnapshot.sqf";
            };
            class buildPlayersSnapshot {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_buildPlayersSnapshot.sqf";
            };
            class buildOperationStartPayload {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_buildOperationStartPayload.sqf";
            };
            class buildOperationFinishPayload {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_buildOperationFinishPayload.sqf";
            };
            class deleteModuleLogic {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_deleteModuleLogic.sqf";
            };
            class buildOperationSource {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_buildOperationSource.sqf";
            };
            class registerAutomationSettings {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_registerAutomationSettings.sqf";
            };
            class autoInit {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_autoInit.sqf";
            };
            class startAutomation {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_startAutomation.sqf";
            };
            class stopAutomation {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_stopAutomation.sqf";
            };
            class autoTriggerWatcher {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_autoTriggerWatcher.sqf";
            };
            class autoDelayedStart {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_autoDelayedStart.sqf";
            };
            class autoMissionEndFallback {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_autoMissionEndFallback.sqf";
            };
            class findMissionTriggerByName {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_findMissionTriggerByName.sqf";
            };
            class scoreNormalizeArray {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_scoreNormalizeArray.sqf";
            };
            class scoreInit {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_scoreInit.sqf";
            };
            class scoreCaptureUnit {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_scoreCaptureUnit.sqf";
            };
            class scoreCaptureCurrentPlayers {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_scoreCaptureCurrentPlayers.sqf";
            };
            class scoreDelta {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_scoreDelta.sqf";
            };
            class scoreStatsForUid {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_scoreStatsForUid.sqf";
            };
            class scoreAttachStats {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_scoreAttachStats.sqf";
            };
            class presenceInit {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_presenceInit.sqf";
            };
            class presenceRegisterHandlers {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_presenceRegisterHandlers.sqf";
            };
            class presenceStartLoop {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_presenceStartLoop.sqf";
            };
            class presenceStopLoop {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_presenceStopLoop.sqf";
            };
            class markPlayerPresentFromUnit {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_markPlayerPresentFromUnit.sqf";
            };
            class markUidPresentPending {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_markUidPresentPending.sqf";
            };
            class markPlayerAbsent {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_markPlayerAbsent.sqf";
            };
            class incrementPresenceStat {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_incrementPresenceStat.sqf";
            };
            class presenceFinalizeForEnd {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_presenceFinalizeForEnd.sqf";
            };
            class buildAttendanceRecords {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_buildAttendanceRecords.sqf";
            };
            class extractJsonStringField {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_extractJsonStringField.sqf";
            };
            class operationStart {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_operationStart.sqf";
            };
            class operationFinish {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_operationFinish.sqf";
            };
            class moduleStartOperation {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_moduleStartOperation.sqf";
            };
            class moduleFinishOperation {
                file = "\x\tcwa3_stats_tracker\addons\main\functions\fnc_moduleFinishOperation.sqf";
            };
        };
    };
};

class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase;
        class ModuleDescription;
    };

    class AASE_Module_DebugPoke: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "$STR_AASE_Module_DebugPoke";
        category = "AASE_Modules";
        function = "TCWA3_fnc_moduleDebugPoke";
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 1;
        curatorCanAttach = 0;

        class Attributes: AttributesBase {};
        class ModuleDescription: ModuleDescription {
            description = "$STR_AASE_Module_DebugPoke_Description";
        };
    };

    class AASE_Module_StartOperation: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "$STR_AASE_Module_StartOperation";
        category = "AASE_Modules";
        function = "TCWA3_fnc_moduleStartOperation";
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 1;
        curatorCanAttach = 0;

        class Attributes: AttributesBase {};
        class ModuleDescription: ModuleDescription {
            description = "$STR_AASE_Module_StartOperation_Description";
        };
    };

    class AASE_Module_FinishOperation: Module_F {
        scope = 2;
        scopeCurator = 2;
        displayName = "$STR_AASE_Module_FinishOperation";
        category = "AASE_Modules";
        function = "TCWA3_fnc_moduleFinishOperation";
        functionPriority = 1;
        isGlobal = 1;
        isTriggerActivated = 0;
        isDisposable = 1;
        curatorCanAttach = 0;

        class Attributes: AttributesBase {};
        class ModuleDescription: ModuleDescription {
            description = "$STR_AASE_Module_FinishOperation_Description";
        };
    };
};
