#pragma once

#include <sstream>
#include <string>
#include <string_view>

namespace arma_attendance {

inline std::string JsonEscape(std::string_view value) {
    std::ostringstream escaped;
    for (const unsigned char ch : value) {
        switch (ch) {
        case '\\':
            escaped << "\\\\";
            break;
        case '"':
            escaped << "\\\"";
            break;
        case '\b':
            escaped << "\\b";
            break;
        case '\f':
            escaped << "\\f";
            break;
        case '\n':
            escaped << "\\n";
            break;
        case '\r':
            escaped << "\\r";
            break;
        case '\t':
            escaped << "\\t";
            break;
        default:
            if (ch < 0x20) {
                escaped << "\\u";
                constexpr char kHex[] = "0123456789abcdef";
                escaped << '0' << '0' << kHex[(ch >> 4U) & 0x0FU] << kHex[ch & 0x0FU];
            } else {
                escaped << static_cast<char>(ch);
            }
            break;
        }
    }
    return escaped.str();
}

inline std::string JsonString(std::string_view value) {
    return "\"" + JsonEscape(value) + "\"";
}

inline std::string JsonError(std::string_view command, std::string_view code, std::string_view message) {
    return "{\"ok\":false,\"command\":" + JsonString(command) +
           ",\"error\":{\"code\":" + JsonString(code) +
           ",\"message\":" + JsonString(message) + "}}";
}

} // namespace arma_attendance
