class Window{
    bool isOpened = false;

    array<Tab@> tabs;
    Tab@ activeTab;
    Tab@ c_lastActiveTab;

    Window(){
        AddTab(MostAwardedTab());
        AddTab(FeaturedMapsTab());
        AddTab(TagsListTab());
        AddTab(LatestMapsTab());
        AddTab(RecentlyAwardedTab());
        AddTab(SearchTab());
        AddTab(MapPackListTab());
        // AddTab(LatestMapPacksTab());
        // AddTab(MostDownloadedMapPacks());
    }

    void AddTab(Tab@ tab, bool select = false){
        tabs.InsertLast(tab);
        if (select) {
            @activeTab = tab;
        }
    }

    void Render(){
        if(!isOpened) return;

        UI::PushStyleColor(UI::Col::WindowBg,vec4(0,0,0,1));

        UI::SetNextWindowSize(800, 500);
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
        UI::PopStyleColor(1);
    }

}

Window mxMenu;