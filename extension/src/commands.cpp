#include "arma_attendance/commands.hpp"

#include "arma_attendance/config.hpp"
#include "arma_attendance/http_client.hpp"
#include "arma_attendance/json.hpp"

#include <exception>
#include <sstream>
#include <string>
#include <string_view>
#include <vector>

namespace arma_attendance {
namespace {

bool LooksLikeJsonBody(std::string_view body) {
    const auto first = body.find_first_not_of(" \t\r\n");
    if (first == std::string_view::npos) {
        return false;
    }
    const auto last = body.find_last_not_of(" \t\r\n");
    const auto leading = body[first];
    const auto trailing = body[last];
    return (leading == '{' && trailing == '}') || (leading == '[' && trailing == ']');
}

std::string HttpJson(std::string_view command, const HttpResponse& response) {
    if (!response.error.empty()) {
        return JsonError(command, response.status == 0 ? "http_request_failed" : "http_status_not_ok", response.error);
    }

    std::ostringstream output;
    output << "{\"ok\":" << (response.ok ? "true" : "false")
           << ",\"command\":" << JsonString(command)
           << ",\"http_status\":" << response.status;
    if (LooksLikeJsonBody(response.body)) {
        output << ",\"body\":" << response.body;
    } else {
        output << ",\"body_raw\":" << JsonString(response.body);
    }
    output << "}";
    return output.str();
}

std::string MissingConfig(std::string_view command, std::string_view name) {
    return JsonError(command, "missing_config", std::string{name} + " is not configured.");
}

} // namespace

std::string ExecuteCommand(std::string_view command, std::span<const std::string> args) {
    try {
        if (command == "version") {
            return "{\"ok\":true,\"command\":\"version\",\"version\":" + JsonString(kExtensionVersion) + "}";
        }

        if (command == "reload_config") {
            const auto loaded = ReloadConfig();
            return "{\"ok\":true,\"command\":\"reload_config\",\"config\":" + RedactedConfigJson(loaded.config) + "}";
        }

        const Config config = CurrentConfig();

        if (command == "config") {
            return RedactedConfigJson(config);
        }

        if (command == "health") {
            if (config.base_url.empty()) {
                return MissingConfig(command, "AASE_BASE_URL");
            }
            return HttpJson(command, HttpGet("/health", config));
        }

        if (command == "poke") {
            if (config.base_url.empty()) {
                return MissingConfig(command, "AASE_BASE_URL");
            }
            if (config.api_token.empty()) {
                return MissingConfig(command, "AASE_API_TOKEN");
            }

            const std::string message = args.empty() ? "hello from arma" : args.front();
            const std::string body = "{\"message\":" + JsonString(message) +
                                     ",\"server_key\":" + JsonString(config.server_key) + "}";
            return HttpJson(command, HttpPostJson("/v1/debug/poke", body, config));
        }

        return JsonError(command, "unknown_command", "Unknown command.");
    } catch (const std::exception& ex) {
        return JsonError(command, "internal_error", ex.what());
    } catch (...) {
        return JsonError(command, "internal_error", "Unknown internal error.");
    }
}

std::string ExecuteCommand(std::string_view command, int argc, const char* const* argv) {
    std::vector<std::string> args;
    args.reserve(static_cast<size_t>(argc));
    for (int index = 0; index < argc; ++index) {
        args.emplace_back(argv[index] == nullptr ? "" : argv[index]);
    }
    return ExecuteCommand(command, std::span<const std::string>{args.data(), args.size()});
}

} // namespace arma_attendance
