namespace HomePageTabRender {
    Resources::Font@ Header = Resources::GetFont("DroidSans.ttf", 20);

    void Home()
    {
        UI::PushFont(Header);
        UI::Text("Welcome to " + pluginName + ", select a tab to begin.");
        UI::PopFont();
    }
}