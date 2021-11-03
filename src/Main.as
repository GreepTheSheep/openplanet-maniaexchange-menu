string inputMapID = "";

void RenderMenu()
{
    if(UI::MenuItem(nameMenu, "", mxMenu.isOpened)) {
        mxMenu.isOpened = !mxMenu.isOpened;
    }
}

void RenderMenuMain(){
    if(UI::BeginMenu(nameMenu)) {
        if(UI::MenuItem(pluginColor + Icons::WindowMaximize+"\\$z Open "+shortMXName+" menu", "", mxMenu.isOpened)) {
            mxMenu.isOpened = !mxMenu.isOpened;
        }
        if(UI::BeginMenu(pluginColor + Icons::ICursor+"\\$z Enter map ID")) {
            inputMapID = UI::InputText("", inputMapID);
            if (inputMapID != ""){
#if TMNEXT
                if (Permissions::PlayLocalMap() && UI::MenuItem(Icons::Play + " Play map")){
#else
                if (UI::MenuItem(Icons::Play + " Play map")){
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
        
        UI::Separator();
        if (UI::BeginMenu(Icons::ClockO + " Play later")){
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
                        if (UI::MenuItem(Icons::Kenney::InfoCircle + " Open information")){
                            if (!mxMenu.isOpened) mxMenu.isOpened = true;
                            mxMenu.AddTab(MapTab(map.TrackID), true);
                        }
                        if (UI::MenuItem("\\$f00"+Icons::TrashO + " Remove map")){
                            g_PlayLaterMaps.RemoveAt(i);
                            SavePlayLater(g_PlayLaterMaps);
                        }
                        
                        UI::EndMenu();
                    }
                }
            } else {
                UI::TextDisabled("The list is empty!");
                UI::Separator();
                UI::TextDisabled("To add a map here,");
                UI::TextDisabled("select the map in the menu");
                UI::TextDisabled("and click on the 'Add to Play later'");
            }
            UI::EndMenu();
        }
        UI::EndMenu();
    }
}

void Main(){
    startnew(MX::GetAllMapTags);
    startnew(MX::LookForMapToLoad);
    g_PlayLaterMaps = LoadPlayLater();
}

void RenderInterface(){
    mxMenu.Render();
}