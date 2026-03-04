[Setting name="Show menu" category="UI"]
bool Setting_ShowMenu = false;

[Setting name="Use colored map name" category="UI"]
bool Setting_ColoredMapName = true;

[Setting name="Hide Openplanet overlay when loading a map" category="UI"]
bool Setting_CloseOverlayOnLoad = true;

[Setting name="Show Play Button on all map types" category="UI" description="If you try to load other maps than supported types, the game will crash or return you to the main menu."]
bool Setting_ShowPlayOnAllMaps = false;

[Setting name="Colored tags" category="UI" description="When disabled, style tags will use the default gray background color instead of the colors provided by MX"]
bool Setting_ColoredTags = true;

[Setting name="Show/Hide window hotkey" category="UI" description="Hotkey to show / hide the ManiaExchange window"]
VirtualKey Setting_WindowHotkey;

// Tabs

[Setting name="Your profile (Your user ID)" category="Display Tabs" description="Set your (or any other) User ID here to get your profile tab" min=0]
int Setting_Tab_YourProfile_UserID = 0;

int Tab_YourProfile_UserID_Old = 0;

[Setting name="Most Awarded" category="Display Tabs"]
bool Setting_Tab_MostAwarded_Visible = true;

[Setting name="Featured" category="Display Tabs"]
bool Setting_Tab_Featured_Visible = true;

#if TMNEXT
[Setting name="TOTDs" category="Display Tabs"]
#endif
bool Setting_Tab_TOTD_Visible = false;

[Setting name="Personal Lists" category="Display Tabs"]
bool Setting_Tab_PersonalLists_Visible = true;

[Setting name="Users" category="Display Tabs"]
bool Setting_Tab_Users_Visible = true;

[Setting name="Map Packs" category="Display Tabs"]
bool Setting_Tab_MapPacks_Visible = true;

[Setting name="Maps" category="Display Tabs"]
bool Setting_Tab_Maps_Visible = true;

#if MP4
enum MP4mxRepos {
    Trackmania,
    Shootmania
}

[Setting hidden]
MP4mxRepos repo = MP4mxRepos::Trackmania;

[SettingsTab name="ManiaPlanet 4" icon="ManiaExchange" order=3]
void RenderMP4RepoSelectSettings()
{
    if (UI::BeginCombo("Repository for maps", tostring(repo))) {
        for (int i = 0; i < 2; i++) {
            if (UI::Selectable(tostring(MP4mxRepos(i)), repo == MP4mxRepos(i))) {
                if (repo != MP4mxRepos(i)) {
                    repo = MP4mxRepos(i);

                    if (repo == MP4mxRepos::Trackmania) MXURL = "https://tm.mania.exchange";
                    else if (repo == MP4mxRepos::Shootmania) MXURL = "https://sm.mania.exchange";
                    Logging::Info("Changed repository to " + tostring(repo) + " (" + MXURL + "), reloading...");
                    startnew(MX::CheckForAPILoaded);

                    for (uint t = 0; t < mxMenu.tabs.Length; t++) {
                        if (mxMenu.tabs[t] !is null) {
                            mxMenu.tabs[t].Reload();
                        }
                    }
                }
            }
        }
        UI::EndCombo();
    }
}
#endif

#if DEPENDENCY_NADEOSERVICES

enum FavoritesSorting {
    Date,
    Name
}

enum FavoritesSortOrder {
    Ascending,
    Descending
}

[Setting hidden]
int Setting_FavoritesRefreshDelay = 60;

[Setting hidden]
FavoritesSorting Setting_FavoritesSort = FavoritesSorting::Date;

[Setting hidden]
FavoritesSortOrder Setting_FavoritesSortOrder = FavoritesSortOrder::Descending;

[SettingsTab name="Favorite Maps" icon="Star" order=3]
void RenderNadeoServicesSettings()
{
    if (UI::Button(Icons::Refresh + " Refresh Favorite Maps")) {
        startnew(TM::ReloadFavorites);
    }

    Setting_FavoritesRefreshDelay = UI::SliderInt("Favorites refresh delay (in minutes)", Setting_FavoritesRefreshDelay, 10, 120);

    if (UI::BeginCombo("Favorites map list Sorting", tostring(Setting_FavoritesSort))) {
        for (int i = 0; i < 2; i++) {
            if (UI::Selectable(tostring(FavoritesSorting(i)), Setting_FavoritesSort == FavoritesSorting(i))) {
                Setting_FavoritesSort = FavoritesSorting(i);
                startnew(TM::SortFavorites);
            }
        }
        UI::EndCombo();
    }

    if (UI::BeginCombo("Favorites map list Sorting Order", tostring(Setting_FavoritesSortOrder))) {
        for (int i = 0; i < 2; i++) {
            if (UI::Selectable(tostring(FavoritesSortOrder(i)), Setting_FavoritesSortOrder == FavoritesSortOrder(i))) {
                Setting_FavoritesSortOrder = FavoritesSortOrder(i);
                startnew(TM::SortFavorites);
            }
        }
        UI::EndCombo();
    }
}
#endif

[Setting hidden]
LogLevel Setting_LogLevel = LogLevel::Info;

[SettingsTab name="Dev" order=4]
void RenderDevSettings()
{
    if (UI::Button("Reset to default")) {
        Setting_LogLevel = LogLevel::Info;
    }

    if (UI::BeginCombo("Log level", tostring(Setting_LogLevel))) {
        for (int i = 0; i <= LogLevel::Trace; i++) {
            if (UI::Selectable(tostring(LogLevel(i)), Setting_LogLevel == LogLevel(i))) {
                Setting_LogLevel = LogLevel(i);
            }
        }
        UI::EndCombo();
    }
}
