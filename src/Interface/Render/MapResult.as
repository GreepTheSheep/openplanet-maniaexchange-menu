namespace IfaceRender
{
    void MapResult(MX::MapInfo@ map)
    {
        UI::TableNextRow();

        UI::TableSetColumnIndex(0);
        if (Setting_ColoredMapName) UI::Text(Text::OpenplanetFormatCodes(map.GbxMapName));
        else UI::Text(map.Name);
        UI::MXMapThumbnailTooltip(map.TrackID);
        if (UI::IsItemClicked()) mxMenu.AddTab(MapTab(map.TrackID), true);

        UI::TableSetColumnIndex(1);
        UI::Text(map.Username);
        UI::SetPreviousTooltip("Click to view "+map.Username+"'s profile");
        if (UI::IsItemClicked()) mxMenu.AddTab(UserTab(map.UserID), true);

        UI::TableSetColumnIndex(2);
        if (map.Tags.Length == 0) UI::Text("No tags");
        else if (map.Tags.Length == 1) UI::Text(map.Tags[0].Name);
        else{
            for (uint i = 0; i < map.Tags.Length; i++) {
                IfaceRender::MapTag(map.Tags[i]);
                UI::SameLine();
            }
        }

        UI::TableSetColumnIndex(3);
        UI::Text(tostring(map.AwardCount));

        UI::TableSetColumnIndex(4);
        // buttons
        if (UI::CyanButton(Icons::Kenney::InfoCircle)) {
            mxMenu.AddTab(MapTab(map.TrackID), true);
        }
        UI::MXMapThumbnailTooltip(map.TrackID);
        UI::SameLine();

        Json::Value SupportedModes = MX::ModesFromMapType();

#if TMNEXT
        if (Permissions::PlayLocalMap() && SupportedModes.HasKey(map.MapType)) {
#else
        if (SupportedModes.HasKey(map.MapType)) {
#endif
            if (UI::GreenButton(Icons::Play)) {
                if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(map.GbxMapName) + "\\$z\\$s by " + map.Username);
                MX::mapToLoad = map.TrackID;
            }

#if TMNEXT
        } else if (Permissions::PlayLocalMap() && !SupportedModes.HasKey(map.MapType) && Setting_ShowPlayOnAllMaps) {
#else
        } else if (!SupportedModes.HasKey(map.MapType) && Setting_ShowPlayOnAllMaps) {
#endif
            if (UI::OrangeButton(Icons::Play)) {
                if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(map.GbxMapName) + "\\$z\\$s by " + map.Username);
                UI::ShowNotification(Icons::ExclamationTriangle + " Warning", "The map type is not supported for direct play, it can crash your game or returns you to the menu", UI::HSV(0.11, 1.0, 1.0), 15000);
                MX::mapToLoad = map.TrackID;
            }
            if (UI::IsItemHovered()) {
                UI::BeginTooltip();
                UI::Text(Icons::ExclamationTriangle + " The map type is not supported for direct play, it can crash your game or returns you to the menu");
                UI::TextDisabled(map.MapType);
                UI::EndTooltip();
            }
#if TMNEXT
        } else if (Permissions::PlayLocalMap() && !SupportedModes.HasKey(map.MapType) && !Setting_ShowPlayOnAllMaps) {
#else
        } else if (!SupportedModes.HasKey(map.MapType) && !Setting_ShowPlayOnAllMaps) {
#endif
            UI::Text("\\$f90"+Icons::ExclamationTriangle);
            if (UI::IsItemHovered()) {
                UI::BeginTooltip();
                UI::Text(Icons::ExclamationTriangle + " The map type is not supported for direct play, it can crash your game or returns you to the menu");
                UI::TextDisabled(map.MapType);
                UI::Separator();
                UI::Text("If you still want to play this map, check the box \"Show Play Button on all map types\" in the plugin settings");
                UI::EndTooltip();
            }
        }
    }
}