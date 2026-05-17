#include "script_component.hpp"

class CfgPatches {
    class aase_main {
        name = "Arma Attendance";
        units[] = {"AASE_Module_DebugPoke", "AASE_Module_StartOperation", "AASE_Module_FinishOperation"};
        weapons[] = {};
        requiredVersion = 2.18;
        requiredAddons[] = {"cba_main", "cba_xeh", "A3_Modules_F_Curator"};
        author = "JTM-rootstorm";
    };
};

class CfgFactionClasses {
    class AASE_Modules {
        displayName = "Attendance";
        priority = 2;
        side = 7;
    };
};

class CfgFunctions {
    class AASE {
        class main {
            tag = "AASE";
            class log {
                file = "\x\aase\addons\main\functions\fnc_log.sqf";
            };
            class callExtension {
                file = "\x\aase\addons\main\functions\fnc_callExtension.sqf";
            };
            class poke {
                file = "\x\aase\addons\main\functions\fnc_poke.sqf";
            };
            class moduleDebugPoke {
                file = "\x\aase\addons\main\functions\fnc_moduleDebugPoke.sqf";
            };
            class buildMissionPayload {
                file = "\x\aase\addons\main\functions\fnc_buildMissionPayload.sqf";
            };
            class buildPlayerSnapshot {
                file = "\x\aase\addons\main\functions\fnc_buildPlayerSnapshot.sqf";
            };
            class buildPlayersSnapshot {
                file = "\x\aase\addons\main\functions\fnc_buildPlayersSnapshot.sqf";
            };
            class buildOperationStartPayload {
                file = "\x\aase\addons\main\functions\fnc_buildOperationStartPayload.sqf";
            };
            class buildOperationFinishPayload {
                file = "\x\aase\addons\main\functions\fnc_buildOperationFinishPayload.sqf";
            };
            class extractJsonStringField {
                file = "\x\aase\addons\main\functions\fnc_extractJsonStringField.sqf";
            };
            class operationStart {
                file = "\x\aase\addons\main\functions\fnc_operationStart.sqf";
            };
            class operationFinish {
                file = "\x\aase\addons\main\functions\fnc_operationFinish.sqf";
            };
            class moduleStartOperation {
                file = "\x\aase\addons\main\functions\fnc_moduleStartOperation.sqf";
            };
            class moduleFinishOperation {
                file = "\x\aase\addons\main\functions\fnc_moduleFinishOperation.sqf";
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
        function = "AASE_fnc_moduleDebugPoke";
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
        function = "AASE_fnc_moduleStartOperation";
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
        function = "AASE_fnc_moduleFinishOperation";
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
