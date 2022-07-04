class Window{
    bool isOpened = false;

    array<Tab@> tabs;
    Tab@ activeTab;
    Tab@ c_lastActiveTab;
    Tab@ m_YourProfileTab;

    Window(){
        AddTab(HomePageTab());
        AddTab(MostAwardedTab());
        AddTab(FeaturedMapsTab());
        AddTab(TagsListTab());
        AddTab(LatestMapsTab());
        AddTab(RecentlyAwardedTab());
        AddTab(TOTDTab());
        AddTab(MapPackListTab());
        AddTab(SearchTab());
        if (Setting_Tab_YourProfile_UserID != 0) {
            @m_YourProfileTab = UserTab(Setting_Tab_YourProfile_UserID, true);
            AddTab(m_YourProfileTab);
        }
    }

    void AddTab(Tab@ tab, bool select = false){
        tabs.InsertLast(tab);
        if (select) {
            @activeTab = tab;
        }
    }

    void RemoveTab(Tab@ tab){
        tabs.RemoveAt(tabs.FindByRef(tab));
    }

    void Render(){
        if(!isOpened) return;

        if (Setting_Tab_YourProfile_UserID != 0 && Setting_Tab_YourProfile_UserID != Tab_YourProfile_UserID_Old) {
            if (m_YourProfileTab !is null) {
               RemoveTab(m_YourProfileTab);
            }
            @m_YourProfileTab = UserTab(Setting_Tab_YourProfile_UserID, true);
            AddTab(m_YourProfileTab);
            Tab_YourProfile_UserID_Old = Setting_Tab_YourProfile_UserID;
        }

        if (Setting_Tab_YourProfile_UserID == 0 && m_YourProfileTab !is null) {
            RemoveTab(m_YourProfileTab);
            @m_YourProfileTab = null;
        }

        UI::PushStyleColor(UI::Col::WindowBg,vec4(.1,.1,.1,1));
        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(10, 10));
        UI::PushStyleVar(UI::StyleVar::WindowRounding, 10.0);
        UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(10, 6));
        UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(.5, .5));
        UI::SetNextWindowSize(820, 500);
        if(UI::Begin(nameMenu + " \\$666v"+Meta::ExecutingPlugin().get_Version(), isOpened)){
            // Push the last active tab style so that the separator line is colored (this is drawn in BeginTabBar)
            auto lastActiveTab = c_lastActiveTab;
            if (lastActiveTab !is null) {
                lastActiveTab.PushTabStyle();
            }
            UI::BeginTabBar("Tabs");

            for(uint i = 0; i < tabs.Length; i++){
                auto tab = tabs[i];
                if (!tab.IsVisible()) continue;

                UI::PushID(tab);

                int flags = 0;
                if (tab is activeTab) {
                    flags |= UI::TabItemFlags::SetSelected;
                    if (!tab.GetLabel().Contains("Loading")) @activeTab = null;
                }

                tab.PushTabStyle();

                if (tab.CanClose()){
                    bool open = true;
                    if(UI::BeginTabItem(tab.GetLabel(), open, flags)){
                        @c_lastActiveTab = tab;

                        UI::BeginChild("Tab");
                        tab.Render();
                        UI::EndChild();

                        UI::EndTabItem();
                    }
                    if (!open){
                        tabs.RemoveAt(i--);
                    }
                } else {
                    if(UI::BeginTabItem(tab.GetLabel(), flags)){
                        @c_lastActiveTab = tab;

                        UI::BeginChild("Tab");
                        tab.Render();
                        UI::EndChild();

                        UI::EndTabItem();
                    }
                }

                tab.PopTabStyle();

                UI::PopID();

            }

            UI::EndTabBar();

            // Pop the tab style (for the separator line) only after EndTabBar, to satisfy the stack unroller
            if (lastActiveTab !is null) {
                lastActiveTab.PopTabStyle();
            }
        }
        UI::End();
        UI::PopStyleVar(4);
        UI::PopStyleColor(1);
    }

}