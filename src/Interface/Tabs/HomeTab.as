class HomePageTab : Tab {
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
        auto logo = Images::CachedFromURL("https://images.mania.exchange/logos/mx/square_sm.png");
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
        UI::PushFont(Fonts::TitleBold);
        UI::Text("Welcome to " + pluginName);
        UI::PopFont();
        UI::PushFont(Fonts::MidBold);
#if MP4
        UI::TextDisabled("The content network for " + tostring(repo) + " - driven by the community.");
#else
        UI::TextDisabled("The content network for Trackmania - driven by the community.");
#endif
        UI::PopFont();
        UI::SameLine();
        UI::TextDisabled(Icons::ExternalLink);
        UI::SetItemTooltip("Click to open the website");
        if (UI::IsItemClicked()) OpenBrowserURL("https://"+MXURL);
#if MP4
        UI::TextDisabled("Current repository: " + MXURL + "    " + Icons::InfoCircle);
        if (UI::BeginItemTooltip()) {
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