#pragma once

#include <span>
#include <string>
#include <string_view>

namespace arma_attendance {

constexpr std::string_view kExtensionVersion = "arma_attendance 0.1.0";

std::string ExecuteCommand(std::string_view command, std::span<const std::string> args = {});
std::string ExecuteCommand(std::string_view command, int argc, const char* const* argv);

} // namespace arma_attendance
