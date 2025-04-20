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
#if DEPENDENCY_NADEOSERVICES
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

        if (t_selectedList == "Favorites") {
            UI::SameLine();
            UI::Text("| Sorting:");
            UI::SameLine();
            UI::BeginDisabled(MXNadeoServicesGlobal::APIRefresh);
            UI::SetNextItemWidth(90);
            if (UI::BeginCombo("##FavoritesSorting", tostring(Setting_NadeoServices_FavoriteMaps_Sort))) {
                for (int i = 0; i < 2; i++) {
                    if (UI::Selectable(tostring(NadeoServicesFavoriteMapListSort(i)), false)) {
                        Setting_NadeoServices_FavoriteMaps_Sort = NadeoServicesFavoriteMapListSort(i);
                        startnew(MXNadeoServicesGlobal::ReloadFavoriteMapsAsync);
                    }
                }
                UI::EndCombo();
            }
            UI::SameLine();
            UI::SetNextItemWidth(120);
            if (UI::BeginCombo("##FavoritesSortingOrder", tostring(Setting_NadeoServices_FavoriteMaps_SortOrder))) {
                for (int i = 0; i < 2; i++) {
                    if (UI::Selectable(tostring(NadeoServicesFavoriteMapListSortOrder(i)), false)) {
                        Setting_NadeoServices_FavoriteMaps_SortOrder = NadeoServicesFavoriteMapListSortOrder(i);
                        startnew(MXNadeoServicesGlobal::ReloadFavoriteMapsAsync);
                    }
                }
                UI::EndCombo();
            }
            UI::EndDisabled();
            if (MXNadeoServicesGlobal::APIRefresh) {
                UI::SameLine();
                UI::Text("\\$850"+Icons::Refresh + " Now refreshing favorite maps list... \\$z|");
                Reload();
            }
            UI::SameLine();
            UI::TextDisabled(Icons::ExclamationTriangle + " Only maps available on TMX are displayed");
            UI::SetItemTooltip("All favorite maps are displayed in game via the Local menu or via the Openplanet overlay");

            UI::SameLine();
            UI::SetCursorPos(vec2(UI::GetWindowSize().x - 40, UI::GetCursorPos().y));

            UI::BeginDisabled(MXNadeoServicesGlobal::APIRefresh);

            if (UI::Button(Icons::Refresh)) {
                startnew(MXNadeoServicesGlobal::ReloadFavoriteMapsAsync);
                Reload();
            }

            UI::EndDisabled();
        }
#endif

        if (t_selectedList == "Play later") {
            UI::SameLine();
            UI::SetCursorPos(vec2(UI::GetWindowSize().x - 120, UI::GetCursorPos().y));

            UI::BeginDisabled(g_PlayLaterMaps.Length == 0);

            if (UI::RedButton(Icons::TrashO + " Clear")) {
                Renderables::Add(ClearPlayLaterListWarn());
            }

            UI::EndDisabled();

            if (maps.Length != g_PlayLaterMaps.Length) Reload();

            UI::SameLine();

            if (UI::Button(Icons::Refresh)) {
                Reload();
            }
        }
    }
}