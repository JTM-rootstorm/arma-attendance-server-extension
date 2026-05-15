#include "arma_attendance/commands.hpp"

#include <algorithm>
#include <cstring>
#include <string>
#include <string_view>

#if defined(_WIN32)
#define AASE_EXPORT extern "C" __declspec(dllexport)
#define AASE_CALL __stdcall
#else
#define AASE_EXPORT extern "C" __attribute__((visibility("default")))
#define AASE_CALL
#endif

namespace {

void CopyResult(char* output, int output_size, std::string_view value) {
    if (output == nullptr || output_size <= 0) {
        return;
    }

    const auto writable = static_cast<size_t>(output_size - 1);
    const auto count = std::min(writable, value.size());
    std::memcpy(output, value.data(), count);
    output[count] = '\0';
}

} // namespace

AASE_EXPORT void AASE_CALL RVExtensionVersion(char* output, int output_size) {
    CopyResult(output, output_size, arma_attendance::kExtensionVersion);
}

AASE_EXPORT void AASE_CALL RVExtension(char* output, int output_size, const char* function) {
    const std::string result = arma_attendance::ExecuteCommand(function == nullptr ? "" : function);
    CopyResult(output, output_size, result);
}

AASE_EXPORT int AASE_CALL RVExtensionArgs(
    char* output,
    int output_size,
    const char* function,
    const char** argv,
    int argc) {
    const std::string result = arma_attendance::ExecuteCommand(function == nullptr ? "" : function, argc, argv);
    CopyResult(output, output_size, result);
    return 0;
}
