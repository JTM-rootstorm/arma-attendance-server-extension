#include "arma_attendance/config.hpp"

#include "arma_attendance/json.hpp"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <fstream>
#include <mutex>
#include <sstream>
#include <string>
#include <string_view>

namespace arma_attendance {
namespace {

std::mutex g_config_mutex;
Config g_config;

std::string Trim(std::string value) {
    auto not_space = [](unsigned char ch) { return !std::isspace(ch); };
    value.erase(value.begin(), std::find_if(value.begin(), value.end(), not_space));
    value.erase(std::find_if(value.rbegin(), value.rend(), not_space).base(), value.end());
    return value;
}

std::string Unquote(std::string value) {
    value = Trim(std::move(value));
    if (value.size() >= 2 && value.front() == '"' && value.back() == '"') {
        return value.substr(1, value.size() - 2);
    }
    return value;
}

std::optional<std::string> GetEnv(std::string_view name) {
    if (const char* value = std::getenv(std::string{name}.c_str())) {
        if (*value != '\0') {
            return std::string{value};
        }
    }
    return std::nullopt;
}

std::optional<bool> ParseBool(std::string value) {
    std::ranges::transform(value, value.begin(), [](unsigned char ch) { return static_cast<char>(std::tolower(ch)); });
    if (value == "true" || value == "1" || value == "yes") {
        return true;
    }
    if (value == "false" || value == "0" || value == "no") {
        return false;
    }
    return std::nullopt;
}

void ApplyEnv(Config& config) {
    if (auto value = GetEnv("AASE_BASE_URL")) {
        config.base_url = *value;
    }
    if (auto value = GetEnv("AASE_API_TOKEN")) {
        config.api_token = *value;
    }
    if (auto value = GetEnv("AASE_SERVER_KEY")) {
        config.server_key = *value;
    }
    if (auto value = GetEnv("AASE_TIMEOUT_MS")) {
        try {
            const auto timeout = std::clamp(std::stoi(*value), 1, 10000);
            config.timeout = std::chrono::milliseconds{timeout};
        } catch (...) {
        }
    }
    if (auto value = GetEnv("AASE_VERIFY_TLS")) {
        if (auto parsed = ParseBool(*value)) {
            config.verify_tls = *parsed;
        }
    }
}

void ApplyTomlFile(Config& config, const std::filesystem::path& path) {
    std::ifstream input{path};
    if (!input) {
        return;
    }

    std::string section;
    std::string line;
    while (std::getline(input, line)) {
        const auto comment = line.find('#');
        if (comment != std::string::npos) {
            line.erase(comment);
        }

        line = Trim(std::move(line));
        if (line.empty()) {
            continue;
        }

        if (line.front() == '[' && line.back() == ']') {
            section = Trim(line.substr(1, line.size() - 2));
            continue;
        }

        const auto equals = line.find('=');
        if (equals == std::string::npos) {
            continue;
        }

        const auto key = Trim(line.substr(0, equals));
        const auto value = Unquote(line.substr(equals + 1));
        if (section == "server" && key == "server_key") {
            config.server_key = value;
        } else if (section == "http" && key == "base_url") {
            config.base_url = value;
        } else if (section == "http" && key == "api_token") {
            config.api_token = value;
        } else if (section == "http" && key == "timeout_ms") {
            try {
                const auto timeout = std::clamp(std::stoi(value), 1, 10000);
                config.timeout = std::chrono::milliseconds{timeout};
            } catch (...) {
            }
        } else if (section == "http" && key == "verify_tls") {
            if (auto parsed = ParseBool(value)) {
                config.verify_tls = *parsed;
            }
        }
    }
}

std::filesystem::path ConfigPath() {
    return std::filesystem::current_path() / "arma_attendance.toml";
}

std::string TokenPreview(const std::string& token) {
    if (token.empty()) {
        return "";
    }
    if (token.size() < 8) {
        return "redacted";
    }
    return token.substr(0, 4) + "..." + token.substr(token.size() - 4);
}

} // namespace

ConfigLoadResult LoadConfig() {
    Config config;
    const auto path = ConfigPath();
    if (std::filesystem::exists(path)) {
        ApplyTomlFile(config, path);
        config.source_path = path;
    }
    ApplyEnv(config);

    if (config.base_url.ends_with('/')) {
        config.base_url.pop_back();
    }

    std::lock_guard lock{g_config_mutex};
    g_config = config;
    return ConfigLoadResult{config, std::nullopt};
}

ConfigLoadResult ReloadConfig() {
    return LoadConfig();
}

Config CurrentConfig() {
    {
        std::lock_guard lock{g_config_mutex};
        if (!g_config.base_url.empty() || !g_config.api_token.empty()) {
            return g_config;
        }
    }

    return LoadConfig().config;
}

std::string RedactedConfigJson(const Config& config) {
    std::ostringstream output;
    output << "{\"ok\":true,\"command\":\"config\""
           << ",\"server_key\":" << JsonString(config.server_key)
           << ",\"base_url\":" << JsonString(config.base_url)
           << ",\"timeout_ms\":" << config.timeout.count()
           << ",\"verify_tls\":" << (config.verify_tls ? "true" : "false")
           << ",\"api_token_present\":" << (!config.api_token.empty() ? "true" : "false");
    if (!config.api_token.empty()) {
        output << ",\"api_token_preview\":" << JsonString(TokenPreview(config.api_token));
    }
    if (!config.source_path.empty()) {
        output << ",\"source_path\":" << JsonString(config.source_path.string());
    }
    output << "}";
    return output.str();
}

} // namespace arma_attendance
