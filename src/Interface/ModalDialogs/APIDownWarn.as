class APIDownWarning : ModalDialog
{
    APIDownWarning() {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zWarning###APIDownWarning");
        m_size = vec2(400, 140);
    }

    void RenderDialog() override
    {
        UI::BeginChild("Content", vec2(0, -35));
        UI::Text(pluginName + " is currently offline.\nPlease try again later.");
        UI::EndChild();
        if (UI::Button(Icons::Times + " Close")) {
            Close();
        }
        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - (MX::APIRefresh ? 40 : 85), UI::GetCursorPos().y));
        if (MX::APIDown) {
            if (MX::APIRefresh) {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass);
            } else {
                if (UI::GreenButton(Icons::Refresh + " Retry")) {
                    startnew(MX::CheckForAPILoaded);
                }
            }
        } else {
            Close();
        }
    }
}