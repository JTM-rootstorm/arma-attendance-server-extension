#define PREFIX AASE
#define QUOTE(var1) #var1
#define ADDON DOUBLES(PREFIX,COMPONENT)
#define DOUBLES(var1,var2) var1##_##var2
#define FUNC(var1) DOUBLES(PREFIX,fnc_##var1)
#define QFUNC(var1) QUOTE(FUNC(var1))
#define GVAR(var1) DOUBLES(PREFIX,var1)
#define QGVAR(var1) QUOTE(GVAR(var1))
