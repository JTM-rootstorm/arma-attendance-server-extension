#include "arma_attendance/commands.hpp"

#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <iterator>
#include <string>
#include <vector>

#if defined(_WIN32)
#include <cstdlib>
#endif

namespace {

bool Contains(const std::string& value, const std::string& needle) {
    return value.find(needle) != std::string::npos;
}

bool ExpectOk(const std::string& command, const std::string& result) {
    if (!Contains(result, "\"ok\":true")) {
        std::cerr << command << " failed: " << result << '\n';
        return false;
    }
    return true;
}

bool ExpectNoToken(const std::string& result) {
    if (Contains(result, "dev-token")) {
        std::cerr << "Token leaked in response: " << result << '\n';
        return false;
    }
    return true;
}

std::string ExtractJsonStringField(const std::string& body, const std::string& field) {
    const std::string needle = "\"" + field + "\"";
    const auto key = body.find(needle);
    if (key == std::string::npos) {
        return {};
    }

    const auto colon = body.find(':', key + needle.size());
    const auto quote = body.find('"', colon == std::string::npos ? key : colon + 1);
    if (quote == std::string::npos) {
        return {};
    }

    std::string value;
    for (auto index = quote + 1; index < body.size(); ++index) {
        if (body[index] == '"' && body[index - 1] != '\\') {
            return value;
        }
        value.push_back(body[index]);
    }
    return {};
}

void SetEnv(const char* name, const char* value) {
#if defined(_WIN32)
    _putenv_s(name, value);
#else
    setenv(name, value, 1);
#endif
}

} // namespace

int main(int argc, char** argv) {
    bool ok = true;
    const char* original_base_url = std::getenv("AASE_BASE_URL");
    const std::string base_url = original_base_url == nullptr ? "http://127.0.0.1:3000" : original_base_url;
    std::filesystem::path queue_path;
    std::filesystem::path sent_path;

    if (argc > 0 && argv[0] != nullptr) {
        const auto executable_path = std::filesystem::absolute(argv[0]);
        const auto config_path = executable_path.parent_path() / "arma_attendance.toml";
        queue_path = executable_path.parent_path() / "arma_attendance_queue_test.ndjson";
        sent_path = executable_path.parent_path() / "arma_attendance_queue_test.sent.ndjson";
        std::filesystem::remove(queue_path);
        std::filesystem::remove(sent_path);
        SetEnv("AASE_QUEUE_FILE", queue_path.string().c_str());
        SetEnv("AASE_QUEUE_SENT_FILE", sent_path.string().c_str());
        std::ofstream config{config_path};
        config << "[server]\n"
               << "server_key = \"smoke-file-server\"\n"
               << "\n"
               << "[http]\n"
               << "base_url = \"http://127.0.0.1:3000\"\n"
               << "api_token = \"dev-token\"\n"
               << "timeout_ms = 3000\n"
               << "verify_tls = false\n";
    }

    const auto version = arma_attendance::ExecuteCommand("version");
    ok = ExpectOk("version", version) && ok;

    const auto config = arma_attendance::ExecuteCommand("config");
    ok = ExpectOk("config", config) && ok;
    ok = Contains(config, "\"source_path\"") && ok;
    ok = ExpectNoToken(config) && ok;

    const auto health = arma_attendance::ExecuteCommand("health");
    ok = ExpectOk("health", health) && ok;

    const std::vector<std::string> args{"hello from arma"};
    const auto poke = arma_attendance::ExecuteCommand("poke", args);
    ok = ExpectOk("poke", poke) && ok;
    ok = Contains(poke, "received") && ok;
    ok = ExpectNoToken(poke) && ok;

    const std::vector<std::string> start_args{
        "{\"request_id\":\"ci:start:001\",\"payload_version\":1,\"mission\":{\"mission_uid\":\"ci-world:ci-mission:001\",\"mission_name\":\"CI Mission\",\"world_name\":\"VR\"},\"players\":[]}"};
    const auto operation_start = arma_attendance::ExecuteCommand("operation_start", start_args);
    ok = ExpectOk("operation_start", operation_start) && ok;
    const auto operation_id = ExtractJsonStringField(operation_start, "operation_id");
    if (operation_id.empty()) {
        std::cerr << "operation_start did not return operation_id: " << operation_start << '\n';
        ok = false;
    }
    ok = ExpectNoToken(operation_start) && ok;

    const auto operation_start_replay = arma_attendance::ExecuteCommand("operation_start", start_args);
    ok = ExpectOk("operation_start replay", operation_start_replay) && ok;
    ok = Contains(operation_start_replay, "\"idempotent\":true") && ok;

    const std::vector<std::string> finish_args{
        operation_id,
        R"json({"request_id":"ci:finish:001","payload_version":1,"players":[{"player_uid":"76561198000000000","name":"Smoke Alpha","stats":{"infantry_kills":0,"vehicle_kills":0,"player_kills":0,"ai_kills":0,"friendly_kills":0,"deaths":0}}],"attendance_records":[{"player_uid":"76561198000000000","name":"Smoke Alpha","present_at_start":true,"present_at_end":true,"joined_after_start":false,"operation_seconds":3600,"attended_seconds":3600,"missed_seconds":0,"attendance_ratio":1.0,"attendance_percent":100.0,"attendance_status":"full","attendance_credit":true,"disconnect_count":0,"reconnect_count":0}]})json"};
    const auto operation_finish = arma_attendance::ExecuteCommand("operation_finish", finish_args);
    ok = ExpectOk("operation_finish", operation_finish) && ok;
    ok = Contains(operation_finish, "\"status\":\"finished\"") && ok;
    ok = ExpectNoToken(operation_finish) && ok;

    const std::vector<std::string> ingest_args{"ci:start:001"};
    const auto ingest_get = arma_attendance::ExecuteCommand("ingest_request_get", ingest_args);
    ok = ExpectOk("ingest_request_get", ingest_get) && ok;

    const std::vector<std::string> operation_args{operation_id};
    const auto operation_get = arma_attendance::ExecuteCommand("operation_get", operation_args);
    ok = ExpectOk("operation_get", operation_get) && ok;

    const auto attendance_get = arma_attendance::ExecuteCommand("operation_attendance_get", operation_args);
    ok = ExpectOk("operation_attendance_get", attendance_get) && ok;

    const auto finish_missing_arg = arma_attendance::ExecuteCommand("operation_finish");
    if (!Contains(finish_missing_arg, "\"ok\":false") || !Contains(finish_missing_arg, "missing_argument")) {
        std::cerr << "operation_finish missing-arg check failed: " << finish_missing_arg << '\n';
        ok = false;
    }

    SetEnv("AASE_API_TOKEN", "bad-token");
    arma_attendance::ExecuteCommand("reload_config");
    const auto bad_auth = arma_attendance::ExecuteCommand("operation_get", operation_args);
    if (!Contains(bad_auth, "\"ok\":false") || !Contains(bad_auth, "\"http_status\":401")) {
        std::cerr << "operation_get bad-auth check failed: " << bad_auth << '\n';
        ok = false;
    }
    ok = ExpectNoToken(bad_auth) && ok;
    SetEnv("AASE_API_TOKEN", "dev-token");
    arma_attendance::ExecuteCommand("reload_config");

    SetEnv("AASE_BASE_URL", "http://127.0.0.1:9");
    arma_attendance::ExecuteCommand("reload_config");
    const std::vector<std::string> offline_args{
        "{\"request_id\":\"ci:start:offline\",\"payload_version\":1,\"players\":[]}"};
    const auto offline_start = arma_attendance::ExecuteCommand("operation_start", offline_args);
    if (!Contains(offline_start, "\"queued\":true")) {
        std::cerr << "operation_start offline queue check failed: " << offline_start << '\n';
        ok = false;
    }

    const auto queue_status = arma_attendance::ExecuteCommand("queue_status");
    ok = ExpectOk("queue_status", queue_status) && ok;
    ok = Contains(queue_status, "\"queued_count\":1") && ok;
    if (!queue_path.empty()) {
        std::ifstream queue_file{queue_path};
        std::string queue_contents{
            std::istreambuf_iterator<char>{queue_file},
            std::istreambuf_iterator<char>{}};
        ok = ExpectNoToken(queue_contents) && ok;
    }

    SetEnv("AASE_BASE_URL", base_url.c_str());
    arma_attendance::ExecuteCommand("reload_config");
    const auto queue_flush = arma_attendance::ExecuteCommand("queue_flush");
    ok = ExpectOk("queue_flush", queue_flush) && ok;
    ok = Contains(queue_flush, "\"remaining\":0") && ok;

    const auto queue_compact = arma_attendance::ExecuteCommand("queue_compact");
    ok = ExpectOk("queue_compact", queue_compact) && ok;

    return ok ? EXIT_SUCCESS : EXIT_FAILURE;
}
