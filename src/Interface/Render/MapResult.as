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
        UI::AlignTextToFramePadding();
        UI::Text(map.Username);
        UI::SetItemTooltip("Click to view "+map.Username+"'s profile");
        if (UI::IsItemClicked()) mxMenu.AddTab(UserTab(map.UserId), true);

        UI::TableNextColumn();

#if TMNEXT
        if (Setting_VistaIcons) {
            MX::RenderVistaIcon(map.Environment, map.EnvironmentName);
        } else {
#endif
            UI::AlignTextToFramePadding();
            UI::Text(map.EnvironmentName);
#if TMNEXT
        }
#endif

        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        UI::Text(map.VehicleName.Length == 0 ? "Unknown" : map.VehicleName);

        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        UI::Text(tostring(map.GameMode));

        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        UI::Text(map.TitlePack.Length == 0 ? "Unknown" : map.TitlePack);

        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        if (map.Tags.IsEmpty()) {
            UI::Text("No tags");
        } else {
            for (uint i = 0; i < map.Tags.Length; i++) {
                IfaceRender::MapTag(map.Tags[i]);
                UI::SameLine();
            }
        }

        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        UI::Text(map.LengthStr);

        UI::TableNextColumn();
        MX::RenderDifficultyIcon(map.Difficulty);

        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        if (map.AwardCount > 0) {
            UI::Text("\\$FB1" + Icons::Trophy + "\\$z " + map.AwardCount);
        }

        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        UI::Text(map.PlayerCountStr);

        UI::TableNextColumn();
        UI::AlignTextToFramePadding();

        if (map.AuthorBeaten) {
            UI::Text("\\$9fc" + Icons::ClockO);
            UI::SetItemTooltip("Has records, AT beaten");
        } else if (!map.AuthorBeatable) {
            UI::Text("\\$f77" + Icons::ClockO);
            UI::SetItemTooltip("AT unbeatable");
        } else if (map.PlayerCount > 0) {
            UI::Text(Icons::ClockO);
            UI::SetItemTooltip("Has records");
        }

        UI::TableNextColumn();
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
                UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(map.GbxMapName) + "\\$z\\$s by " + map.Username);
                startnew(CoroutineFunc(map.PlayMap));
            }

#if TMNEXT
        } else if (Permissions::PlayLocalMap() && !isMapTypeSupported && Setting_ShowPlayOnAllMaps) {
#else
        } else if (!isMapTypeSupported && Setting_ShowPlayOnAllMaps) {
#endif
            if (UI::OrangeButton(Icons::Play)) {
                UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(map.GbxMapName) + "\\$z\\$s by " + map.Username);
                UI::ShowNotification(Icons::ExclamationTriangle + " Warning", "The map type is not supported for direct play, it can crash your game or returns you to the menu", UI::HSV(0.11, 1.0, 1.0), 15000);
                startnew(CoroutineFunc(map.PlayMap));
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