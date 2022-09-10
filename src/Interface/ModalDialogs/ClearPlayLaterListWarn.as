class ClarPlayLaterListWarn : ModalDialog
{
    ClarPlayLaterListWarn() {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zWarning###ClarPlayLaterListWarn");
        m_size = vec2(400, 140);
    }

    void RenderDialog() override
    {
        UI::BeginChild("Content", vec2(0, -35));
        UI::Text("Are you sure to empty the Play later list?");
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
            UI::ShowNotification("\\$0f0"+ Icons::Check +" \\$zPlay Later list has been cleared.");
        }
    }
}