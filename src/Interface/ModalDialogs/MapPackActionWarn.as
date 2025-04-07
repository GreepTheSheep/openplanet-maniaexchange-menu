enum MapPackActions {
    AddPlayLater,
    Download
}

class MapPackActionWarn : ModalDialog
{
    MapPackActions m_action;
    array<MX::MapInfo@> m_mapPack_maps;

    MapPackActionWarn(MapPackActions action, array<MX::MapInfo@> maps) {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zWarning###MapPackActionWarn");
        m_size = vec2(400, 140);
        m_action = action;
        m_mapPack_maps = maps;
    }

    void RenderDialog() override
    {
        UI::BeginChild("Content", vec2(0, -35));
        switch (m_action) {
            case MapPackActions::AddPlayLater:
                UI::Text("This will add " + m_mapPack_maps.Length + " maps to the Play later list.\n\nAre you sure?");
                break;
            case MapPackActions::Download:
                UI::Text("This will download " + m_mapPack_maps.Length + " maps to your Downloaded Maps folder.\n\nAre you sure?");
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
                    for (uint i = 0; i < m_mapPack_maps.Length; i++) {
                        g_PlayLaterMaps.InsertAt(g_PlayLaterMaps.Length, m_mapPack_maps[i]);
                    }
                    SavePlayLater(g_PlayLaterMaps);
                    UI::ShowNotification(pluginName, Icons::Check + " Succesfully added " + m_mapPack_maps.Length + " maps to the Play Later list", UI::HSV(0.33, 0.7, 0.65));
                    break;
                case MapPackActions::Download:
                    for (uint i = 0; i < m_mapPack_maps.Length; i++) {
                        MX::MapInfo@ map = m_mapPack_maps[i];
                        startnew(CoroutineFunc(map.DownloadMap));
                    }
                    UI::ShowNotification(pluginName, Icons::Check+" Succesfully downloaded " + m_mapPack_maps.Length + " maps to your Downloaded Maps folder", UI::HSV(0.33, 0.7, 0.65));
                    break;
            }
        }
    }
}