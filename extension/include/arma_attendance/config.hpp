#pragma once

#include <chrono>
#include <filesystem>
#include <optional>
#include <string>

namespace arma_attendance {

struct Config {
    std::string base_url;
    std::string api_token;
    std::string server_key{"main-unit-server"};
    std::chrono::milliseconds timeout{3000};
    bool verify_tls{true};
    std::filesystem::path source_path;
};

struct ConfigLoadResult {
    Config config;
    std::optional<std::string> warning;
};

ConfigLoadResult LoadConfig();
ConfigLoadResult ReloadConfig();
Config CurrentConfig();
std::string RedactedConfigJson(const Config& config);

} // namespace arma_attendance
