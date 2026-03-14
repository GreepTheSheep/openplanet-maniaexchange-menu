namespace IfaceRender
{
    void MapPackResult(MX::MapPackInfo@ mapPack)
    {
        UI::TableNextRow();

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();
            UI::Text(mapPack.Name);

            UI::MXMapPackThumbnailTooltip(mapPack.MappackId);

            if (UI::IsItemClicked()) {
                mxMenu.AddTab(MapPackTab(mapPack), true);
            }
        }

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();

            UI::Text(mapPack.Username);
            UI::SetItemTooltip("Click to view "+mapPack.Username+"'s profile");

            if (UI::IsItemClicked()) {
                mxMenu.AddTab(UserTab(mapPack.UserId), true);
            }
        }

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();
            UI::Text(mapPack.TypeName);
        }

        if (UI::TableNextColumn()) {
#if TMNEXT
            if (Setting_VistaIcons) {
                MX::RenderVistaIcon(mapPack.Environment, mapPack.EnvironmentName);
            } else {
#endif
                UI::AlignTextToFramePadding();
                UI::Text(mapPack.EnvironmentName);
#if TMNEXT
            }
#endif
        }

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();

            if (mapPack.Tags.IsEmpty()) {
                UI::Text("No tags");
            } else {
                for (uint i = 0; i < mapPack.Tags.Length; i++) {
                    IfaceRender::MapTag(mapPack.Tags[i]);
                    UI::SameLine();
                }
            }
        }

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();
            UI::Text(tostring(mapPack.MapCount));
        }

        if (UI::TableNextColumn()) {
            if (UI::CyanButton(Icons::Kenney::InfoCircle)) {
                mxMenu.AddTab(MapPackTab(mapPack), true);
            }

            UI::MXMapPackThumbnailTooltip(mapPack.MappackId);
        }
    }
}