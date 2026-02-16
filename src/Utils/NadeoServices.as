namespace MXNadeoServicesGlobal
{
    bool APIDown;
    bool APIRefresh;
    array<NadeoServices::MapInfo@> g_favoriteMaps;
    dictionary checkedMaps;
    bool g_fetchedFavorites;

    bool get_FetchedFavorites() {
        return g_fetchedFavorites;
    }

#if DEPENDENCY_NADEOSERVICES
    void LoadNadeoServices()
    {
        try {
            APIRefresh = true;

            CheckAuthentication();

            APIRefresh = false;
            APIDown = false;
        } catch {
            Logging::Error("Failed to load NadeoServices: " + getExceptionInfo());
            APIDown = true;
        }
    }

    void CheckAuthentication()
    {
        NadeoServices::AddAudience("NadeoLiveServices");
        NadeoServices::AddAudience("NadeoServices");
        while (!NadeoServices::IsAuthenticated("NadeoLiveServices") || !NadeoServices::IsAuthenticated("NadeoServices")) {
            yield();
        }
        Logging::Debug("NadeoServices audiences authenticated");
    }

    void GetFavoriteMapsAsync()
    {
        if (FetchedFavorites) {
            return;
        }

        g_fetchedFavorites = true;

        Logging::Info("[GetFavoriteMapsAsync] Loading Favorite tracks...");

        try {
            auto app = cast<CGameManiaPlanet>(GetApp());
            auto menu = app.MenuManager.MenuCustom_CurrentManiaApp;
            MwId userId = menu.UserMgr.Users[0].Id;
            auto res = menu.DataFileMgr.Map_NadeoServices_GetFavoriteList(userId, MwFastBuffer<wstring>(), true, false, true, false);

            while (res.IsProcessing) {
                yield();
            }

            if (!res.HasSucceeded || res.HasFailed) {
                Logging::Error("[GetFavoriteMapsAsync] Failed to get favorite maps", true);
                Logging::Error("[GetFavoriteMapsAsync] Failed to get favorite maps: Error " + res.ErrorCode + " - " + res.ErrorDescription);
                menu.DataFileMgr.TaskResult_Release(res.Id);
                return;
            }

            Logging::Trace("[GetFavoriteMapsAsync] Found " + res.MapList.Length + " maps in favorites.");

            MwFastBuffer<CNadeoServicesMap@> favoriteMaps = res.MapList;

            array<string> mapUids;

            for (uint i = 0; i < favoriteMaps.Length; i++) {
                CNadeoServicesMap@ nadeoMap = favoriteMaps[i];
                Logging::Trace("[GetFavoriteMapsAsync] Loading favorite map #" + i + ": " + nadeoMap.Name + " (" + nadeoMap.Uid + ")");

                auto map = NadeoServices::MapInfo(nadeoMap);
                map.Position = i;
    
                g_favoriteMaps.InsertLast(map);
                mapUids.InsertLast(map.Uid);
            }

            menu.DataFileMgr.TaskResult_Release(res.Id);

            Logging::Debug("[GetFavoriteMapsAsync] Loaded " + favoriteMaps.Length + " favorites.");

            if (g_favoriteMaps.IsEmpty()) return;

            Logging::Debug("[GetFavoriteMapsAsync] Checking for favorite maps on MX...");

            array<array<string>> uidChunks = Chunks(mapUids, MX::maxMapsRequest);

            foreach (array<string> currentChunk : uidChunks) {
                // we do + 10 in case multiple maps have the same UID, which can happen
                string reqUrl = MXURL + "/api/maps?fields=" + MX::mapFields + "&count=" + (MX::maxMapsRequest + 10) + "&uid=" + string::Join(currentChunk, ",");

                Logging::Debug("[GetFavoriteMapsAsync] Loading map MX infos: " + reqUrl);

                Net::HttpRequest@ mxReq = API::Get(reqUrl);

                while (!mxReq.Finished()) {
                    yield();
                }

                Logging::Debug("[GetFavoriteMapsAsync] Map MX info response: " + mxReq.String());

                auto mxJson = mxReq.Json();

                if (mxReq.ResponseCode() >= 400 || mxJson.GetType() == Json::Type::Null || !mxJson.HasKey("Results")) {
                    Logging::Error("[GetFavoriteMapsAsync] Invalid MX map info response");
                    continue;
                }

                Json::Value mapResults = mxJson["Results"];
                array<string> foundUids;

                for (uint i = 0; i < mapResults.Length; i++) {
                    Logging::Trace("[GetFavoriteMapsAsync] Loading map MX info " + currentChunk[i]);

                    string resMapUid = mapResults[i]["MapUid"];
                    foundUids.InsertLast(resMapUid);

                    for (uint u = 0; u < g_favoriteMaps.Length; u++) {
                        if (resMapUid == g_favoriteMaps[u].Uid) {
                            @g_favoriteMaps[u].MXMapInfo = MX::MapInfo(mapResults[i]);
                            break;
                        }
                    }
                }

                for (uint f = 0; f < currentChunk.Length; f++) {
                    if (foundUids.Find(currentChunk[f]) == -1) {
                        Logging::Trace("[GetFavoriteMapsAsync] Failed to find map with UID " + currentChunk[f] + " on MX. The map will be ignored");
                    }
                }

                sleep(1000);
            }

            array<string> accountIds;

            for (uint i = 0; i < g_favoriteMaps.Length; i++) {
                if (g_favoriteMaps[i].Author != "" && g_favoriteMaps[i].Author != "Unknown") {
                    continue;
                }

                if (g_favoriteMaps[i].MXMapInfo !is null) {
                    g_favoriteMaps[i].Author = g_favoriteMaps[i].MXMapInfo.Username;
                    continue;
                }

                accountIds.InsertLast(g_favoriteMaps[i].AuthorId);
            }

            if (!accountIds.IsEmpty()) {
                Logging::Trace("[GetFavoriteMapsAsync] Fetching " + accountIds.Length + " missing account names.");

                dictionary displayNames = NadeoServices::GetDisplayNamesAsync(accountIds);

                for (uint i = 0; i < g_favoriteMaps.Length; i++) {
                    string name;

                    if (displayNames.Get(g_favoriteMaps[i].AuthorId, name)) {
                        g_favoriteMaps[i].Author = name;
                    }
                }
            }

            SortFavorites();

            Logging::Info("[GetFavoriteMapsAsync] Loaded " + g_favoriteMaps.Length + " favorite maps.");
        } catch {
            Logging::Error("[GetFavoriteMapsAsync] Failed to load favorite maps: " + getExceptionInfo(), true);
        }
    }

    void ReloadFavoriteMapsAsync() {
        try {
            MXNadeoServicesGlobal::APIRefresh = true;
            if (g_favoriteMaps.Length > 0) g_favoriteMaps.RemoveRange(0, g_favoriteMaps.Length);
            g_fetchedFavorites = false;
            GetFavoriteMapsAsync();
            MXNadeoServicesGlobal::APIRefresh = false;
        } catch {
            Logging::Error("[ReloadFavoriteMapsAsync] Error reloading favorite maps: " + getExceptionInfo());
            MXNadeoServicesGlobal::APIRefresh = false;
        }
    }

    void RefreshFavoriteMapsLoop() {
        if (g_favoriteMaps.Length > 0) {
            g_favoriteMaps.RemoveRange(0, g_favoriteMaps.Length);
        }

        GetFavoriteMapsAsync();

        while (true) {
            sleep(Setting_FavoritesRefreshDelay * 60 * 1000);
            Logging::Debug('Refreshing favorite maps...');
            ReloadFavoriteMapsAsync();
        }
    }

    bool CheckIfMapExistsAsync(const string &in mapUid)
    {
        if (checkedMaps.Exists(mapUid)) {
            return bool(checkedMaps[mapUid]);
        }

        NadeoServices::MapInfo@ map = GetMapInfoAsync(mapUid);

        if (map is null) {
            checkedMaps.Set(mapUid, false);
            return false;
        }

        try {
            checkedMaps.Set(map.Uid, map.Uid == mapUid);
            return map.Uid == mapUid;
        } catch {
            checkedMaps.Set(mapUid, false);
            return false;
        }
    }

    NadeoServices::MapInfo@ GetMapInfoAsync(const string &in mapUid)
    {
        Logging::Debug("[GetMapInfoAsync] Getting map information for UID " + mapUid);

        auto app = cast<CGameManiaPlanet>(GetApp());
        auto menu = app.MenuManager.MenuCustom_CurrentManiaApp;
        MwId userId = menu.UserMgr.Users[0].Id;
        auto res = menu.DataFileMgr.Map_NadeoServices_GetFromUid(userId, mapUid);

        while (res.IsProcessing) {
            yield();
        }

        if (!res.HasSucceeded || res.HasFailed || res.Map is null) {
            Logging::Error("[GetMapInfoAsync] Failed to get favorite maps: Error " + res.ErrorCode + " - " + res.ErrorDescription);
            menu.DataFileMgr.TaskResult_Release(res.Id);
            return null;
        }

        auto mapInfo = NadeoServices::MapInfo(res.Map);
        menu.DataFileMgr.TaskResult_Release(res.Id);

        return mapInfo;
    }

    void AddMapToFavoritesAsync(ref@ mapData)
    {
        MX::MapInfo@ map = cast<MX::MapInfo>(mapData);

        string url = NadeoServices::BaseURLLive() + "/api/token/map/favorite/" + map.MapUid + "/add";
        Logging::Debug("[AddMapToFavoritesAsync] URL: " + url);

        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", url);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        if (req.ResponseCode() >= 400) {
            auto res = req.Json();

            if (res.GetType() != Json::Type::Array) {
                Logging::Error("[AddMapToFavoritesAsync] Error adding map to favorites: " + req.String());
            } else {
                Logging::Error("[AddMapToFavoritesAsync] Error adding map to favorites: Failed to find a map with UID " + map.MapUid);
            }
        } else {
            Logging::Debug("[AddMapToFavoritesAsync] Succesfully added map with UID " + map.MapUid + " to your favorites");
            startnew(MXNadeoServicesGlobal::ReloadFavoriteMapsAsync);
        }
    }

    void RemoveMapFromFavoritesAsync(ref@ mapData)
    {
        NadeoServices::MapInfo@ map = cast<NadeoServices::MapInfo>(mapData);

        string url = NadeoServices::BaseURLLive() + "/api/token/map/favorite/" + map.Uid + "/remove";
        Logging::Debug("[RemoveMapFromFavoritesAsync] URL: " + url);

        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", url);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        if (req.ResponseCode() >= 400) {
            auto res = req.Json();

            if (res.GetType() != Json::Type::Array) {
                Logging::Error("[RemoveMapFromFavoritesAsync] Error removing map from favorites: " + req.String());
            } else {
                string errorText = res[0];
                if (errorText == "map:error-notFound") {
                    Logging::Error("[RemoveMapFromFavoritesAsync] Error removing map from favorites: Failed to find a map with UID " + map.Uid);
                } else {
                    Logging::Error("[RemoveMapFromFavoritesAsync] Error removing map from favorites: A map with UID" + map.Uid + " doesn't exist in your favorites");
                }
            }
        } else {
            Logging::Debug("[RemoveMapFromFavoritesAsync] Succesfully removed map with UID " + map.Uid + " from favorites");
            UI::ShowNotification(Text::OpenplanetFormatCodes(map.Name) + "\\$z by " + map.Author + " has been removed from your favorites!");

            for (uint i = 0; i < g_favoriteMaps.Length; i++) {
                if (g_favoriteMaps[i] == map) {
                    g_favoriteMaps.RemoveAt(i);
                    break;
                }
            }
        }
    }

    void SortFavorites() {
        if (g_favoriteMaps.Length < 2) {
            return;
        }

        switch (Setting_FavoritesSort){
            case FavoritesSorting::Date:
                if (Setting_FavoritesSortOrder == FavoritesSortOrder::Ascending) {
                    g_favoriteMaps.Sort(function(a, b) { 
                        return a.Position > b.Position;
                    });
                } else {
                    g_favoriteMaps.Sort(function(a, b) { 
                        return a.Position < b.Position;
                    });
                }

                break;

            case FavoritesSorting::Name:
                if (Setting_FavoritesSortOrder == FavoritesSortOrder::Ascending) {
                    g_favoriteMaps.Sort(function(a, b) { 
                        return a.Name > b.Name;
                    });
                } else {
                    g_favoriteMaps.Sort(function(a, b) { 
                        return a.Name < b.Name;
                    });
                }

                break;

            default:
                break;
        }
    }
#endif
}