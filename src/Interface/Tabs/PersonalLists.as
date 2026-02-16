enum ListTypes {
#if DEPENDENCY_NADEOSERVICES
    Favorites,
#endif
    Play_Later,
    _Last
}

class PersonalListsTab : MapListTab
{
    ListTypes t_selectedList = ListTypes(0);

    bool IsVisible() override  { return Setting_Tab_PersonalLists_Visible; }
    string GetLabel() override { return Icons::List + " Personal Lists"; }
    vec4 GetColor() override   { return vec4(0.58f, 0.1f, 0.79f, 1); }

    void GetRequestParams(dictionary@ params) override {}

    void StartRequest() override
    {
        switch (t_selectedList) {
#if DEPENDENCY_NADEOSERVICES
            case ListTypes::Favorites:
                for (uint i = 0; i < MXNadeoServicesGlobal::g_favoriteMaps.Length; i++) {
                    if (MXNadeoServicesGlobal::g_favoriteMaps[i].MXMapInfo !is null) {
                        maps.InsertLast(MXNadeoServicesGlobal::g_favoriteMaps[i].MXMapInfo);
                    }
                }

                break;
#endif
            case ListTypes::Play_Later:
            default:
                maps = g_PlayLaterMaps;
                break;
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
        if (UI::BeginCombo("##PersonalListSelect", tostring(t_selectedList).Replace("_", " "))) {
            for (uint i = 0; i < ListTypes::_Last; i++) {
                if (UI::Selectable(tostring(ListTypes(i)).Replace("_", " "), t_selectedList == ListTypes(i))) {
                    t_selectedList = ListTypes(i);
                    Reload();
                }
            }

            UI::EndCombo();
        }

        UI::SameLine();

        if (t_selectedList == ListTypes::Favorites) {
            UI::Text("| Sorting:");

            UI::SameLine();

            UI::BeginDisabled(MXNadeoServicesGlobal::APIRefresh);

            UI::SetNextItemWidth(90);
            if (UI::BeginCombo("##FavoritesSorting", tostring(Setting_FavoritesSort))) {
                for (int i = 0; i < 2; i++) {
                    if (UI::Selectable(tostring(FavoritesSorting(i)), false)) {
                        Setting_FavoritesSort = FavoritesSorting(i);
                        startnew(MXNadeoServicesGlobal::SortFavorites);
                        Reload();
                    }
                }

                UI::EndCombo();
            }

            UI::SameLine();

            UI::SetNextItemWidth(120);
            if (UI::BeginCombo("##FavoritesSortingOrder", tostring(Setting_FavoritesSortOrder))) {
                for (int i = 0; i < 2; i++) {
                    if (UI::Selectable(tostring(FavoritesSortOrder(i)), false)) {
                        Setting_FavoritesSortOrder = FavoritesSortOrder(i);
                        startnew(MXNadeoServicesGlobal::SortFavorites);
                        Reload();
                    }
                }

                UI::EndCombo();
            }

            UI::EndDisabled();

            if (MXNadeoServicesGlobal::APIRefresh) {
                UI::SameLine();
                UI::Text(Icons::AnimatedHourglass + " Refreshing favorites...");
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

        if (t_selectedList == ListTypes::Play_Later) {
            UI::SetCursorPos(vec2(UI::GetWindowSize().x - 120, UI::GetCursorPos().y));

            UI::BeginDisabled(g_PlayLaterMaps.IsEmpty());

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