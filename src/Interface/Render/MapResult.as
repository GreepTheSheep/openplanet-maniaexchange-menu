namespace IfaceRender
{
    void MapResult(MX::MapInfo@ map)
    {
        UI::TableNextRow();

        UI::TableSetColumnIndex(0);
        if (Setting_ColoredMapName) UI::Text(ColoredString(map.GbxMapName));
        else UI::Text(map.Name);

        UI::TableSetColumnIndex(1);
        UI::Text(map.Username);

        UI::TableSetColumnIndex(2);
        if (map.Tags.get_Length() == 0) UI::Text("No tags");
        else if (map.Tags.get_Length() == 1) UI::Text(map.Tags[0].Name);
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
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
            auto img = Images::CachedFromURL("https://"+MXURL+"/maps/"+map.TrackID+"/image/1");
            float width = Draw::GetWidth() * 0.50;

            if (img.m_texture !is null){
                vec2 thumbSize = img.m_texture.GetSize();
                UI::Image(img.m_texture, vec2(
                    width,
                    thumbSize.y / (thumbSize.x / width)
                ));
            } else {
                auto thumb = Images::CachedFromURL("https://"+MXURL+"/maps/thumbnail/"+map.TrackID);
                width = Draw::GetWidth() * 0.30;
                if (thumb.m_texture !is null){
                    vec2 thumbSize = thumb.m_texture.GetSize();
                    UI::Image(thumb.m_texture, vec2(
                        width,
                        thumbSize.y / (thumbSize.x / width)
                    ));
                }
            }
            UI::EndTooltip();
        }
        UI::SameLine();

        Json::Value SupportedModes = MX::ModesFromMapType();

#if TMNEXT
        if (Permissions::PlayLocalMap() && SupportedModes.HasKey(map.MapType)) {
#else
        if (SupportedModes.HasKey(map.MapType)) {
#endif
            if (UI::GreenButton(Icons::Play)) {
                if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                UI::ShowNotification("Loading map...", ColoredString(map.GbxMapName) + "\\$z\\$s by " + map.Username);
                MX::mapToLoad = map.TrackID;
            }

#if TMNEXT
        } else if (Permissions::PlayLocalMap() && !SupportedModes.HasKey(map.MapType) && Setting_ShowPlayOnAllMaps) {
#else
        } else if (!SupportedModes.HasKey(map.MapType) && Setting_ShowPlayOnAllMaps) {
#endif
            if (UI::OrangeButton(Icons::Play)) {
                if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                UI::ShowNotification("Loading map...", ColoredString(map.GbxMapName) + "\\$z\\$s by " + map.Username);
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