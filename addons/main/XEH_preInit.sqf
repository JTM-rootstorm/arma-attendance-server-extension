#include "script_component.hpp"
#include "XEH_PREP.hpp"

[] call FUNC(registerAutomationSettings);

[] spawn {
    waitUntil { !isNil "CBA_settingsInitialized" || {time > 0} };
    [] call AASE_fnc_autoInit;
};

["TCWA3 Stats Tracker addon initialized.", "INFO"] call FUNC(log);
