#pragma once

#include "arma_attendance/config.hpp"

#include <string>
#include <string_view>

namespace arma_attendance {

struct HttpResponse {
    bool ok{false};
    long status{0};
    std::string body;
    std::string error;
};

HttpResponse HttpGet(std::string_view path, const Config& config);
HttpResponse HttpGetAuth(std::string_view path, const Config& config);
HttpResponse HttpPostJson(std::string_view path, std::string_view body, const Config& config);

} // namespace arma_attendance
