#include "arma_attendance/commands.hpp"

#include "arma_attendance/config.hpp"
#include "arma_attendance/http_client.hpp"
#include "arma_attendance/json.hpp"

#include <exception>
#include <chrono>
#include <cctype>
#include <iomanip>
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

bool LooksLikeJsonObject(std::string_view body) {
    const auto first = body.find_first_not_of(" \t\r\n");
    if (first == std::string_view::npos) {
        return false;
    }
    const auto last = body.find_last_not_of(" \t\r\n");
    return body[first] == '{' && body[last] == '}';
}

std::string ExtractJsonStringField(std::string_view body, std::string_view field) {
    const std::string needle = "\"" + std::string{field} + "\"";
    const auto key = body.find(needle);
    if (key == std::string_view::npos) {
        return {};
    }

    const auto colon = body.find(':', key + needle.size());
    if (colon == std::string_view::npos) {
        return {};
    }

    auto quote = body.find('"', colon + 1);
    if (quote == std::string_view::npos) {
        return {};
    }

    std::string value;
    for (++quote; quote < body.size(); ++quote) {
        const char ch = body[quote];
        if (ch == '"' && (quote == 0 || body[quote - 1] != '\\')) {
            return value;
        }
        value.push_back(ch);
    }
    return {};
}

bool JsonObjectHasField(std::string_view body, std::string_view field) {
    return body.find("\"" + std::string{field} + "\"") != std::string_view::npos;
}

std::string AddJsonFieldIfMissing(std::string body, std::string_view field, std::string_view encoded_value) {
    if (JsonObjectHasField(body, field)) {
        return body;
    }

    const auto first = body.find_first_not_of(" \t\r\n");
    if (first == std::string::npos || body[first] != '{') {
        return body;
    }

    auto insert_at = first + 1;
    const bool has_existing_fields = body.find_first_not_of(" \t\r\n", insert_at) != body.find_last_not_of(" \t\r\n");
    std::string field_text = "\"" + std::string{field} + "\":" + std::string{encoded_value};
    if (has_existing_fields) {
        field_text += ",";
    }
    body.insert(insert_at, field_text);
    return body;
}

std::string MakeRequestId(std::string_view server_key, std::string_view kind) {
    const auto now = std::chrono::system_clock::now().time_since_epoch();
    const auto millis = std::chrono::duration_cast<std::chrono::milliseconds>(now).count();
    return std::string{server_key} + ":" + std::string{kind} + ":" + std::to_string(millis);
}

std::string MinimalOperationPayload(const Config& config, std::string_view kind, std::string_view operation_id = {}) {
    std::ostringstream body;
    body << "{\"request_id\":" << JsonString(MakeRequestId(config.server_key, kind))
         << ",\"server_key\":" << JsonString(config.server_key)
         << ",\"payload_version\":1"
         << ",\"source\":{\"kind\":\"arma3-extension\",\"extension_version\":" << JsonString(kExtensionVersion) << "}"
         << ",\"mission\":{\"mission_uid\":" << JsonString(std::string{"native-smoke:"} + std::string{kind})
         << ",\"mission_name\":" << JsonString("Native Smoke")
         << ",\"world_name\":" << JsonString("VR") << "}"
         << ",\"players\":[]";
    if (!operation_id.empty()) {
        body << ",\"operation_id\":" << JsonString(operation_id);
    }
    body << "}";
    return body.str();
}

std::string NormalizeOperationPayload(std::string body, const Config& config, std::string_view kind) {
    body = AddJsonFieldIfMissing(std::move(body), "server_key", JsonString(config.server_key));
    body = AddJsonFieldIfMissing(std::move(body), "request_id", JsonString(MakeRequestId(config.server_key, kind)));
    body = AddJsonFieldIfMissing(std::move(body), "payload_version", "1");
    return body;
}

std::string UrlEncode(std::string_view value) {
    std::ostringstream encoded;
    encoded << std::uppercase << std::hex;
    for (const unsigned char ch : value) {
        if (std::isalnum(ch) || ch == '-' || ch == '_' || ch == '.' || ch == '~') {
            encoded << static_cast<char>(ch);
        } else {
            encoded << '%' << std::setw(2) << std::setfill('0') << static_cast<int>(ch);
        }
    }
    return encoded.str();
}

std::string HttpJson(std::string_view command, const HttpResponse& response) {
    if (!response.error.empty()) {
        return JsonError(command, response.status == 0 ? "http_request_failed" : "http_status_not_ok", response.error);
    }

    const auto operation_id = ExtractJsonStringField(response.body, "operation_id");
    std::ostringstream output;
    output << "{\"ok\":" << (response.ok ? "true" : "false")
           << ",\"command\":" << JsonString(command)
           << ",\"http_status\":" << response.status;
    if (!operation_id.empty()) {
        output << ",\"operation_id\":" << JsonString(operation_id);
    }
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

std::string MissingArg(std::string_view command, std::string_view name) {
    return JsonError(command, "missing_argument", std::string{name} + " is required.");
}

std::string InvalidJson(std::string_view command) {
    return JsonError(command, "invalid_json", "Expected a compact JSON object argument.");
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

        if (command == "operation_start") {
            if (config.base_url.empty()) {
                return MissingConfig(command, "AASE_BASE_URL");
            }
            if (config.api_token.empty()) {
                return MissingConfig(command, "AASE_API_TOKEN");
            }

            std::string body = args.empty() ? MinimalOperationPayload(config, "start") : args.front();
            if (!LooksLikeJsonObject(body)) {
                return InvalidJson(command);
            }
            body = NormalizeOperationPayload(std::move(body), config, "start");
            return HttpJson(command, HttpPostJson("/v1/operations/start", body, config));
        }

        if (command == "operation_finish") {
            if (config.base_url.empty()) {
                return MissingConfig(command, "AASE_BASE_URL");
            }
            if (config.api_token.empty()) {
                return MissingConfig(command, "AASE_API_TOKEN");
            }

            std::string operation_id;
            std::string body;
            if (args.empty()) {
                return MissingArg(command, "operation_id");
            }
            if (args.size() == 1 && LooksLikeJsonBody(args.front())) {
                body = args.front();
                operation_id = ExtractJsonStringField(body, "operation_id");
            } else {
                operation_id = args.front();
                body = args.size() >= 2 ? args[1] : MinimalOperationPayload(config, "finish", operation_id);
            }
            if (operation_id.empty()) {
                return MissingArg(command, "operation_id");
            }
            if (!LooksLikeJsonObject(body)) {
                return InvalidJson(command);
            }
            body = NormalizeOperationPayload(std::move(body), config, "finish");
            return HttpJson(command, HttpPostJson("/v1/operations/" + UrlEncode(operation_id) + "/finish", body, config));
        }

        if (command == "ingest_request_get") {
            if (args.empty() || args.front().empty()) {
                return MissingArg(command, "request_id");
            }
            return HttpJson(command, HttpGetAuth("/v1/ingest-requests/" + UrlEncode(args.front()), config));
        }

        if (command == "operation_get") {
            if (args.empty() || args.front().empty()) {
                return MissingArg(command, "operation_id");
            }
            return HttpJson(command, HttpGetAuth("/v1/operations/" + UrlEncode(args.front()), config));
        }

        if (command == "operation_attendance_get") {
            if (args.empty() || args.front().empty()) {
                return MissingArg(command, "operation_id");
            }
            return HttpJson(command, HttpGetAuth("/v1/operations/" + UrlEncode(args.front()) + "/attendance", config));
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
