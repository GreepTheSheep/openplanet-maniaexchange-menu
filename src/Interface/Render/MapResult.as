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
            int width = 800;

            if (img.m_texture !is null){
                vec2 thumbSize = img.m_texture.GetSize();
                UI::Image(img.m_texture, vec2(
                    width,
                    thumbSize.y / (thumbSize.x / width)
                ));
            } else {
                auto thumb = Images::CachedFromURL("https://"+MXURL+"/maps/thumbnail/"+map.TrackID);
                width = 400;
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

#if TMNEXT
        bool isRoyal = false;
        for (uint i = 0; i < map.Tags.get_Length(); i++) {
            MX::MapTag@ tag = map.Tags[i];
            if (tag.ID == 37) { // Royal map
                isRoyal = true;
                break;
            }
        }


        if ((Permissions::PlayLocalMap() && !isRoyal && UI::GreenButton(Icons::Play)) || (Permissions::PlayLocalMap() && isRoyal && Setting_ShowPlayOnRoyalMap && UI::OrangeButton(Icons::Play))) {
#else
        if (UI::GreenButton(Icons::Play)) {
#endif        
            if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
            UI::ShowNotification("Loading map...", ColoredString(map.GbxMapName) + "\\$z\\$s by " + map.Username);
            MX::mapToLoad = map.TrackID;
        }
    }
}