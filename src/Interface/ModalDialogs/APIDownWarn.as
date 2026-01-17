class APIDownWarning : ModalDialog
{
    APIDownWarning() {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zWarning###APIDownWarning");
        m_size = vec2(400, 140);
    }

    void RenderDialog() override
    {
        if (!MX::APIDown) {
            Close();
        }

        UI::BeginChild("Content", vec2(0, -35));
        UI::Text(pluginName + " is currently offline.\nPlease try again later.");
        UI::EndChild();

        if (UI::Button(Icons::Times + " Close")) {
            Close();
        }

        UI::SameLine();

        UI::BeginDisabled(MX::APIRefresh);

        float buttonWidth = UI::MeasureButton(Icons::Refresh + " Retry").x;
        UI::RightAlignButton(buttonWidth);

        if (UI::GreenButton(Icons::Refresh + " Retry")) {
            startnew(MX::CheckForAPILoaded);
        }

        UI::EndDisabled();
    }
}