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

## Manual Zeus Controls

Automation does not remove or hide the existing Zeus modules:

```text
Attendance: Debug API Poke
Attendance: Start Operation
Attendance: Finish Operation
```

The modules remain the manual control path for admins and Zeus operators. They
run server-side, call the common operation functions, and delete their module
logic after success, failure, or an inactive/non-server exit.

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

## Delayed Auto-Start

Delayed auto-start waits for mission time to begin, then waits the configured
delay and minimum non-headless player count before starting attendance:

```sqf
force AASE_autoStartMode = 2;
force AASE_autoStartDelaySeconds = 300;
force AASE_autoStartMinPlayers = 5;
```

If a Zeus module or named trigger starts the operation before the delay path
fires, delayed auto-start marks itself complete and does not start a second
operation.

## Mission-End Fallback

Mission-end fallback is disabled by default. When enabled, the server registers
one mission-ended handler and attempts a final operation finish only if an
operation is still active:

```sqf
force AASE_enableMissionEndFallback = true;
```

The finish payload uses `mission_end_fallback` source metadata. If the web API
cannot be reached during shutdown, the native extension queue preserves the
finish request for a later flush.
