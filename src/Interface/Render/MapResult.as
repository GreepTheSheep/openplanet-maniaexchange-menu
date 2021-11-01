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
        UI::SameLine();
#if TMNEXT
        if (Permissions::PlayLocalMap() && UI::GreenButton(Icons::Play)) {
#else
        if (UI::GreenButton(Icons::Play)) {
#endif        
            if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
            UI::ShowNotification("Loading map...", ColoredString(map.GbxMapName) + "\\$z\\$s by " + map.Username);
            MX::mapToLoad = map.TrackID;
        }
        UI::Separator();
    }
}