class PersonalListsTab : MapListTab
{
    array<string> t_lists = {
#if DEPENDENCY_NADEOSERVICES
        "Favorites",
#endif
        "Play later"
    };
    string t_selectedList = t_lists[0];

    bool IsVisible() override {return Setting_Tab_PersonalLists_Visible;}
    string GetLabel() override {return Icons::List + " Personal Lists";}

    vec4 GetColor() override { return vec4(0.58f, 0.1f, 0.79f, 1); }

    void GetRequestParams(dictionary@ params) override {}

    void StartRequest() override
    {
#if DEPENDENCY_NADEOSERVICES
        if (t_selectedList == "Favorites") {
            array<MX::MapInfo@> mxMapInfo;
            for (uint i = 0; i < MXNadeoServicesGlobal::g_favoriteMaps.Length; i++) {
                if (MXNadeoServicesGlobal::g_favoriteMaps[i].MXMapInfo !is null) {
                    maps.InsertLast(MXNadeoServicesGlobal::g_favoriteMaps[i].MXMapInfo);
                }
            }
        }
#endif
        if (t_selectedList == "Play later") {
            maps = g_PlayLaterMaps;
        }
    }

    void CheckStartRequest() override
    {
        if (!MX::APIDown && maps.Length == 0 && UI::IsWindowAppearing()) {
            StartRequest();
        }
    }

    void RenderHeader() override
    {
        UI::SetNextItemWidth(120);
        if (UI::BeginCombo("##PersonalListSelect", t_selectedList)){
            for (uint i = 0; i < t_lists.Length; i++) {
                if (UI::Selectable(t_lists[i], t_selectedList == t_lists[i])){
                    t_selectedList = t_lists[i];
                    Reload();
                }
            }
            UI::EndCombo();
        }
#if DEPENDENCY_NADEOSERVICES
        if (t_selectedList == "Favorites") {
            if (MXNadeoServicesGlobal::APIRefresh) {
                UI::SameLine();
                UI::Text("\\$850"+Icons::Refresh + " Now refreshing favorite maps list...");
                Reload();
            }
            UI::SameLine();
            UI::TextDisabled(Icons::ExclamationTriangle + " Only maps available on TMX are displayed");
            UI::SetPreviousTooltip("All favorite maps are displayed in game via the Local menu or via the Openplanet overlay");
        }
#endif
        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 40, UI::GetCursorPos().y));
        if (UI::Button(Icons::Refresh)) Reload();
    }
}