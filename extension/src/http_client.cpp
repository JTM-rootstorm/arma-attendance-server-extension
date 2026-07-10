#include "arma_attendance/http_client.hpp"

#include <curl/curl.h>

#include <mutex>
#include <sstream>
#include <string>
#include <string_view>

namespace arma_attendance {
namespace {

std::once_flag g_curl_init_once;

struct ResponseBuffer {
    std::string body;
    size_t maximum{};
    bool overflow{false};
};

size_t WriteBody(char* data, size_t size, size_t nmemb, void* userdata) {
    auto* response = static_cast<ResponseBuffer*>(userdata);
    const auto bytes = size * nmemb;
    if (bytes > response->maximum - std::min(response->maximum, response->body.size())) {
        response->overflow = true;
        return 0;
    }
    response->body.append(data, bytes);
    return bytes;
}

HttpResponse Perform(std::string_view method, std::string_view path, std::string_view body, const Config& config) {
    std::call_once(g_curl_init_once, [] { curl_global_init(CURL_GLOBAL_DEFAULT); });

    if (config.base_url.empty()) {
        return HttpResponse{false, 0, {}, "AASE_BASE_URL is not configured."};
    }

    CURL* curl = curl_easy_init();
    if (curl == nullptr) {
        return HttpResponse{false, 0, {}, "Failed to initialize libcurl."};
    }

    ResponseBuffer response{{}, config.max_response_bytes, false};
    std::string url = config.base_url;
    if (!path.empty() && path.front() != '/') {
        url += '/';
    }
    url += path;

    struct curl_slist* headers = nullptr;
    if (method == "POST" || method == "GET_AUTH") {
        if (config.api_token.empty()) {
            curl_easy_cleanup(curl);
            return HttpResponse{false, 0, {}, "AASE_API_TOKEN is not configured."};
        }
        const std::string auth = "Authorization: Bearer " + config.api_token;
        headers = curl_slist_append(headers, auth.c_str());
    }

    if (method == "POST") {
        headers = curl_slist_append(headers, "Content-Type: application/json");
        curl_easy_setopt(curl, CURLOPT_POST, 1L);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body.data());
        curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, static_cast<long>(body.size()));
    }

    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteBody);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT_MS, static_cast<long>(config.timeout.count()));
    curl_easy_setopt(curl, CURLOPT_CONNECTTIMEOUT_MS, static_cast<long>(config.connect_timeout.count()));
    curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
    curl_easy_setopt(curl, CURLOPT_USERAGENT, "TCWA3-Stats-Tracker/0.1.0");
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 0L);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, config.verify_tls ? 1L : 0L);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, config.verify_tls ? 2L : 0L);
    if (headers != nullptr) {
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    }

    const CURLcode code = curl_easy_perform(curl);
    long status = 0;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &status);

    std::string error;
    if (response.overflow) {
        error = "HTTP response exceeded configured maximum size.";
    } else if (code != CURLE_OK) {
        error = curl_easy_strerror(code);
    }

    if (headers != nullptr) {
        curl_slist_free_all(headers);
    }
    curl_easy_cleanup(curl);

    return HttpResponse{code == CURLE_OK && !response.overflow && status >= 200 && status < 300, status, response.body, error};
}

} // namespace

HttpResponse HttpGet(std::string_view path, const Config& config) {
    return Perform("GET", path, {}, config);
}

HttpResponse HttpGetAuth(std::string_view path, const Config& config) {
    return Perform("GET_AUTH", path, {}, config);
}

HttpResponse HttpPostJson(std::string_view path, std::string_view body, const Config& config) {
    return Perform("POST", path, body, config);
}

} // namespace arma_attendance
