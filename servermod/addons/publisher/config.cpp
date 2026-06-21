class CfgPatches {
    class tcwa3_stats_tracker_server_publisher {
        name = "TCWA3 Stats Tracker Server Extension";
        author = "JTM-rootstorm";
        url = "https://github.com/JTM-rootstorm/arma-attendance-server-extension";
        requiredVersion = 2.18;
        requiredAddons[] = {};
        units[] = {};
        weapons[] = {};
    };
};

class CfgMods {
    class tcwa3_stats_tracker_server_extension {
        dir = "@tcwa3_stats_tracker_server";
        name = "TCWA3 Stats Tracker Server Extension";
        author = "JTM-rootstorm";
        tooltip = "TCWA3 Stats Tracker Server Extension";
        overview = "Publisher marker addon for the combined TCWA3 Stats Tracker addon and native extension package. Load this Workshop item with -mod on clients and dedicated servers.";
        actionName = "GitHub";
        action = "https://github.com/JTM-rootstorm/arma-attendance-server-extension";
    };
};
