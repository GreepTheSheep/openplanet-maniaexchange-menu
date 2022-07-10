class Window{
    bool isOpened = false;

    array<Tab@> tabs;
    Tab@ activeTab;
    Tab@ c_lastActiveTab;
    Tab@ m_YourProfileTab;

    Window(){
        AddTab(HomePageTab());
        if (Setting_Tab_YourProfile_UserID != 0) {
            @m_YourProfileTab = UserTab(Setting_Tab_YourProfile_UserID, true);
            AddTab(m_YourProfileTab);
        }
        AddTab(MostAwardedTab());
        AddTab(FeaturedMapsTab());
        AddTab(TagsListTab());
        AddTab(LatestMapsTab());
        AddTab(RecentlyAwardedTab());
        AddTab(TOTDTab());
        AddTab(MapPackListTab());
        AddTab(SearchTab());
    }

    void AddTab(Tab@ tab, bool select = false, int index = -1){
        if (index == -1) tabs.InsertLast(tab);
        else tabs.InsertAt(index, tab);
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
            AddTab(m_YourProfileTab, false, 1);
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
        if(UI::Begin(nameMenu + " \\$666v"+Meta::ExecutingPlugin().Version+"###ManiaExchange Menu", isOpened)){
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
                    bool beginTabClosable = UI::BeginTabItem(tab.GetLabel(), open, flags);
                    if (tab.GetTooltip().Length > 0) UI::SetPreviousTooltip(tab.GetTooltip());
                    if (beginTabClosable){
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
                    bool beginTab = UI::BeginTabItem(tab.GetLabel(), flags);
                    if (tab.GetTooltip().Length > 0) UI::SetPreviousTooltip(tab.GetTooltip());
                    if (beginTab){
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