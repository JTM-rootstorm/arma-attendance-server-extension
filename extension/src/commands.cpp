#include "arma_attendance/commands.hpp"
#include "arma_attendance/config.hpp"
#include "arma_attendance/http_client.hpp"
#include "arma_attendance/json.hpp"
#include "arma_attendance/queue_store.hpp"

#include <chrono>
#include <cctype>
#include <iomanip>
#include <nlohmann/json.hpp>
#include <sstream>
#include <vector>

namespace arma_attendance {
namespace {
using json = nlohmann::json;

std::string DecodeSqfStringLiteral(std::string_view value) {
    const auto first = value.find_first_not_of(" \t\r\n");
    const auto last = value.find_last_not_of(" \t\r\n");
    if (first == std::string_view::npos || value[first] != '"' || value[last] != '"') return std::string{value};
    std::string decoded;
    for (size_t i = first + 1; i < last; ++i) {
        if (value[i] == '"' && i + 1 < last && value[i + 1] == '"') { decoded.push_back('"'); ++i; }
        else decoded.push_back(value[i]);
    }
    return decoded;
}

std::string RequestId(std::string_view server, std::string_view kind) {
    const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::system_clock::now().time_since_epoch()).count();
    return std::string{server} + ":" + std::string{kind} + ":" + std::to_string(ms);
}
int64_t Now() { return std::chrono::system_clock::to_time_t(std::chrono::system_clock::now()); }

std::string UrlEncode(std::string_view value) {
    std::ostringstream out; out << std::uppercase << std::hex;
    for (unsigned char ch : value) if (std::isalnum(ch) || ch == '-' || ch == '_' || ch == '.' || ch == '~') out << ch;
    else out << '%' << std::setw(2) << std::setfill('0') << static_cast<int>(ch);
    return out.str();
}

std::optional<json> ParseObject(std::string_view body) {
    auto value = json::parse(body, nullptr, false);
    if (value.is_discarded() || !value.is_object()) return std::nullopt;
    return value;
}

std::string Invalid(std::string_view command, std::string message = "Expected a compact JSON object argument.") {
    return JsonError(command, "invalid_json", message);
}

std::optional<json> Normalize(std::string_view body, const Config& config, std::string_view kind) {
    auto parsed = ParseObject(body); if (!parsed) return std::nullopt;
    auto has_string = [&](std::string_view key) { auto it = parsed->find(key); return it == parsed->end() || it->is_string(); };
    auto version = parsed->find("payload_version");
    if (!has_string("request_id") || (version != parsed->end() && !version->is_number_integer()) ||
        (kind == "finish" && !has_string("outcome"))) return std::nullopt;
    (*parsed)["server_key"] = config.server_key;
    if (!parsed->contains("request_id")) (*parsed)["request_id"] = RequestId(config.server_key, kind);
    if (!parsed->contains("payload_version")) (*parsed)["payload_version"] = 1;
    if (kind == "finish" && !parsed->contains("outcome")) (*parsed)["outcome"] = "success";
    return parsed;
}

json Minimal(const Config& config, std::string_view kind, std::string_view operation_id = {}) {
    json body{{"request_id", RequestId(config.server_key, kind)}, {"server_key", config.server_key}, {"payload_version", 1},
              {"source", {{"kind", "arma3-extension"}, {"extension_version", kExtensionVersion}}},
              {"mission", {{"mission_uid", "native-smoke:" + std::string{kind}}, {"mission_name", "Native Smoke"}, {"world_name", "VR"}}}, {"players", json::array()}};
    if (!operation_id.empty()) body["operation_id"] = operation_id;
    if (kind == "finish") body["outcome"] = "success";
    return body;
}

std::string HttpError(const HttpResponse& response) {
    auto body = json::parse(response.body, nullptr, false);
    if (body.is_object()) {
        if (body.contains("code") && body["code"].is_string()) return body["code"];
        if (body.contains("error") && body["error"].is_string()) return body["error"];
        if (body.contains("error") && body["error"].is_object() && body["error"].value("code", "") != "") return body["error"]["code"];
    }
    return response.error.empty() ? "HTTP " + std::to_string(response.status) : response.error;
}
bool Terminal(const HttpResponse& r) { return !r.ok && r.status >= 400 && r.status < 500 && r.status != 408 && r.status != 429; }

std::string HttpJson(std::string_view command, const HttpResponse& response) {
    json result{{"ok", response.ok}, {"command", command}, {"http_status", response.status}};
    auto body = json::parse(response.body, nullptr, false);
    if (!body.is_discarded()) result["body"] = body; else result["body_raw"] = response.body;
    if (!response.error.empty()) result["error"] = {{"code", response.status ? "http_status_not_ok" : "http_request_failed"}, {"message", response.error}};
    if (response.ok && command == "operation_start" && body.is_object() && body.value("ok", false) && body.value("accepted", false) &&
        body.value("status", "") == "started" && body.contains("operation_id") && body["operation_id"].is_string() && !body["operation_id"].get<std::string>().empty())
        result["operation_id"] = body["operation_id"];
    return result.dump();
}

QueueStore Store(const Config& c) { return QueueStore{c.queue_file, c.queue_sent_file, c.queue_dead_letter_file, c.queue_results_file}; }
json Dead(const json& record, std::string kind, const HttpResponse& response) {
    json dead = record; dead["failure_kind"] = std::move(kind); dead["last_http_status"] = response.status;
    dead["last_error_code"] = HttpError(response); dead["last_error_message"] = response.error; dead["failed_at"] = Now(); return dead;
}

struct FlushResult { int attempted{}, sent{}, terminal{}, exhausted{}, dead{}; size_t remaining{}; bool persistence_error{}; std::string last_error; std::optional<HttpResponse> current; };

FlushResult Flush(const Config& config, std::string_view current = {}, bool force = false) {
    auto store = Store(config); auto loaded = store.load_pending(); FlushResult result;
    if (!loaded.ok) { result.persistence_error = true; result.last_error = loaded.error; return result; }
    std::vector<json> remaining; const auto now = Now();
    for (auto& record : loaded.records) {
        if (result.attempted >= config.queue_flush_budget || (!force && record.value("next_attempt_at", int64_t{0}) > now)) { remaining.push_back(record); continue; }
        ++result.attempted; record["attempts"] = record.value("attempts", 0) + 1; record["last_attempt_at"] = now;
        const auto response = HttpPostJson(record.value("path", ""), record.value("body", json::object()).dump(), config);
        if (record.value("queue_id", "") == current) result.current = response;
        if (response.ok) {
            if (!store.append_sent(record).ok) { remaining.push_back(record); result.persistence_error = true; continue; }
            ++result.sent;
            auto body = json::parse(response.body, nullptr, false);
            json journal{{"queue_id", record.value("queue_id", "")}, {"request_id", record.value("request_id", "")},
                         {"command", record.value("command", "")}, {"http_status", response.status}, {"completed_at", now}, {"response", body.is_discarded() ? json::object() : body}};
            if (!store.append_result(journal).ok) result.persistence_error = true;
        } else if (Terminal(response)) {
            auto dead = Dead(record, "terminal_http", response);
            if (store.append_dead_letter(dead).ok) { ++result.terminal; ++result.dead; } else { remaining.push_back(record); result.persistence_error = true; }
            result.last_error = HttpError(response);
        } else if (record.value("attempts", 0) >= config.queue_max_attempts) {
            auto dead = Dead(record, "retry_exhausted", response);
            if (store.append_dead_letter(dead).ok) { ++result.exhausted; ++result.dead; } else { remaining.push_back(record); result.persistence_error = true; }
            result.last_error = HttpError(response);
        } else {
            static constexpr int delays[]{5, 15, 30, 60, 300, 900, 1800};
            const auto attempt = std::min(record.value("attempts", 1) - 1, 6); record["next_attempt_at"] = now + delays[attempt]; remaining.push_back(record);
            result.last_error = HttpError(response);
        }
    }
    if (auto replaced = store.replace_pending(remaining); !replaced.ok) { result.persistence_error = true; result.last_error = replaced.error; }
    result.remaining = remaining.size(); return result;
}

json FlushJson(std::string_view command, const FlushResult& f) {
    json out{{"ok", !f.persistence_error && !f.terminal && !f.exhausted && f.remaining == 0}, {"command", command}, {"attempted", f.attempted},
             {"sent", f.sent}, {"terminal_failed", f.terminal}, {"exhausted", f.exhausted}, {"dead_lettered", f.dead}, {"remaining", f.remaining}};
    if (!f.last_error.empty()) out["last_error"] = f.last_error; return out;
}

std::string SendQueued(std::string_view command, std::string path, const json& body, const Config& config) {
    if (!config.queue_enabled) return HttpJson(command, HttpPostJson(path, body.dump(), config));
    const auto request = body.value("request_id", RequestId("queue", command));
    json record{{"queue_id", request}, {"request_id", request}, {"command", command}, {"method", "POST"}, {"path", path}, {"body", body},
                {"attempts", 0}, {"last_attempt_at", 0}, {"next_attempt_at", 0}};
    auto store = Store(config); auto saved = store.append_pending(record);
    if (!saved.ok) return JsonError(command, "queue_persist_failed", saved.error);
    auto flushed = Flush(config, request);
    if (flushed.current && flushed.current->ok) return HttpJson(command, *flushed.current);
    if (flushed.current && Terminal(*flushed.current)) { auto out = json::parse(HttpJson(command, *flushed.current)); out["queued"] = false; out["terminal"] = true; return out.dump(); }
    auto out = FlushJson(command, flushed); out["ok"] = false; out["queued"] = true; out["queue_id"] = request; return out.dump();
}
}

std::string ExecuteCommand(std::string_view command, std::span<const std::string> args) {
    try {
        if (command == "version") return json{{"ok", true}, {"command", command}, {"version", kExtensionVersion}}.dump();
        if (command == "reload_config") { auto loaded = ReloadConfig(); json out{{"ok", true}, {"command", command}, {"config", json::parse(RedactedConfigJson(loaded.config))}}; if (loaded.warning) out["warning"] = *loaded.warning; return out.dump(); }
        const auto config = CurrentConfig();
        if (command == "config") return RedactedConfigJson(config);
        if (command == "health") return config.base_url.empty() ? JsonError(command, "missing_config", "AASE_BASE_URL is not configured.") : HttpJson(command, HttpGet("/health", config));
        if (command == "poke") { if (config.base_url.empty() || config.api_token.empty()) return JsonError(command, "missing_config", "HTTP configuration is incomplete."); return HttpJson(command, HttpPostJson("/v1/debug/poke", json{{"message", args.empty() ? "hello from arma" : args.front()}, {"server_key", config.server_key}}.dump(), config)); }
        if (command == "operation_start") {
            auto body = args.empty() ? std::optional<json>{Minimal(config, "start")} : Normalize(args.front(), config, "start");
            if (!body) return Invalid(command); return SendQueued(command, "/v1/operations/start", *body, config);
        }
        if (command == "operation_finish") {
            if (args.empty()) return JsonError(command, "missing_argument", "operation_id is required.");
            std::string operation_id; std::optional<json> body;
            if (args.size() == 1 && ParseObject(args.front())) { body = Normalize(args.front(), config, "finish"); if (body && (*body).contains("operation_id") && (*body)["operation_id"].is_string()) operation_id = (*body)["operation_id"]; }
            else { operation_id = args.front(); body = args.size() > 1 ? Normalize(args[1], config, "finish") : std::optional<json>{Minimal(config, "finish", operation_id)}; }
            if (operation_id.empty()) return JsonError(command, "missing_argument", "operation_id is required."); if (!body) return Invalid(command);
            return SendQueued(command, "/v1/operations/" + UrlEncode(operation_id) + "/finish", *body, config);
        }
        auto store = Store(config);
        if (command == "queue_status" || command == "queue_dead_status") return json{{"ok", true}, {"command", command}, {"queued_count", store.count_pending()}, {"sent_count", store.count_sent()}, {"dead_letter_count", store.count_dead_letter()}, {"queue_file", config.queue_file.string()}, {"sent_file", config.queue_sent_file.string()}, {"dead_letter_file", config.queue_dead_letter_file.string()}}.dump();
        if (command == "queue_flush") return FlushJson(command, Flush(config, {}, true)).dump();
        if (command == "queue_compact") { auto loaded = store.load_pending(); if (!loaded.ok) return JsonError(command, "queue_parse_failed", loaded.error); auto saved = store.replace_pending(loaded.records); return saved.ok ? json{{"ok", true}, {"command", command}, {"queued_count", loaded.records.size()}}.dump() : JsonError(command, "queue_persist_failed", saved.error); }
        if (command == "queue_dead_compact") return json{{"ok", true}, {"command", command}, {"dead_letter_count", store.count_dead_letter()}}.dump();
        if (command == "queue_result_get" || command == "queue_result_consume") {
            if (args.empty()) return JsonError(command, "missing_argument", "request_id is required."); auto loaded = store.load_results(); if (!loaded.ok) return JsonError(command, "queue_parse_failed", loaded.error);
            std::vector<json> keep; std::optional<json> found; for (auto& record : loaded.records) if (!found && record.value("request_id", "") == args.front()) found = record; else keep.push_back(record);
            if (command == "queue_result_consume" && found) { auto saved = store.replace_results(keep); if (!saved.ok) return JsonError(command, "queue_persist_failed", saved.error); }
            return json{{"ok", found.has_value()}, {"command", command}, {"found", found.has_value()}, {"result", found.value_or(json::object())}}.dump();
        }
        auto get = [&](std::string path) { return HttpJson(command, HttpGetAuth(path, config)); };
        if (command == "ingest_request_get" && !args.empty()) return get("/v1/ingest-requests/" + UrlEncode(args.front()));
        if (command == "operation_get" && !args.empty()) return get("/v1/operations/" + UrlEncode(args.front()));
        if (command == "operation_attendance_get" && !args.empty()) return get("/v1/operations/" + UrlEncode(args.front()) + "/attendance");
        if (command == "operation_payloads_get" && !args.empty()) return get("/v1/operations/" + UrlEncode(args.front()) + "/payloads");
        if (command == "operation_list") return get("/v1/operations?server_key=" + UrlEncode(config.server_key) + (args.empty() ? "" : "&limit=" + UrlEncode(args.front())));
        return JsonError(command, "unknown_command", "Unknown command.");
    } catch (const std::exception& error) { return JsonError(command, "internal_error", error.what()); }
}

std::string ExecuteCommand(std::string_view command, int argc, const char* const* argv) {
    std::vector<std::string> args; args.reserve(std::max(argc, 0));
    for (int i = 0; i < argc; ++i) args.push_back(argv && argv[i] ? DecodeSqfStringLiteral(argv[i]) : "");
    return ExecuteCommand(command, args);
}
} // namespace arma_attendance
