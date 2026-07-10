#include "arma_attendance/queue_store.hpp"

#include <chrono>
#include <fstream>
#include <system_error>
#if defined(_WIN32)
#include <windows.h>
#endif

namespace arma_attendance {

std::recursive_mutex QueueStore::mutex_;

namespace {
StoreResult EnsureParent(const std::filesystem::path& path) {
    if (path.parent_path().empty()) return {true, {}};
    std::error_code ec;
    std::filesystem::create_directories(path.parent_path(), ec);
    return ec ? StoreResult{false, "queue_directory_create_failed: " + ec.message()} : StoreResult{true, {}};
}
}

QueueStore::QueueStore(std::filesystem::path pending, std::filesystem::path sent,
                       std::filesystem::path dead, std::filesystem::path results)
    : pending_(std::move(pending)), sent_(std::move(sent)), dead_(std::move(dead)), results_(std::move(results)) {}

StoreResult QueueStore::append(const std::filesystem::path& path, const nlohmann::json& record) {
    std::lock_guard lock{mutex_};
    if (auto parent = EnsureParent(path); !parent.ok) return parent;
    std::ofstream out{path, std::ios::app | std::ios::binary};
    if (!out) return {false, "queue_open_failed"};
    out << record.dump() << '\n';
    if (!out) return {false, "queue_write_failed"};
    out.flush();
    if (!out) return {false, "queue_flush_failed"};
    return {true, {}};
}

StoreResult QueueStore::append_pending(const nlohmann::json& record) { return append(pending_, record); }
StoreResult QueueStore::append_sent(const nlohmann::json& record) { return append(sent_, record); }
StoreResult QueueStore::append_dead_letter(const nlohmann::json& record) { return append(dead_, record); }
StoreResult QueueStore::append_result(const nlohmann::json& record) { return append(results_, record); }

LoadResult QueueStore::load(const std::filesystem::path& path, bool dead_letter_parse_errors) {
    std::lock_guard lock{mutex_};
    std::ifstream in{path, std::ios::binary};
    if (!in) {
        if (!std::filesystem::exists(path)) return {true, {}, {}};
        return {false, {}, "queue_open_failed"};
    }
    LoadResult result{true, {}, {}};
    std::string line;
    size_t line_number = 0;
    while (std::getline(in, line)) {
        ++line_number;
        if (line.empty()) continue;
        auto value = nlohmann::json::parse(line, nullptr, false);
        if (value.is_discarded() || !value.is_object()) {
            if (!dead_letter_parse_errors) return {false, {}, "queue_parse_failed at line " + std::to_string(line_number)};
            nlohmann::json dead{{"failure_kind", "parse_error"}, {"line_number", line_number},
                                {"last_error_code", "queue_parse_failed"},
                                {"raw_line", line},
                                {"failed_at", std::chrono::system_clock::to_time_t(std::chrono::system_clock::now())}};
            if (auto saved = append(dead_, dead); !saved.ok) return {false, {}, saved.error};
            continue;
        }
        result.records.push_back(std::move(value));
    }
    return result;
}

LoadResult QueueStore::load_pending() { return load(pending_, true); }
LoadResult QueueStore::load_results() { return load(results_, false); }

StoreResult QueueStore::replace(const std::filesystem::path& path, const std::vector<nlohmann::json>& records) {
    std::lock_guard lock{mutex_};
    if (auto parent = EnsureParent(path); !parent.ok) return parent;
    auto temporary = path;
    temporary += ".tmp";
    {
        std::ofstream out{temporary, std::ios::trunc | std::ios::binary};
        if (!out) return {false, "queue_open_failed"};
        for (const auto& record : records) out << record.dump() << '\n';
        if (!out) return {false, "queue_write_failed"};
        out.flush();
        if (!out) return {false, "queue_flush_failed"};
    }
#if defined(_WIN32)
    if (!MoveFileExW(temporary.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
        std::filesystem::remove(temporary);
        return {false, "queue_replace_failed: " + std::to_string(GetLastError())};
    }
#else
    std::error_code ec;
    std::filesystem::rename(temporary, path, ec);
    if (ec) {
        std::filesystem::remove(temporary);
        return {false, "queue_replace_failed: " + ec.message()};
    }
#endif
    return {true, {}};
}

StoreResult QueueStore::replace_pending(const std::vector<nlohmann::json>& records) { return replace(pending_, records); }
StoreResult QueueStore::replace_results(const std::vector<nlohmann::json>& records) { return replace(results_, records); }

size_t QueueStore::count(const std::filesystem::path& path) const {
    std::lock_guard lock{mutex_};
    std::ifstream in{path};
    size_t result = 0;
    std::string line;
    while (std::getline(in, line)) if (!line.empty()) ++result;
    return result;
}
size_t QueueStore::count_pending() const { return count(pending_); }
size_t QueueStore::count_sent() const { return count(sent_); }
size_t QueueStore::count_dead_letter() const { return count(dead_); }

} // namespace arma_attendance
