enum MapPackActions {
    AddPlayLater,
    Download
}

class MapPackActionWarn : ModalDialog
{
    MapPackActions m_action;
    array<MX::MapInfo@> m_mapPack_maps;

    MapPackActionWarn(MapPackActions action, array<MX::MapInfo@> mapPack_maps) {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zWarning###MapPackActionWarn");
        m_size = vec2(400, 140);
        m_action = action;
        m_mapPack_maps = mapPack_maps;
    }

    void RenderDialog() override
    {
        UI::BeginChild("Content", vec2(0, -35));
        switch (m_action) {
            case MapPackActions::AddPlayLater:
                UI::Text("This will add " + m_mapPack_maps.Length + " maps to the Play later list,\nare you sure?");
                break;
            case MapPackActions::Download:
                UI::Text("This will download " + m_mapPack_maps.Length + " maps to your Downloaded Maps folder,\nare you sure?");
                break;
            default:
                Close();
                break;
        }
        UI::EndChild();
        if (UI::Button(Icons::Times + " No")) {
            Close();
        }
        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 85, UI::GetCursorPos().y));
        if (UI::GreenButton(Icons::Check + " Yes")) {
            Close();
            switch (m_action) {
                case MapPackActions::AddPlayLater:
                    for (uint i = 0; i < mapPack_maps.Length; i++) {
                        g_PlayLaterMaps.InsertAt(g_PlayLaterMaps.Length, mapPack_maps[i]);
                    }
                    SavePlayLater(g_PlayLaterMaps);
                    UI::ShowNotification("\\$0f0"+Icons::Check+" \\$zAdded "+mapPack_maps.Length+" maps to the Play Later list");
                    break;
                case MapPackActions::Download:
                    for (uint i = 0; i < mapPack_maps.Length; i++) {
                        MX::MapInfo@ map = mapPack_maps[i];
                        UI::ShowNotification("Downloading map...", Text::OpenplanetFormatCodes(map.GbxMapName) + "\\$z\\$s by " + map.Username);
                        startnew(CoroutineFunc(map.DownloadMap));
                    }
                    break;
            }
        }
    }
}