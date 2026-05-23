# Operation Automation

Arma Attendance keeps the Zeus modules as manual controls and adds optional
server-side automation through CBA settings. Automation calls the same
`AASE_fnc_operationStart` and `AASE_fnc_operationFinish` functions used by the
modules; it does not spawn module objects.

Automation is disabled by default:

```sqf
force AASE_autoStartMode = 0;
force AASE_autoFinishMode = 0;
force AASE_enableMissionEndFallback = false;
```

## Named Triggers

Mission makers can place normal vanilla triggers and name them with mission
namespace variable names. The defaults are:

```text
aase_start_trigger
aase_finish_trigger
```

Server-side CBA settings enable the watcher:

```sqf
force AASE_autoStartMode = 1;
force AASE_autoFinishMode = 1;
force AASE_startTriggerName = "aase_start_trigger";
force AASE_finishTriggerName = "aase_finish_trigger";
force AASE_triggerPollSeconds = 5;
```

The watcher runs only on the server. Each trigger fires at most once. If the
start trigger activates while an operation is already active, or the finish
trigger activates before one exists, the addon logs the condition and does not
call the native extension.
