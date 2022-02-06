string inputMapID = "";
int currentMapID = -4;

void RenderMenu()
{
    if(UI::MenuItem(nameMenu + (MX::APIDown ? " \\$f00"+Icons::Server : ""), "", mxMenu.isOpened)) {
        if (MX::APIDown) {
            Dialogs::Message("\\$f00"+Icons::Times+" \\$zSorry, "+pluginName+" is not responding.\nReload the plugin to try again.");
        } else {
            mxMenu.isOpened = !mxMenu.isOpened;
        }
    }
}

void RenderMenuMain(){
    if(UI::BeginMenu(nameMenu + (MX::APIDown ? " \\$f00"+Icons::Server : ""))) {
        if (!MX::APIDown) {
            if(UI::MenuItem(pluginColor + Icons::WindowMaximize+"\\$z Open "+shortMXName+" menu", "", mxMenu.isOpened)) {
                mxMenu.isOpened = !mxMenu.isOpened;
            }
            if(UI::BeginMenu(pluginColor + Icons::ICursor+"\\$z Enter map ID")) {
                bool pressedEnter = false;
                inputMapID = UI::InputText("", inputMapID, pressedEnter, UI::InputTextFlags::EnterReturnsTrue | UI::InputTextFlags::CharsDecimal);
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
                        if (!mxMenu.isOpened) mxMenu.isOpened = true;
                        mxMenu.AddTab(MapTab(Text::ParseInt(inputMapID)), true);
                    }
                }
                UI::EndMenu();
            }

            if (currentMapID > 0){
                UI::Separator();
                if (UI::MenuItem(Icons::Kenney::InfoCircle + " Current map information")){
                    if (!mxMenu.isOpened) mxMenu.isOpened = true;
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

            if (IsDevMode() && currentMapID == -4){
                UI::Separator();
                UI::TextDisabled("Not in a map.");
            }

            if (IsDevMode() && currentMapID == -5){
                UI::Separator();
                UI::TextDisabled("In map editor.");
            }
        } else {
            UI::TextDisabled("\\$f00" + Icons::Server + " \\$z" + shortMXName + " is down!");
            UI::TextDisabled("Consider to check your internet connection.");
            UI::TextDisabled("Reload the plugin to try again.");
        }
        UI::Separator();
        if (UI::BeginMenu(Icons::ClockO + " Play later" + (g_PlayLaterMaps.get_Length() > 0 ? " (" + g_PlayLaterMaps.get_Length() + ")" : ""))) {
            if (g_PlayLaterMaps.get_Length() > 0) {
                for (uint i = 0; i < g_PlayLaterMaps.get_Length(); i++) {
                    MX::MapInfo@ map = g_PlayLaterMaps[i];
                    if (UI::BeginMenu((Setting_ColoredMapName ? ColoredString(map.GbxMapName) : map.Name) + " \\$z\\$sby " + map.Username)) {
#if TMNEXT
                        if (Permissions::PlayLocalMap() && UI::MenuItem(Icons::Play + " Play map")){
#else
                        if (UI::MenuItem(Icons::Play + " Play map")){
#endif
                            if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                            UI::ShowNotification("Loading map...", ColoredString(map.GbxMapName) + "\\$z\\$s by " + map.Username);
                            MX::mapToLoad = map.TrackID;
                        }
                        if (!MX::APIDown && UI::MenuItem(Icons::Kenney::InfoCircle + " Open information")){
                            if (!mxMenu.isOpened) mxMenu.isOpened = true;
                            mxMenu.AddTab(MapTab(map.TrackID), true);
                        }
                        if (UI::MenuItem("\\$f00"+Icons::TrashO + " Remove map")){
                            g_PlayLaterMaps.RemoveAt(i);
                            SavePlayLater(g_PlayLaterMaps);
                            UI::ShowNotification(ColoredString(map.GbxMapName) + "\\$z\\$s by " + map.Username + " has been removed!");
                        }
                        UI::EndMenu();
                    }
                }
            } else {
                UI::TextDisabled("The list is empty!");
                UI::Separator();
                UI::TextDisabled("To add a map here,");
                UI::TextDisabled("select the map in the menu");
                UI::TextDisabled("and click on 'Add to Play later'");
            }
            UI::EndMenu();
        }
        if (g_PlayLaterMaps.get_Length() > 0 && UI::MenuItem("\\$f00"+Icons::TrashO + " Clear list")){
            Dialogs::Question("\\$f90" + Icons::ExclamationTriangle + " \\$zAre you sure to empty the Play later list?", function(){
                g_PlayLaterMaps.RemoveRange(0, g_PlayLaterMaps.get_Length());
                SavePlayLater(g_PlayLaterMaps);
                Dialogs::Message("\\$0f0"+ Icons::Check +" \\$zPlay Later list has been cleared.");
            }, function(){});
        }
        UI::Separator();
         if (UI::BeginMenu(pluginColor+Icons::InfoCircle + " \\$zAbout")){
            if (UI::BeginMenu("\\$f00"+Icons::Heart + " \\$zSupport")){
                if (UI::MenuItem(pluginColor+Icons::Heart + " \\$zSupport ManiaExchange")) OpenBrowserURL("https://"+MXURL+"/support");
                if (UI::MenuItem(Icons::Heartbeat + " \\$zSupport the plugin creator")) OpenBrowserURL("https://github.com/sponsors/GreepTheSheep");
                UI::EndMenu();
            }
            UI::Separator();
            if (UI::BeginMenu(pluginColor+Icons::KeyboardO + " \\$zContact")){
                if (UI::MenuItem(pluginColor+Icons::KeyboardO + " \\$zContact ManiaExchange")) OpenBrowserURL("https://"+MXURL+"/messaging/compose/11");
                if (UI::MenuItem(Icons::DiscordAlt + "Plugin's creator Discord")) OpenBrowserURL("https://greep.gq/discord");
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
            UI::EndMenu();
        }
        UI::EndMenu();
    }
}

void Main(){
#if MP4
    if (repo == MP4mxRepos::Trackmania) MXURL = "tm.mania.exchange";
    else if (repo == MP4mxRepos::Shootmania) MXURL = "sm.mania.exchange";
#endif
    startnew(MX::GetAllMapTags);
    g_PlayLaterMaps = LoadPlayLater();

    while(true){
        yield();

        // Looks for the map to load or DL
        if (MX::mapToLoad != -1){
            MX::LoadMap(MX::mapToLoad);
            MX::mapToLoad = -1;
        }
        if (MX::mapToDL != -1){
            MX::DownloadMap(MX::mapToDL);
            MX::mapToDL = -1;
        }

        // Checks current played map
        auto currentMap = GetCurrentMap();
        if (!IsInEditor()){
            if (currentMap !is null){
                if (!MX::APIDown && currentMapID < 0 && currentMapID != -1) {
                    currentMapID = MX::GetCurrentMapMXID();
                    if (currentMapID < 0 && currentMapID != -3) {
                        if (IsDevMode()) print("MX ID error: " + currentMapID);
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

void RenderInterface(){
    mxMenu.Render();
    Dialogs::RenderInterface();
}

string changeEnumStyle(string enumName){
    string str = enumName.SubStr(enumName.IndexOf(":") + 1);
    str = str.Replace("_", " ");
    return str;
}

string UserMapsFolder(){
    try {
        CSystemFids@ userFolder = Fids::GetUserFolder('Maps');
        if (userFolder is null) return "<Invalid>";
        CSystemFids@ Tree = userFolder.Trees[0];
        if (Tree is null) return "<Invalid>";
        CSystemFidFile@ Fid = Tree.Leaves[0];
        if (Fid is null) return "<Invalid>";
        return Fid.ParentFolder.ParentFolder.FullDirName;
    } catch {
        return "<Invalid>";
    }
}