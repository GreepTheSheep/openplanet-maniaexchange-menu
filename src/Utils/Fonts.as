namespace Fonts {
    UI::Font@ TitleBold;
    UI::Font@ BigBold;
    UI::Font@ Header;
    UI::Font@ MidBold;

    void Load() {
        @TitleBold = UI::LoadFont("DroidSans-Bold.ttf", 32);
        @BigBold = UI::LoadFont("DroidSans-Bold.ttf", 24);
        @Header = UI::LoadFont("DroidSans.ttf", 20, -1, -1, true, true, true);
        @MidBold = UI::LoadFont("DroidSans-Bold.ttf", 18);
    }
}
