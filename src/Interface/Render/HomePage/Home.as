namespace HomePageTabRender {
    void Home()
    {
        if (MX::APIDown) {
            UI::Text("\\$f80" + Icons::ExclamationTriangle + " \\$z" + pluginName + " servers are not responding.");
            if (MX::APIRefresh) {
                UI::Text(Icons::AnimatedHourglass + " Refreshing...");
            } else if (UI::Button(Icons::Refresh + " Refresh")) {
                startnew(MX::CheckForAPILoaded);
            }
        } else {
            UI::PushFont(Fonts::Header);
            UI::Text("Welcome to " + pluginName + ", select a tab to begin.");
            UI::PopFont();
        }
    }
}