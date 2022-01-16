#if MP4
string pluginName = "ManiaExchange";
string shortMXName = "MX";
string pluginColor = "\\$39f";
vec4 pluginColorVec = vec4(0.2, 0.6, 1, 1);
string gameName = "MP4";
string MXURL = "tm.mania.exchange";

array<string> supportedMapTypes = {
    "Race",
    "MeleeArena",
    "ObstacleTitleArena",
    "SiegeV2Arena",
    "SpeedBallArena",
    "RoyalArena",
    "EliteArena",
    "JoustArena",
    "CTFModeArena",
    "CTFAgeArena",
    "BattleArena"
};

#elif TMNEXT
string pluginName = "TrackmaniaExchange";
string shortMXName = "TMX";
string pluginColor = "\\$9fc";
vec4 pluginColorVec = vec4(0.3, 0.7, 0.4, 1);
string gameName = "TMNEXT";
string MXURL = "trackmania.exchange";

array<string> supportedMapTypes = {
    "TM_Race"
};

#endif

string nameMenu = pluginColor + Icons::Exchange + " \\$z"+ pluginName;
array<MX::MapInfo@> g_PlayLaterMaps;
string PlayLaterJSON = IO::FromDataFolder("ManiaExchange_PlayLater.json");
string repoURL = "https://github.com/GreepTheSheep/openplanet-maniaexchange-menu";