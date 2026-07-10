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
    std::chrono::milliseconds connect_timeout{1000};
    bool verify_tls{true};
    size_t max_response_bytes{1024 * 1024};
    bool queue_enabled{true};
    std::filesystem::path queue_file{"arma_attendance_queue.ndjson"};
    std::filesystem::path queue_sent_file{"arma_attendance_queue.sent.ndjson"};
    std::filesystem::path queue_dead_letter_file{"tcwa3_stats_tracker_queue.dead.ndjson"};
    std::filesystem::path queue_results_file{"tcwa3_stats_tracker_queue.results.ndjson"};
    int queue_max_attempts{25};
    int queue_flush_budget{3};
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
