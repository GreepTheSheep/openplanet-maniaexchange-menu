namespace HomePageTabRender {
    void Home()
    {
        if (MX::APIDown) {
            UI::Text("\\$f80" + Icons::ExclamationTriangle + " \\$z"+ Meta::ExecutingPlugin().Name + " servers is not responding.");
            if (!MX::APIRefresh && UI::Button(Icons::Refresh + " Refresh")) {
                startnew(MX::CheckForAPILoaded);
            }
            if (MX::APIRefresh) {
                UI::Text(Icons::AnimatedHourglass + " Refreshing...");
            }
        } else {
            UI::PushFont(Fonts::Header);
            UI::Text("Welcome to " + pluginName + ", select a tab to begin.");
            UI::PopFont();
        }
    }
}