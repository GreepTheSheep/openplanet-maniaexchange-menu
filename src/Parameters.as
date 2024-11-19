#if MP4
string pluginName = "ManiaExchange";
string shortMXName = "MX";
string pluginColor = "\\$39f";
vec4 pluginColorVec = vec4(0.2, 0.6, 1, 1);
string gameName = "MP4";
string MXURL = "tm.mania.exchange";

#elif TMNEXT
string pluginName = "TrackmaniaExchange (Modern)";
string shortMXName = "ModernTMX";
string pluginColor = "\\$9fc";
vec4 pluginColorVec = vec4(0.3, 0.7, 0.4, 1);
string gameName = "TMNEXT";
string MXURL = "trackmania.exchange";

#endif

string nameMenu = pluginColor + Icons::Exchange + " \\$z"+ pluginName;
array<MX::MapInfo@> g_PlayLaterMaps;
string PlayLaterJSON = IO::FromStorageFolder("PlayLater.json");
string repoName = "GreepTheSheep/openplanet-maniaexchange-menu";
string repoURL = "https://github.com/"+repoName;
bool isDevMode = Meta::IsDeveloperMode();