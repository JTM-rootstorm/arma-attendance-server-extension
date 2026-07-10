#include "arma_attendance/config.hpp"
#include "arma_attendance/json.hpp"

#include <algorithm>
#include <cstdlib>
#include <mutex>
#include <sstream>
#include <vector>
#include <toml++/toml.hpp>

#if defined(_WIN32)
#include <windows.h>
#else
#include <dlfcn.h>
#endif

namespace arma_attendance {
namespace {
std::mutex g_config_mutex;
Config g_config;

std::optional<std::string> Env(std::string_view name) {
    if (const char* value = std::getenv(std::string{name}.c_str()); value && *value) return std::string{value};
    return std::nullopt;
}

std::filesystem::path ModulePath() {
#if defined(_WIN32)
    HMODULE module{};
    if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                            reinterpret_cast<LPCWSTR>(&ModulePath), &module)) return {};
    std::vector<wchar_t> buffer(512);
    for (;;) {
        const DWORD size = GetModuleFileNameW(module, buffer.data(), static_cast<DWORD>(buffer.size()));
        if (!size) return {};
        if (size < buffer.size() - 1) return std::filesystem::path{std::wstring_view{buffer.data(), size}};
        buffer.resize(buffer.size() * 2);
    }
#else
    Dl_info info{};
    if (!dladdr(reinterpret_cast<void*>(&ModulePath), &info) || !info.dli_fname) return {};
    return info.dli_fname;
#endif
}

std::filesystem::path ConfigPath() {
    if (auto value = Env("TCWA3_STATS_CONFIG_PATH")) return *value;
    if (auto value = Env("AASE_CONFIG_PATH")) return *value;
    const auto directory = ModulePath().parent_path();
    for (const auto& name : {"tcwa3_stats_tracker.toml", "arma_attendance.toml"}) {
        const auto candidate = directory / name;
        if (std::filesystem::exists(candidate)) return candidate;
    }
    return directory / "tcwa3_stats_tracker.toml";
}

template <typename T> void Assign(const toml::table& table, std::string_view section, std::string_view key, T& target) {
    if (auto value = table[section][key].value<T>()) target = *value;
}

void ApplyToml(Config& c, const std::filesystem::path& path, std::string& warning) {
    try {
        const auto table = toml::parse_file(path.string());
        Assign(table, "server", "server_key", c.server_key);
        Assign(table, "http", "base_url", c.base_url);
        Assign(table, "http", "api_token", c.api_token);
        Assign(table, "http", "verify_tls", c.verify_tls);
        Assign(table, "queue", "enabled", c.queue_enabled);
        std::string value;
        if (auto v = table["queue"]["queue_file"].value<std::string>()) c.queue_file = *v;
        if (auto v = table["queue"]["queue_sent_file"].value<std::string>()) c.queue_sent_file = *v;
        if (auto v = table["queue"]["sent_file"].value<std::string>()) c.queue_sent_file = *v;
        if (auto v = table["queue"]["dead_letter_file"].value<std::string>()) c.queue_dead_letter_file = *v;
        if (auto v = table["queue"]["results_file"].value<std::string>()) c.queue_results_file = *v;
        if (auto v = table["http"]["timeout_ms"].value<int64_t>()) c.timeout = std::chrono::milliseconds{std::clamp<int64_t>(*v, 1, 10000)};
        if (auto v = table["http"]["connect_timeout_ms"].value<int64_t>()) c.connect_timeout = std::chrono::milliseconds{std::clamp<int64_t>(*v, 1, 10000)};
        if (auto v = table["http"]["max_response_bytes"].value<int64_t>()) c.max_response_bytes = static_cast<size_t>(std::clamp<int64_t>(*v, 1024, 16 * 1024 * 1024));
        if (auto v = table["queue"]["max_attempts"].value<int64_t>()) c.queue_max_attempts = static_cast<int>(std::clamp<int64_t>(*v, 1, 1000));
        if (auto v = table["queue"]["flush_budget"].value<int64_t>()) c.queue_flush_budget = static_cast<int>(std::clamp<int64_t>(*v, 1, 25));
    } catch (const toml::parse_error&) {
        warning = "config_parse_failed: invalid TOML; values were not loaded";
    }
}

void ApplyEnv(Config& c, std::string& warning) {
    auto text = [&](const char* name, auto& target) { if (auto v = Env(name)) target = *v; };
    text("AASE_BASE_URL", c.base_url); text("AASE_API_TOKEN", c.api_token); text("AASE_SERVER_KEY", c.server_key);
    if (auto v = Env("AASE_QUEUE_FILE")) c.queue_file = *v;
    if (auto v = Env("AASE_QUEUE_SENT_FILE")) c.queue_sent_file = *v;
    if (auto v = Env("AASE_QUEUE_DEAD_LETTER_FILE")) c.queue_dead_letter_file = *v;
    if (auto v = Env("AASE_QUEUE_RESULTS_FILE")) c.queue_results_file = *v;
    auto integer = [&](const char* name, auto minimum, auto maximum, auto setter) {
        if (auto v = Env(name)) try { setter(std::clamp(std::stoll(*v), static_cast<long long>(minimum), static_cast<long long>(maximum))); }
        catch (...) { warning += std::string{warning.empty() ? "" : "; "} + name + " is invalid"; }
    };
    integer("AASE_TIMEOUT_MS", 1, 10000, [&](auto v){ c.timeout = std::chrono::milliseconds{v}; });
    integer("AASE_CONNECT_TIMEOUT_MS", 1, 10000, [&](auto v){ c.connect_timeout = std::chrono::milliseconds{v}; });
    integer("AASE_MAX_RESPONSE_BYTES", 1024, 16 * 1024 * 1024, [&](auto v){ c.max_response_bytes = static_cast<size_t>(v); });
    auto boolean = [&](const char* name, bool& target) { if (auto v = Env(name)) { if (*v == "true" || *v == "1") target = true; else if (*v == "false" || *v == "0") target = false; else warning += std::string{warning.empty() ? "" : "; "} + name + " is invalid"; }};
    boolean("AASE_VERIFY_TLS", c.verify_tls); boolean("AASE_QUEUE_ENABLED", c.queue_enabled);
}

void Resolve(Config& c) {
    auto base = ModulePath().parent_path();
    if (base.empty()) base = c.source_path.parent_path();
    auto resolve = [&](std::filesystem::path& path) { if (!path.empty() && path.is_relative()) path = base / path; };
    resolve(c.queue_file); resolve(c.queue_sent_file); resolve(c.queue_dead_letter_file); resolve(c.queue_results_file);
}
}

ConfigLoadResult LoadConfig() {
    Config config;
    std::string warning;
    const auto path = ConfigPath();
    if (std::filesystem::exists(path)) { ApplyToml(config, path, warning); config.source_path = path; }
    ApplyEnv(config, warning); Resolve(config);
    if (config.base_url.ends_with('/')) config.base_url.pop_back();
    std::lock_guard lock{g_config_mutex}; g_config = config;
    return {config, warning.empty() ? std::nullopt : std::optional<std::string>{warning}};
}
ConfigLoadResult ReloadConfig() { return LoadConfig(); }
Config CurrentConfig() {
    { std::lock_guard lock{g_config_mutex}; if (!g_config.base_url.empty() || !g_config.api_token.empty()) return g_config; }
    return LoadConfig().config;
}

std::string RedactedConfigJson(const Config& c) {
    std::ostringstream out;
    out << "{\"ok\":true,\"command\":\"config\",\"server_key\":" << JsonString(c.server_key)
        << ",\"base_url\":" << JsonString(c.base_url) << ",\"timeout_ms\":" << c.timeout.count()
        << ",\"connect_timeout_ms\":" << c.connect_timeout.count() << ",\"verify_tls\":" << (c.verify_tls ? "true" : "false")
        << ",\"queue_enabled\":" << (c.queue_enabled ? "true" : "false") << ",\"queue_file\":" << JsonString(c.queue_file.string())
        << ",\"queue_sent_file\":" << JsonString(c.queue_sent_file.string()) << ",\"queue_dead_letter_file\":" << JsonString(c.queue_dead_letter_file.string())
        << ",\"queue_results_file\":" << JsonString(c.queue_results_file.string()) << ",\"queue_max_attempts\":" << c.queue_max_attempts
        << ",\"api_token_present\":" << (!c.api_token.empty() ? "true" : "false");
    if (!c.source_path.empty()) out << ",\"source_path\":" << JsonString(c.source_path.string());
    return out.str() + "}";
}
} // namespace arma_attendance
