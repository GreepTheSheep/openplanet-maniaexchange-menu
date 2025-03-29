namespace IfaceRender
{
    void MapPackResult(MX::MapPackInfo@ mapPack)
    {
        UI::TableNextRow();

        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        UI::Text(mapPack.Name);
        UI::MXMapPackThumbnailTooltip(mapPack.MappackId);
        if (UI::IsItemClicked()) mxMenu.AddTab(MapPackTab(mapPack.MappackId), true);

        UI::TableNextColumn();
        UI::Text(mapPack.Username);
        UI::SetItemTooltip("Click to view "+mapPack.Username+"'s profile");
        if (UI::IsItemClicked()) mxMenu.AddTab(UserTab(mapPack.UserId), true);

        UI::TableNextColumn();
        if (mapPack.Tags.Length == 0) UI::Text("No tags");
        else{
            for (uint i = 0; i < mapPack.Tags.Length; i++) {
                IfaceRender::MapTag(mapPack.Tags[i]);
                UI::SameLine();
            }
        }

        UI::TableNextColumn();
        UI::Text(tostring(mapPack.MapCount));

        UI::TableNextColumn();
        // buttons
        if (UI::CyanButton(Icons::Kenney::InfoCircle)) {
            mxMenu.AddTab(MapPackTab(mapPack.MappackId), true);
        }
        UI::MXMapPackThumbnailTooltip(mapPack.MappackId);
    }
}