namespace HomePageTabRender {
    UI::Font@ Header = UI::LoadFont("DroidSans.ttf", 20);

    void Home()
    {
        UI::PushFont(Header);
        UI::Text("Welcome to " + pluginName + ", select a tab to begin.");
        UI::PopFont();
    }
}