enum MapPackActions {
    AddPlayLater,
    Download
}

class MapPackActionWarn : ModalDialog
{
    MapPackActions m_action;
     MX::MapPackInfo@ m_mapPack;

    MapPackActionWarn(MapPackActions action, MX::MapPackInfo@ pack) {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zWarning###MapPackActionWarn");
        m_size = vec2(400, 140);
        m_action = action;
        @m_mapPack = pack;
    }

    void RenderDialog() override
    {
        UI::BeginChild("Content", vec2(0, -35));

        switch (m_action) {
            case MapPackActions::AddPlayLater:
                UI::Text("This will add " + m_mapPack.Maps.Length + " maps to the Play later list.\n\nAre you sure?");
                break;
            case MapPackActions::Download:
                UI::Text("This will download " + m_mapPack.Maps.Length + " maps to your Downloaded Maps folder.\n\nAre you sure?");
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

        float buttonWidth = UI::MeasureButton(Icons::Check + " Yes").x;
        UI::RightAlignButton(buttonWidth);

        if (UI::GreenButton(Icons::Check + " Yes")) {
            Close();

            switch (m_action) {
                case MapPackActions::AddPlayLater:
                    startnew(CoroutineFunc(m_mapPack.AddToPlayLater));
                    break;
                case MapPackActions::Download:
                    startnew(CoroutineFunc(m_mapPack.DownloadMaps));
                    break;
            }
        }
    }
}