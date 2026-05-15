#include "arma_attendance/commands.hpp"

#include <cstdlib>
#include <iostream>
#include <string>
#include <vector>

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

} // namespace

int main() {
    bool ok = true;

    const auto version = arma_attendance::ExecuteCommand("version");
    ok = ExpectOk("version", version) && ok;

    const auto config = arma_attendance::ExecuteCommand("config");
    ok = ExpectOk("config", config) && ok;
    ok = ExpectNoToken(config) && ok;

    const auto health = arma_attendance::ExecuteCommand("health");
    ok = ExpectOk("health", health) && ok;

    const std::vector<std::string> args{"hello from arma"};
    const auto poke = arma_attendance::ExecuteCommand("poke", args);
    ok = ExpectOk("poke", poke) && ok;
    ok = Contains(poke, "received") && ok;
    ok = ExpectNoToken(poke) && ok;

    return ok ? EXIT_SUCCESS : EXIT_FAILURE;
}
