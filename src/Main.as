string inputMapID = "";
int currentMapID = -4;
MX::MapInfo@ currentMapInfo;
Window@ mxMenu;

void RenderMenu()
{
    if(UI::MenuItem(nameMenu + (MX::APIDown ? " \\$f00"+Icons::Server : "")+ (MX::APIRefresh ? " \\$666"+Icons::Refresh : "") + (MXNadeoServicesGlobal::APIRefresh ? " \\$850"+Icons::Refresh : "") + "###" + pluginName + "Menu", "", Setting_ShowMenu)) {
        if (MX::APIDown) {
            Renderables::Add(APIDownWarning());
        } else {
            Setting_ShowMenu = !Setting_ShowMenu;
        }
    }
}

void RenderMenuMain(){
    if(UI::BeginMenu(nameMenu + (MX::APIDown ? " \\$f00"+Icons::Server : "") + (MX::APIRefresh ? " \\$666"+Icons::Refresh : "") + (MXNadeoServicesGlobal::APIRefresh ? " \\$850"+Icons::Refresh : "") + "###" + pluginName + "Menu")) {
        if (!MX::APIDown) {
            if (MX::APIRefresh) {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Please wait...");
            } else {
                if(UI::MenuItem(pluginColor + Icons::WindowMaximize+"\\$z Open "+shortMXName+" menu", "", Setting_ShowMenu)) {
                    Setting_ShowMenu = !Setting_ShowMenu;
                }
                if(UI::BeginMenu(pluginColor + Icons::ICursor+"\\$z Enter map ID")) {
                    bool pressedEnter = false;
                    inputMapID = UI::InputText("##InputMapId", inputMapID, pressedEnter, UI::InputTextFlags::EnterReturnsTrue | UI::InputTextFlags::CharsDecimal);
                    if (!Regex::Contains(inputMapID, "^[0-9]*$")) {
                        inputMapID = "";
                        UI::TextDisabled("\\$f00" + Icons::Times +" \\$zOnly numbers are allowed");
                    }
                    if (inputMapID != ""){
#if TMNEXT
                        if (Permissions::PlayLocalMap() && (pressedEnter || UI::MenuItem(Icons::Play + " Play map"))){
#else
                        if (pressedEnter || UI::MenuItem(Icons::Play + " Play map")){
#endif
                            if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                            UI::ShowNotification("Loading map...");
                            MX::mapToLoad = Text::ParseInt(inputMapID);
                        }
                        if (UI::MenuItem(Icons::Kenney::InfoCircle + " Open information")){
                            if (!Setting_ShowMenu) Setting_ShowMenu = true;
                            mxMenu.AddTab(MapTab(Text::ParseInt(inputMapID)), true);
                        }
                    }
                    UI::EndMenu();
                }

                if (currentMapID > 0){
                    UI::Separator();
                    if (UI::MenuItem(Icons::Kenney::InfoCircle + " " + Text::OpenplanetFormatCodes(currentMapInfo.GbxMapName))){
                        if (!Setting_ShowMenu) Setting_ShowMenu = true;
                        mxMenu.AddTab(MapTab(currentMapID), true);
                    }
                }

                if (currentMapID == -1){
                    UI::Separator();
                    UI::TextDisabled(Icons::Times + " Current map not found on " + shortMXName);
                }

                if (currentMapID == -2){
                    UI::Separator();
                    UI::TextDisabled("Error while checking the current map on " + shortMXName);
                }

                if (currentMapID == -3){
                    UI::Separator();
                    int HourGlassValue = Time::Stamp % 3;
                    string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                    UI::TextDisabled(Hourglass + " Loading...");
                }

                if (isDevMode && currentMapID == -4){
                    UI::Separator();
                    UI::TextDisabled("Not in a map.");
                }

                if (isDevMode && currentMapID == -5){
                    UI::Separator();
                    UI::TextDisabled("In map editor.");
                }
            }
        } else {
            UI::TextDisabled("\\$f00" + Icons::Server + " \\$z" + shortMXName + " is down!");
            UI::TextDisabled("Consider to check your internet connection.");
            if (!MX::APIRefresh && UI::Button(Icons::Refresh + " Refresh")) {
                startnew(MX::CheckForAPILoaded);
            }
            if (MX::APIRefresh) {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Refreshing...");
            }
        }
        UI::Separator();
        if (UI::BeginMenu(Icons::ClockO + " Play later" + (g_PlayLaterMaps.Length > 0 ? " (" + g_PlayLaterMaps.Length + ")" : ""))) {
            if (g_PlayLaterMaps.Length > 0) {
                for (uint i = 0; i < g_PlayLaterMaps.Length; i++) {
                    MX::MapInfo@ map = g_PlayLaterMaps[i];
                    if (UI::BeginMenu((Setting_ColoredMapName ? Text::OpenplanetFormatCodes(map.GbxMapName) : map.Name) + " \\$z\\$sby " + map.Username)) {
#if TMNEXT
                        if (Permissions::PlayLocalMap() && UI::MenuItem(Icons::Play + " Play map")){
#else
                        if (UI::MenuItem(Icons::Play + " Play map")){
#endif
                            if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                            UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(map.GbxMapName) + "\\$z\\$s by " + map.Username);
                            MX::mapToLoad = map.TrackID;
                        }
                        if (!MX::APIDown && UI::MenuItem(Icons::Kenney::InfoCircle + " Open information")){
                            if (!Setting_ShowMenu) Setting_ShowMenu = true;
                            mxMenu.AddTab(MapTab(map.TrackID), true);
                        }
                        if (UI::MenuItem("\\$f00"+Icons::TrashO + " Remove map")){
                            g_PlayLaterMaps.RemoveAt(i);
                            SavePlayLater(g_PlayLaterMaps);
                            UI::ShowNotification(Text::OpenplanetFormatCodes(map.GbxMapName) + "\\$z\\$s by " + map.Username + " has been removed!");
                        }
                        UI::EndMenu();
                    }
                }
            } else {
                UI::TextDisabled("The list is empty!");
                UI::Separator();
                UI::TextDisabled("To add a map here,");
                UI::TextDisabled("select a map in the menu");
                UI::TextDisabled("and click on 'Add to Play later'");
            }
            UI::EndMenu();
        }
        if (g_PlayLaterMaps.Length > 0 && UI::MenuItem("\\$f00"+Icons::TrashO + " Clear list")){
            Renderables::Add(ClarPlayLaterListWarn());
        }
        UI::Separator();
#if DEPENDENCY_NADEOSERVICES
        // TODO: Add in-game favorites list from NadeoServices
        if (UI::BeginMenu(pluginColor+Icons::Heart + " \\$zFavorites"+(MXNadeoServicesGlobal::g_totalFavoriteMaps > 0 ? (" ("+MXNadeoServicesGlobal::g_totalFavoriteMaps+")") : ""))) {
            if (MXNadeoServicesGlobal::g_favoriteMaps.Length > 0) {
                for (uint i = 0; i < MXNadeoServicesGlobal::g_favoriteMaps.Length; i++) {
                    NadeoServices::MapInfo@ mapNadeo = MXNadeoServicesGlobal::g_favoriteMaps[i];

                    if (mapNadeo.MXMapInfo !is null) {
                        MX::MapInfo@ map = mapNadeo.MXMapInfo;
                        if (UI::BeginMenu((Setting_ColoredMapName ? Text::OpenplanetFormatCodes(map.GbxMapName) : map.Name) + " \\$z\\$sby " + map.Username)) {
#if TMNEXT
                            if (Permissions::PlayLocalMap() && UI::MenuItem(Icons::Play + " Play map")){
#else
                            if (UI::MenuItem(Icons::Play + " Play map")){
#endif
                                if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                                UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(map.GbxMapName) + " \\$zby " + map.Username);
                                MX::mapToLoad = map.TrackID;
                            }
                            if (!MX::APIDown && UI::MenuItem(Icons::Kenney::InfoCircle + " Open information")){
                                if (!Setting_ShowMenu) Setting_ShowMenu = true;
                                mxMenu.AddTab(MapTab(map.TrackID), true);
                            }
                            if (UI::MenuItem("\\$f00"+Icons::TrashO + " Remove map")){
                                MXNadeoServicesGlobal::m_mapUidToAction = mapNadeo.uid;
                                startnew(MXNadeoServicesGlobal::RemoveMapFromFavoritesAsync);
                                UI::ShowNotification(Text::OpenplanetFormatCodes(mapNadeo.name) + " \\$zby " + map.Username + " has been removed from favorites!");
                            }
                            UI::EndMenu();
                        }
                    } else {
                        if (UI::BeginMenu((Setting_ColoredMapName ? Text::OpenplanetFormatCodes(mapNadeo.name) : Text::StripFormatCodes(mapNadeo.name)) + "\\$z" + (mapNadeo.authorUsername.Length > 0 ? (" by " + mapNadeo.authorUsername) : ""))) {
                            UI::TextDisabled(Icons::Times + " This map is not available on " + pluginName);
                            if (UI::MenuItem("\\$f00"+Icons::TrashO + " Remove map")){
                                MXNadeoServicesGlobal::m_mapUidToAction = mapNadeo.uid;
                                startnew(MXNadeoServicesGlobal::RemoveMapFromFavoritesAsync);
                                UI::ShowNotification(Text::OpenplanetFormatCodes(mapNadeo.name) + "\\$z" + (mapNadeo.authorUsername.Length > 0 ? (" by " + mapNadeo.authorUsername) : "") + " has been removed from favorites!");
                            }
                            UI::EndMenu();
                        }
                    }
                }
            } else {
                UI::TextDisabled("The list is empty!");
                UI::Separator();
                UI::TextDisabled("To add a map here,");
                UI::TextDisabled("select a map in the menu");
                UI::TextDisabled("and click on 'Add to Favorites'");
            }
            UI::EndMenu();
        }
        UI::Separator();
#endif
        if (UI::BeginMenu(pluginColor+Icons::InfoCircle + " \\$zAbout")){
            if (UI::BeginMenu("\\$f00"+Icons::Heart + " \\$zSupport")){
                if (UI::MenuItem(pluginColor+Icons::Heart + " \\$zSupport ManiaExchange")) OpenBrowserURL("https://"+MXURL+"/support");
                if (UI::MenuItem(Icons::Heartbeat + " \\$zSupport the plugin creator")) OpenBrowserURL("https://github.com/sponsors/GreepTheSheep");
                UI::EndMenu();
            }
            UI::Separator();
            if (UI::BeginMenu(pluginColor+Icons::KeyboardO + " \\$zContact")){
                if (UI::MenuItem(pluginColor+Icons::KeyboardO + " \\$zContact ManiaExchange")) OpenBrowserURL("https://"+MXURL+"/messaging/compose/11");
                if (UI::MenuItem(Icons::DiscordAlt + "Plugin creator's Discord")) OpenBrowserURL("https://greep.gq/discord");
                UI::EndMenu();
            }
            UI::Separator();
            if (UI::MenuItem(pluginColor+Icons::Facebook + " \\$zManiaExchange on Facebook")) OpenBrowserURL("https://facebook.com/maniaexchange/");
            if (UI::MenuItem(pluginColor+Icons::Twitter + " \\$zManiaExchange on Twitter")) OpenBrowserURL("https://twitter.com/maniaexchange/");
            if (UI::MenuItem(pluginColor+Icons::YoutubePlay + " \\$zManiaExchange on YouTube")) OpenBrowserURL("https://youtube.com/maniaexchangetracks/");
            if (UI::MenuItem(pluginColor+Icons::DiscordAlt + " \\$zManiaExchange on Discord")) OpenBrowserURL("https://discord.mania.exchange/");
            UI::EndMenu();
         }
        if (UI::BeginMenu("\\$f90"+Icons::CircleThin + " \\$zAdvanced")){
            UI::TextDisabled("Actual Repository URL: ");
            UI::TextDisabled(MXURL);
            if (UI::MenuItem(pluginColor+Icons::ExternalLink + " \\$zOpen "+pluginName+" in browser")) OpenBrowserURL("https://"+MXURL);
            UI::Separator();
            if (!MX::APIRefresh && UI::MenuItem(Icons::Refresh + " Refresh Tags and Seasons")) startnew(MX::CheckForAPILoaded);
#if DEPENDENCY_NADEOSERVICES
            if (!MXNadeoServicesGlobal::APIRefresh && UI::MenuItem("\\$850"+Icons::Refresh + " \\$zRefresh favorite maps list")) startnew(MXNadeoServicesGlobal::ReloadFavoriteMapsAsync);
#endif
            UI::EndMenu();
        }
        UI::EndMenu();
    }
}

void Main(){
    @mxMenu = Window();
#if MP4
    if (repo == MP4mxRepos::Trackmania) MXURL = "tm.mania.exchange";
    else if (repo == MP4mxRepos::Shootmania) MXURL = "sm.mania.exchange";
#endif
    startnew(MX::CheckForAPILoaded);
    g_PlayLaterMaps = LoadPlayLater();

#if DEPENDENCY_NADEOSERVICES
    startnew(MXNadeoServicesGlobal::LoadNadeoLiveServices);
#endif

#if DEPENDENCY_BETTERCHAT
    startnew(BetterChatRegisterCommands);
#endif

    startnew(MapLoader);
    startnew(MapChecker);
}

void MapLoader() {
    while(true){
        yield();

        // Looks for the map to load or DL
        if (MX::mapToLoad != -1){
            MX::LoadMap(MX::mapToLoad);
            MX::mapToLoad = -1;
        }
        if (MX::mapToEdit != -1){
            MX::LoadMap(MX::mapToEdit, true);
            MX::mapToEdit = -1;
        }
        if (MX::mapToDL != -1){
            MX::DownloadMap(MX::mapToDL);
            MX::mapToDL = -1;
        }
    }
}

void MapChecker() {
    while(true){
        yield();

        // Checks current played map
        auto currentMap = GetCurrentMap();
        if (!IsInEditor()){
            if (currentMap !is null){
                if (!MX::APIDown && currentMapID < 0 && currentMapID != -1) {
                    currentMapID = MX::GetCurrentMapMXID();
                    if (currentMapID < 0 && currentMapID != -3) {
                        if (isDevMode) print("MX ID error: " + currentMapID);
                        sleep(30000);
                    }
                }
            } else {
                currentMapID = -4;
            }
        } else {
            currentMapID = -5;
        }
    }
}

#if DEPENDENCY_BETTERCHAT
void BetterChatRegisterCommands() {
    try {
        BetterChat::RegisterCommand("mx", MXBetterChat::OpenMapOnMXCmd());
        BetterChat::RegisterCommand("maniaexchange", MXBetterChat::OpenMapOnMXCmd());
        BetterChat::RegisterCommand("mx-page", MXBetterChat::MXPage(false));
        BetterChat::RegisterCommand("mx-tell-page", MXBetterChat::MXPage(true));
        BetterChat::RegisterCommand("mx-awards", MXBetterChat::MapAwards(false));
        BetterChat::RegisterCommand("mx-tell-awards", MXBetterChat::MapAwards(true));
        BetterChat::RegisterCommand("mx-tell-plugin", MXBetterChat::TellMXPlugin());

        if (isDevMode) BetterChat::RegisterCommand("mx-json", MXBetterChat::ShowMapInfoJson());
    } catch {
        mxError("Better Chat: unable to register commands: " + getExceptionInfo(), true);
    }
}
#endif

void RenderInterface(){
    mxMenu.Render();
}

void Render(){
    Renderables::Render();
}

void OnDestroyed() {
#if DEPENDENCY_BETTERCHAT
    BetterChat::UnregisterCommand("mx");
    BetterChat::UnregisterCommand("maniaexchange");
    if (isDevMode) BetterChat::UnregisterCommand("mx-json");
    BetterChat::UnregisterCommand("mx-awards");
    BetterChat::UnregisterCommand("mx-tell-awards");
    BetterChat::UnregisterCommand("mx-page");
    BetterChat::UnregisterCommand("mx-tell-page");
    BetterChat::UnregisterCommand("mx-tell-plugin");
#endif
}