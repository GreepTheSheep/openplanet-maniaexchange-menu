namespace IfaceRender
{
    void MapPackResult(MX::MapPackInfo@ mapPack)
    {
        UI::TableNextRow();

        UI::TableSetColumnIndex(0);
        UI::Text(mapPack.Name);

        UI::TableSetColumnIndex(1);
        UI::Text(mapPack.Username);

        UI::TableSetColumnIndex(2);
        if (mapPack.Tags.get_Length() == 0) UI::Text("No tags");
        else if (mapPack.Tags.get_Length() == 1) UI::Text(mapPack.Tags[0].Name);
        else{
            for (uint i = 0; i < mapPack.Tags.Length; i++) {
                IfaceRender::MapTag(mapPack.Tags[i]);
                UI::SameLine();
            }
        }

        UI::TableSetColumnIndex(3);
        // buttons
        if (UI::CyanButton(Icons::Kenney::InfoCircle)) {
            mxMenu.AddTab(MapPackTab(mapPack.ID), true);
        }
    }
}