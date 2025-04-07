class ClearPlayLaterListWarn : ModalDialog
{
    ClearPlayLaterListWarn() {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zWarning###ClearPlayLaterListWarn");
        m_size = vec2(400, 140);
    }

    void RenderDialog() override
    {
        UI::BeginChild("Content", vec2(0, -35));
        UI::Text("This will clear the Play later list.\n\nAre you sure?");
        UI::EndChild();
        if (UI::Button(Icons::Times + " No")) {
            Close();
        }
        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 85, UI::GetCursorPos().y));
        if (UI::RedButton(Icons::TrashO + " Yes")) {
            Close();
            g_PlayLaterMaps.RemoveRange(0, g_PlayLaterMaps.Length);
            SavePlayLater(g_PlayLaterMaps);
            UI::ShowNotification(pluginName, Icons::Check + " Succesfully cleared the Play Later list.", UI::HSV(0.33, 0.7, 0.65));
        }
    }
}