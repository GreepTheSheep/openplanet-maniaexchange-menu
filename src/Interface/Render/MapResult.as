namespace IfaceRender
{
    void MapResult(MX::MapInfo@ map)
    {
        UI::TableNextRow();

        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        if (Setting_ColoredMapName) UI::Text(Text::OpenplanetFormatCodes(map.GbxMapName));
        else UI::Text(map.Name);
        UI::MXMapThumbnailTooltip(map.MapId);
        if (UI::IsItemClicked()) mxMenu.AddTab(MapTab(map), true);

        UI::TableNextColumn();
        UI::Text(map.Username);
        UI::SetItemTooltip("Click to view "+map.Username+"'s profile");
        if (UI::IsItemClicked()) mxMenu.AddTab(UserTab(map.UserId), true);

#if MP4
        UI::TableNextColumn();
        string envi = map.EnvironmentName.Length == 0 ? "Unknown" : map.EnvironmentName;
        string vehicle = map.VehicleName.Length == 0 ? "Unknown" : map.VehicleName;
        UI::Text(envi + "/" + vehicle);

        UI::TableNextColumn();
        UI::Text(map.TitlePack.Length == 0 ? "Unknown" : map.TitlePack);
#endif

        UI::TableNextColumn();
        if (map.Tags.Length == 0) UI::Text("No tags");
        else{
            for (uint i = 0; i < map.Tags.Length; i++) {
                IfaceRender::MapTag(map.Tags[i]);
                UI::SameLine();
            }
        }

        UI::TableNextColumn();
        UI::Text(tostring(map.AwardCount));

        UI::TableNextColumn();
        // buttons
        if (UI::CyanButton(Icons::Kenney::InfoCircle)) {
            mxMenu.AddTab(MapTab(map), true);
        }
        UI::MXMapThumbnailTooltip(map.MapId);
        UI::SameLine();

        bool isMapTypeSupported = MX::ModesFromMapType.Exists(map.MapType);

#if TMNEXT
        if (Permissions::PlayLocalMap() && isMapTypeSupported) {
#else
        if (isMapTypeSupported) {
#endif
            if (UI::GreenButton(Icons::Play)) {
                if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(map.GbxMapName) + "\\$z\\$s by " + map.Username);
                MX::mapToLoad = map.MapId;
            }

#if TMNEXT
        } else if (Permissions::PlayLocalMap() && !isMapTypeSupported && Setting_ShowPlayOnAllMaps) {
#else
        } else if (!isMapTypeSupported && Setting_ShowPlayOnAllMaps) {
#endif
            if (UI::OrangeButton(Icons::Play)) {
                if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(map.GbxMapName) + "\\$z\\$s by " + map.Username);
                UI::ShowNotification(Icons::ExclamationTriangle + " Warning", "The map type is not supported for direct play, it can crash your game or returns you to the menu", UI::HSV(0.11, 1.0, 1.0), 15000);
                MX::mapToLoad = map.MapId;
            }
            if (UI::BeginItemTooltip()) {
                UI::Text(Icons::ExclamationTriangle + " The map type is not supported for direct play, it can crash your game or returns you to the menu");
                UI::TextDisabled(map.MapType);
                UI::EndTooltip();
            }
#if TMNEXT
        } else if (Permissions::PlayLocalMap() && !isMapTypeSupported && !Setting_ShowPlayOnAllMaps) {
#else
        } else if (!isMapTypeSupported && !Setting_ShowPlayOnAllMaps) {
#endif
            UI::BeginDisabled();
            UI::OrangeButton(Icons::ExclamationTriangle);
            UI::EndDisabled();
            if (UI::BeginItemTooltip()) {
                UI::Text(Icons::ExclamationTriangle + " The map type is not supported for direct play, it can crash your game or returns you to the menu");
                UI::TextDisabled(map.MapType);
                UI::Separator();
                UI::Text("If you still want to play this map, check the box \"Show Play Button on all map types\" in the plugin settings");
                UI::EndTooltip();
            }
        }
    }
}