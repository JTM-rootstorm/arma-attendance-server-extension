#include "script_component.hpp"

class CfgPatches {
    class aase_main {
        name = "Arma Attendance";
        units[] = {"AASE_Module_DebugPoke"};
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
            file = "\x\aase\addons\main\functions";
            class log {};
            class callExtension {};
            class poke {};
            class moduleDebugPoke {};
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
        isDisposable = 0;
        curatorCanAttach = 0;

        class Attributes: AttributesBase {};
        class ModuleDescription: ModuleDescription {
            description = "$STR_AASE_Module_DebugPoke_Description";
        };
    };
};
