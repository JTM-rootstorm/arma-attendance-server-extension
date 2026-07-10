#include "script_component.hpp"

// Functions are registered through CfgFunctions. Including XEH_PREP here
// re-compiles final functions on mission load and spams the server RPT.

[] call FUNC(registerAutomationSettings);

[] spawn {
    waitUntil { !isNil "CBA_settingsInitialized" || {time > 0} };
    [] call TCWA3_fnc_autoInit;
};

["TCWA3 Stats Tracker addon initialized.", "INFO"] call FUNC(log);
