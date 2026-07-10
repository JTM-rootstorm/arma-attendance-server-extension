#pragma once

#include <filesystem>
#include <mutex>
#include <nlohmann/json.hpp>
#include <string>
#include <vector>

namespace arma_attendance {

struct StoreResult {
    bool ok{false};
    std::string error;
};

struct LoadResult {
    bool ok{false};
    std::vector<nlohmann::json> records;
    std::string error;
};

class QueueStore {
public:
    QueueStore(std::filesystem::path pending, std::filesystem::path sent,
               std::filesystem::path dead, std::filesystem::path results);

    StoreResult append_pending(const nlohmann::json& record);
    LoadResult load_pending();
    StoreResult replace_pending(const std::vector<nlohmann::json>& records);
    StoreResult append_sent(const nlohmann::json& record);
    StoreResult append_dead_letter(const nlohmann::json& record);
    StoreResult append_result(const nlohmann::json& record);
    LoadResult load_results();
    StoreResult replace_results(const std::vector<nlohmann::json>& records);
    size_t count_pending() const;
    size_t count_sent() const;
    size_t count_dead_letter() const;

private:
    StoreResult append(const std::filesystem::path& path, const nlohmann::json& record);
    LoadResult load(const std::filesystem::path& path, bool dead_letter_parse_errors);
    StoreResult replace(const std::filesystem::path& path, const std::vector<nlohmann::json>& records);
    size_t count(const std::filesystem::path& path) const;

    std::filesystem::path pending_;
    std::filesystem::path sent_;
    std::filesystem::path dead_;
    std::filesystem::path results_;
    static std::recursive_mutex mutex_;
};

} // namespace arma_attendance
