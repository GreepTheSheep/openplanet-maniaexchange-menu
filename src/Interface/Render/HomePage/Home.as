namespace HomePageTabRender {
    UI::Font@ Header = UI::LoadFont("DroidSans.ttf", 20);

    void Home()
    {
        if (MX::APIDown) {
            UI::Text("\\$f80" + Icons::ExclamationTriangle + " \\$z"+ Meta::ExecutingPlugin().Name + " servers is not responding.");
            if (!MX::APIRefresh && UI::Button(Icons::Refresh + " Refresh")) {
                startnew(MX::CheckForAPILoaded);
            }
            if (MX::APIRefresh) {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Refreshing...");
            }
        } else {
            UI::PushFont(Header);
            UI::Text("Welcome to " + pluginName + ", select a tab to begin.");
            UI::PopFont();
        }
    }
}