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
            string tags = "";
            for (uint i = 0; i < map.Tags.get_Length(); i++) {
                if (i == map.Tags.get_Length() - 1) tags += map.Tags[i].Name;
                else tags += map.Tags[i].Name + ", ";
            }
            UI::Text(tags);
        }

        UI::TableSetColumnIndex(3);
        UI::Text(tostring(map.AwardCount));

        UI::TableSetColumnIndex(4);
        // buttons
        vec2 pos_orig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos_orig.x + 35, pos_orig.y));
        if (UI::GreenButton(Icons::Play)) MX::mapToLoad = map.TrackID;
        UI::SetCursorPos(pos_orig);
    }
}