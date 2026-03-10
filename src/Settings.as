// General

[Setting name="Show menu" category="General"]
bool Setting_ShowMenu = false;

[Setting name="Hide Openplanet overlay when loading a map" category="General"]
bool Setting_CloseOverlayOnLoad = true;

[Setting name="Show Play Button on all map types" category="General" description="If you try to load other maps than supported types, the game will crash or return you to the main menu."]
bool Setting_ShowPlayOnAllMaps = false;

[Setting name="Show/Hide window hotkey" category="General" description="Hotkey to show / hide the ManiaExchange window"]
VirtualKey Setting_WindowHotkey;

// Tabs

[Setting name="Your profile (Your user ID)" category="Tabs" description="Set your (or any other) User ID here to get your profile tab" min=0]
int Setting_Tab_YourProfile_UserID = 0;

int Tab_YourProfile_UserID_Old = 0;

[Setting name="Most Awarded" category="Tabs"]
bool Setting_Tab_MostAwarded_Visible = true;

[Setting name="Featured" category="Tabs"]
bool Setting_Tab_Featured_Visible = true;

#if TMNEXT
[Setting name="TOTDs" category="Tabs"]
#endif
bool Setting_Tab_TOTD_Visible = false;

[Setting name="Personal Lists" category="Tabs"]
bool Setting_Tab_PersonalLists_Visible = true;

[Setting name="Users" category="Tabs"]
bool Setting_Tab_Users_Visible = true;

[Setting name="Map Packs" category="Tabs"]
bool Setting_Tab_MapPacks_Visible = true;

[Setting name="Maps" category="Tabs"]
bool Setting_Tab_Maps_Visible = true;

enum MP4mxRepos {
    Trackmania,
    Shootmania
}

[Setting hidden]
MP4mxRepos repo = MP4mxRepos::Trackmania;

#if MP4
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

[SettingsTab name="Favorites" icon="Star" order=3]
void RenderNadeoServicesSettings()
{
    if (UI::Button("Reset to default")) {
        Setting_FavoritesRefreshDelay = 60;
        Setting_FavoritesSort = FavoritesSorting::Date;
        Setting_FavoritesSortOrder = FavoritesSortOrder::Descending;

        if (!TM::APIRefresh && !TM::APIDown) {
            startnew(TM::ReloadFavorites);    
        }
    }

    UI::BeginDisabled(TM::APIRefresh || TM::APIDown);

    if (UI::OrangeButton(Icons::Refresh + " Refresh favorite maps")) {
        startnew(TM::ReloadFavorites);
    }

    UI::EndDisabled();

    UI::SetNextItemWidth(200);
    Setting_FavoritesRefreshDelay = UI::SliderInt("Favorites refresh delay (in minutes)", Setting_FavoritesRefreshDelay, 10, 120);

    UI::SetNextItemWidth(200);
    if (UI::BeginCombo("Favorites map list sorting", tostring(Setting_FavoritesSort))) {
        for (int i = 0; i < 2; i++) {
            if (UI::Selectable(tostring(FavoritesSorting(i)), Setting_FavoritesSort == FavoritesSorting(i))) {
                Setting_FavoritesSort = FavoritesSorting(i);
                startnew(TM::SortFavorites);
            }
        }
        UI::EndCombo();
    }

    UI::SetNextItemWidth(200);
    if (UI::BeginCombo("Favorites map list sorting order", tostring(Setting_FavoritesSortOrder))) {
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

    UI::SetNextItemWidth(175);
    if (UI::BeginCombo("Log level", tostring(Setting_LogLevel))) {
        for (int i = 0; i <= LogLevel::Trace; i++) {
            if (UI::Selectable(tostring(LogLevel(i)), Setting_LogLevel == LogLevel(i))) {
                Setting_LogLevel = LogLevel(i);
            }
        }
        UI::EndCombo();
    }
}

// Display

[Setting hidden]
bool Setting_ColoredMapName = true;

[Setting hidden]
bool Setting_ColoredTags = true;

[Setting hidden]
bool Setting_MapName = true;

[Setting hidden]
bool Setting_MapAuthor = true;

[Setting hidden]
#if MP4
bool Setting_MapEnvironment = true;
#else
bool Setting_MapEnvironment = false;
#endif

[Setting hidden]
#if MP4
bool Setting_MapVehicle = true;
#else
bool Setting_MapVehicle = false;
#endif

#if MP4
[Setting hidden]
bool Setting_MapTitlepack = true;
#else
bool Setting_MapTitlepack = false;
#endif

[Setting hidden]
bool Setting_MapTags = true;

[Setting hidden]
bool Setting_MapLength = false;

[Setting hidden]
bool Setting_MapType = false;

[Setting hidden]
bool Setting_MapDifficulty = false;

[Setting hidden]
bool Setting_MapAwards = true;

[Setting hidden]
bool Setting_MapRecordCount = true;

[Setting hidden]
bool Setting_MapAtStatus = true;

// Mappack

[Setting hidden]
bool Setting_MappackName = true;

[Setting hidden]
bool Setting_MappackAuthor = true;

[Setting hidden]
bool Setting_MappackType = true;

[Setting hidden]
bool Setting_MappackEnvironment = true;

[Setting hidden]
bool Setting_MappackTags = true;

[Setting hidden]
bool Setting_MappackMapCount = true;

// User

[Setting hidden]
bool Setting_UserName = true;

[Setting hidden]
bool Setting_UserRegisterDate = true;

[Setting hidden]
bool Setting_UserMapCount = true;

[Setting hidden]
bool Setting_UserMappackCount = true;

[Setting hidden]
bool Setting_UserReplayCount = true;

[Setting hidden]
bool Setting_UserComments = true;

[Setting hidden]
bool Setting_UserAwards = true;

[Setting hidden]
bool Setting_UserFavorites = true;

[Setting hidden]
bool Setting_UserAchievements = true;

[SettingsTab name="Display" order="3" icon="Eye"]
void RenderDisplaySettings() {
    UI::BeginChild("DisplaySettings");

    if (UI::Button("Reset to default")) {
        Setting_ColoredMapName = true;
        Setting_ColoredTags = true;

        Setting_MapName = true;
        Setting_MapAuthor = true;
#if MP4
        Setting_MapEnvironment = true;
        Setting_MapVehicle = true;
        Setting_MapTitlepack = true;
#else
        Setting_MapEnvironment = false;
        Setting_MapVehicle = false;
        Setting_MapTitlepack = false;
#endif
        Setting_MapType = false;
        Setting_MapTags = true;
        Setting_MapLength = false;
        Setting_MapDifficulty = false;
        Setting_MapAwards = true;
        Setting_MapRecordCount = true;
        Setting_MapAtStatus = true;

        Setting_MappackName = true;
        Setting_MappackAuthor = true;
        Setting_MappackType = true;
        Setting_MappackEnvironment = true;
        Setting_MappackTags = true;
        Setting_MappackMapCount = true;

        Setting_UserName = true;
        Setting_UserRegisterDate = true;
        Setting_UserMapCount = true;
        Setting_UserMappackCount = true;
        Setting_UserReplayCount = true;
        Setting_UserComments = true;
        Setting_UserAwards = true;
        Setting_UserFavorites = true;
        Setting_UserAchievements = true;
    }

    Setting_ColoredTags = UI::Checkbox("Use TMX colors for tags", Setting_ColoredTags);
    UI::SettingDescription("When disabled, tags will use the default gray background color instead of the colors provided by TMX");

    UI::PaddedHeaderSeparator("Maps");

    Setting_ColoredMapName = UI::Checkbox("Use colored map names", Setting_ColoredMapName);

    array<bool> mapValues = { 
        Setting_MapName,
        Setting_MapAuthor,
        Setting_MapEnvironment,
        Setting_MapVehicle,
        Setting_MapTags,
#if MP4
        Setting_MapTitlepack,
#endif
        Setting_MapAwards,
        Setting_MapAtStatus,
        Setting_MapLength,
        Setting_MapType,
        Setting_MapRecordCount,
        Setting_MapDifficulty
    };
    string mapComboText = GetComboText(mapValues);

    UI::SetNextItemWidth(175);
    if (UI::BeginCombo("Displayed columns##Map", mapComboText)) {
        Setting_MapName = UI::Checkbox("Name##Map", Setting_MapName);
        Setting_MapAuthor = UI::Checkbox("Author##Map", Setting_MapAuthor);
#if MP4
        Setting_MapEnvironment = UI::Checkbox("Environment##Map", Setting_MapEnvironment);
#else
        Setting_MapEnvironment = UI::Checkbox("Vista##Map", Setting_MapEnvironment);
#endif
        Setting_MapVehicle = UI::Checkbox("Vehicle##Map", Setting_MapVehicle);
        Setting_MapType = UI::Checkbox("Type##Map", Setting_MapType);
#if MP4
        Setting_MapTitlepack = UI::Checkbox("Titlepack##Map", Setting_MapTitlepack);
#endif
        Setting_MapTags = UI::Checkbox("Tags##Map", Setting_MapTags);
        Setting_MapLength = UI::Checkbox("Length##Map", Setting_MapLength);
        Setting_MapDifficulty = UI::Checkbox("Difficulty##Map", Setting_MapDifficulty);
        Setting_MapAwards = UI::Checkbox("Awards##Map", Setting_MapAwards);
#if TMNEXT
        Setting_MapRecordCount = UI::Checkbox("Record Count##Map", Setting_MapRecordCount);
#else
        Setting_MapRecordCount = UI::Checkbox("Replay Count##Map", Setting_MapRecordCount);
#endif
        Setting_MapAtStatus = UI::Checkbox("AT Status##Map", Setting_MapAtStatus);

        UI::EndCombo();
    }

    UI::PaddedHeaderSeparator("Mappacks");

    array<bool> mappackValues = { 
        Setting_MappackName,
        Setting_MappackAuthor,
        Setting_MappackType,
        Setting_MappackEnvironment,
        Setting_MappackTags,
        Setting_MappackMapCount
    };
    string mappackComboText = GetComboText(mappackValues);

    UI::SetNextItemWidth(175);
    if (UI::BeginCombo("Displayed columns##Mappack", mappackComboText)) {
        Setting_MappackName = UI::Checkbox("Name##Mappack", Setting_MappackName);
        Setting_MappackAuthor = UI::Checkbox("Author##Mappack", Setting_MappackAuthor);
        Setting_MappackType = UI::Checkbox("Type##Mappack", Setting_MappackType);
#if TMNEXT
        Setting_MappackEnvironment = UI::Checkbox("Vista##Mappack", Setting_MappackEnvironment);
#else
        Setting_MappackEnvironment = UI::Checkbox("Environment##Mappack", Setting_MappackEnvironment);
#endif
        Setting_MappackTags = UI::Checkbox("Tags##Mappack", Setting_MappackTags);
        Setting_MappackMapCount = UI::Checkbox("Map Count##Mappack", Setting_MappackMapCount);

        UI::EndCombo();
    }

    UI::PaddedHeaderSeparator("Users");

    array<bool> userValues = {
        Setting_UserName,
        Setting_UserRegisterDate,
        Setting_UserMapCount,
        Setting_UserMappackCount,
        Setting_UserReplayCount,
        Setting_UserComments,
        Setting_UserAwards,
        Setting_UserFavorites,
        Setting_UserAchievements
    };
    string userComboText = GetComboText(userValues);

    UI::SetNextItemWidth(175);
    if (UI::BeginCombo("Displayed columns##User", userComboText)) {
        Setting_UserName = UI::Checkbox("Name##User", Setting_UserName);
        Setting_UserRegisterDate = UI::Checkbox("Register at##User", Setting_UserRegisterDate);
        Setting_UserMapCount = UI::Checkbox("Map Count##User", Setting_UserMapCount);
        Setting_UserMappackCount = UI::Checkbox("Mappack Count##User", Setting_UserMappackCount);
        Setting_UserReplayCount = UI::Checkbox("Replay Count##User", Setting_UserReplayCount);
        Setting_UserComments = UI::Checkbox("Comments##User", Setting_UserComments);
        Setting_UserAwards = UI::Checkbox("Awards##User", Setting_UserAwards);
        Setting_UserFavorites = UI::Checkbox("Favorites##User", Setting_UserFavorites);
        Setting_UserAchievements = UI::Checkbox("Achievements##User", Setting_UserAchievements);

        UI::EndCombo();
    }

    UI::EndChild();
}
