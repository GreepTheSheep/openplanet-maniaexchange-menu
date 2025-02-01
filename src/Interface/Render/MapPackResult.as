namespace IfaceRender
{
    void MapPackResult(MX::MapPackInfo@ mapPack)
    {
        UI::TableNextRow();

        UI::TableSetColumnIndex(0);
        UI::AlignTextToFramePadding();
        UI::Text(mapPack.Name);
        UI::MXMapPackThumbnailTooltip(mapPack.MappackId);
        if (UI::IsItemClicked()) mxMenu.AddTab(MapPackTab(mapPack.MappackId), true);

        UI::TableSetColumnIndex(1);
        UI::Text(mapPack.Username);
        UI::SetPreviousTooltip("Click to view "+mapPack.Username+"'s profile");
        if (UI::IsItemClicked()) mxMenu.AddTab(UserTab(mapPack.UserId), true);

        UI::TableSetColumnIndex(2);
        if (mapPack.Tags.Length == 0) UI::Text("No tags");
        else{
            for (uint i = 0; i < mapPack.Tags.Length; i++) {
                IfaceRender::MapTag(mapPack.Tags[i]);
                UI::SameLine();
            }
        }

        UI::TableSetColumnIndex(3);
        UI::Text(tostring(mapPack.MapCount));

        UI::TableSetColumnIndex(4);
        // buttons
        if (UI::CyanButton(Icons::Kenney::InfoCircle)) {
            mxMenu.AddTab(MapPackTab(mapPack.MappackId), true);
        }
        UI::MXMapPackThumbnailTooltip(mapPack.MappackId);
    }
}