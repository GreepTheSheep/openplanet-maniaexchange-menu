[Setting name="Show menu" category="UI"]
bool Setting_ShowMenu = false;

[Setting name="Use colored map name" category="UI"]
bool Setting_ColoredMapName = true;

[Setting name="Close Openplanet overlay when loading a map" category="UI"]
bool Setting_CloseOverlayOnLoad = true;

[Setting name="Show Play Button on all map types" category="UI" description="If you try to load other maps than supported types, the game will crash or return you to the main menu."]
bool Setting_ShowPlayOnAllMaps = false;

[Setting name="Limit count for embedded objects" category="UI" min=0 max=75 description="Limit the count of embedded objects in the map info tab. A high value can make a lot of requests to the server, so it is recommended to keep this value as low as possible."]
int Setting_EmbeddedObjectsLimit = 25;

// Tabs

[Setting name="Your profile (Your user ID)" category="Display Tabs" description="Set your (or any other) User ID here to get your profile tab" min=0]
int Setting_Tab_YourProfile_UserID = 0;

int Tab_YourProfile_UserID_Old = 0;

[Setting name="Most Awarded" category="Display Tabs"]
bool Setting_Tab_MostAwarded_Visible = true;

[Setting name="Featured" category="Display Tabs"]
bool Setting_Tab_Featured_Visible = true;

[Setting name="Tags" category="Display Tabs"]
bool Setting_Tab_Tags_Visible = true;

[Setting name="Latest" category="Display Tabs"]
bool Setting_Tab_Latest_Visible = true;

[Setting name="Recently Awarded" category="Display Tabs"]
bool Setting_Tab_RecentlyAwarded_Visible = false;

#if TMNEXT
[Setting name="TOTDs" category="Display Tabs"]
#endif
bool Setting_Tab_TOTD_Visible = false;

[Setting name="Search" category="Display Tabs"]
bool Setting_Tab_Search_Visible = true;

[Setting name="Map Packs" category="Display Tabs"]
bool Setting_Tab_MapPacks_Visible = true;

#if MP4
enum MP4mxRepos {
    Trackmania,
    Shootmania
}

[Setting hidden]
MP4mxRepos repo = MP4mxRepos::Trackmania;

[SettingsTab name="ManiaPlanet 4"]
void RenderMP4RepoSelectSettings()
{
    if (UI::BeginCombo("Repository for maps", tostring(repo))) {
        for (int i = 0; i < 2; i++) {
            if (UI::Selectable(tostring(MP4mxRepos(i)), false)) {
                repo = MP4mxRepos(i);
                if (repo == MP4mxRepos::Trackmania) MXURL = "tm.mania.exchange";
                else if (repo == MP4mxRepos::Shootmania) MXURL = "sm.mania.exchange";
                print("Changed repository to " + repo + " (" + MXURL + "), reloading tags...");
                startnew(MX::CheckForAPILoaded);

                for (uint i = 0; i < mxMenu.tabs.Length; i++) {
                    if (mxMenu.tabs[i] !is null) {
                        mxMenu.tabs[i].Reload();
                    }
                }
            }
        }
        UI::EndCombo();
    }
}
#endif

#if DEPENDENCY_NADEOSERVICES

enum NadeoServicesFavoriteMapListSort {
    Date,
    Name
}

enum NadeoServicesFavoriteMapListSortOrder {
    Ascending,
    Descending
}

[Setting hidden]
int Setting_NadeoServices_FavoriteMaps_RefreshDelay = 30;

[Setting hidden]
NadeoServicesFavoriteMapListSort Setting_NadeoServices_FavoriteMaps_Sort = NadeoServicesFavoriteMapListSort::Date;

[Setting hidden]
NadeoServicesFavoriteMapListSortOrder Setting_NadeoServices_FavoriteMaps_SortOrder = NadeoServicesFavoriteMapListSortOrder::Descending;

[SettingsTab name="Favorite Maps"]
void RenderNadeoServicesSettings()
{
    if (UI::Button(Icons::Refresh + " Refresh Favorite Maps")) {
        startnew(MXNadeoServicesGlobal::ReloadFavoriteMapsAsync);
        for (uint i = 0; i < mxMenu.tabs.Length; i++) {
            if (mxMenu.tabs[i] !is null) {
                mxMenu.tabs[i].Reload();
            }
        }
    }
    Setting_NadeoServices_FavoriteMaps_RefreshDelay = UI::SliderInt("Favorite Maps refresh delay (in minutes)", Setting_NadeoServices_FavoriteMaps_RefreshDelay, 10, 60);

    if (UI::BeginCombo("Favorites map list Sorting", tostring(Setting_NadeoServices_FavoriteMaps_Sort))) {
        for (int i = 0; i < 2; i++) {
            if (UI::Selectable(tostring(NadeoServicesFavoriteMapListSort(i)), false)) {
                Setting_NadeoServices_FavoriteMaps_Sort = NadeoServicesFavoriteMapListSort(i);
                startnew(MXNadeoServicesGlobal::ReloadFavoriteMapsAsync);
            }
        }
        UI::EndCombo();
    }

    if (UI::BeginCombo("Favorites map list Sorting Order", tostring(Setting_NadeoServices_FavoriteMaps_SortOrder))) {
        for (int i = 0; i < 2; i++) {
            if (UI::Selectable(tostring(NadeoServicesFavoriteMapListSortOrder(i)), false)) {
                Setting_NadeoServices_FavoriteMaps_SortOrder = NadeoServicesFavoriteMapListSortOrder(i);
                startnew(MXNadeoServicesGlobal::ReloadFavoriteMapsAsync);
            }
        }
        UI::EndCombo();
    }
}
#endif