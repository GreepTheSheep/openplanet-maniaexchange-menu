class HomePageTab : Tab {
    UI::Font@ g_fontTitle;
    UI::Font@ g_fontHeader;
    UI::Font@ g_fontHeader2;

    HomePageTab() {
        @g_fontTitle = UI::LoadFont("DroidSans-Bold.ttf", 32);
        @g_fontHeader = UI::LoadFont("DroidSans-Bold.ttf", 24);
        @g_fontHeader2 = UI::LoadFont("DroidSans-Bold.ttf", 18);
    }

    string GetLabel() override { return Icons::Home; }

    string GetTooltip() override { return "Home"; }

    vec4 GetColor() override { return pluginColorVec; }

    void Render() override {
        float width = (UI::GetWindowSize().x*0.35)*0.5;
        vec2 posTop = UI::GetCursorPos();

        UI::BeginChild("Summary", vec2(width,0));

#if TMNEXT
        auto logo = Images::CachedFromURL("https://images.mania.exchange/logos/tmx/square_sm.png");
#else
        auto logo = Images::CachedFromURL("https://media.discordapp.net/attachments/373779861157838850/725132923795275806/mx_full.png");
#endif
        if (logo.m_texture !is null){
            vec2 logoSize = logo.m_texture.GetSize();
            UI::Image(logo.m_texture, vec2(
                width,
                logoSize.y / (logoSize.x / width)
            ));
        }

        UI::EndChild();
        UI::SetCursorPos(posTop + vec2(width + 8, 0));
        UI::BeginChild("Description");
        UI::PushFont(g_fontTitle);
        UI::Text("Welcome to " + pluginName);
        UI::PopFont();
        UI::PushFont(g_fontHeader2);
#if MP4
        string actualRepo = "Unknown";
        if (MXURL.StartsWith("tm.")) actualRepo = "Trackmania";
        else if (MXURL.StartsWith("sm.")) actualRepo = "Shootmania";
        UI::TextDisabled("The content network for "+actualRepo+" - driven by the community.");
#else
        UI::TextDisabled("The content network for Trackmania - driven by the community.");
#endif
        UI::PopFont();
        UI::SameLine();
        UI::TextDisabled(Icons::ExternalLink);
        UI::SetPreviousTooltip("Click to open the website");
        if (UI::IsItemClicked()) OpenBrowserURL("https://"+MXURL);
#if MP4
        UI::TextDisabled("Current repository: " + MXURL + "    " + Icons::InfoCircle);
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::Text("You can change the repository on the plugin settings.");
            UI::EndTooltip();
        }
#endif
        UI::Separator();

        UI::BeginTabBar("HomePageTabs");
        if(UI::BeginTabItem(Icons::Home + " Welcome!")){
            UI::BeginChild("HomeChild");
            HomePageTabRender::Home();
            UI::EndChild();
            UI::EndTabItem();
        }
        if(UI::BeginTabItem(Icons::InfoCircle + " About")){
            UI::BeginChild("AboutChild");
            HomePageTabRender::About();
            UI::EndChild();
            UI::EndTabItem();
        }
        if(UI::BeginTabItem(Icons::Tags + " Changelogs")){
            UI::BeginChild("ChangelogsChild");
            HomePageTabRender::Changelog();
            UI::EndChild();
            UI::EndTabItem();
        }
        UI::EndTabBar();
        UI::EndChild();
    }
}