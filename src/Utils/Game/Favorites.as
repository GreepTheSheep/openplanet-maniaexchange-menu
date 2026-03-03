namespace TM {
    bool APIDown;
    bool APIRefresh;
    array<TM::MapInfo@> g_favoriteMaps;
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

    void GetFavorites() {
        if (FetchedFavorites) {
            return;
        }

        g_fetchedFavorites = true;

        Logging::Info("[GetFavorites] Loading Favorite tracks...");

        try {
            auto app = cast<CGameManiaPlanet>(GetApp());
            auto menu = app.MenuManager.MenuCustom_CurrentManiaApp;
            MwId userId = menu.UserMgr.Users[0].Id;
            auto res = menu.DataFileMgr.Map_NadeoServices_GetFavoriteList(userId, MwFastBuffer<wstring>(), true, false, true, false);

            while (res.IsProcessing) {
                yield();
            }

            if (!res.HasSucceeded || res.HasFailed) {
                Logging::Error("[GetFavorites] Failed to get favorite maps", true);
                Logging::Error("[GetFavorites] Failed to get favorite maps: Error " + res.ErrorCode + " - " + res.ErrorDescription);
                menu.DataFileMgr.TaskResult_Release(res.Id);
                return;
            }

            Logging::Trace("[GetFavorites] Found " + res.MapList.Length + " maps in favorites.");

            MwFastBuffer<CNadeoServicesMap@> favoriteMaps = res.MapList;

            array<string> mapUids;

            for (uint i = 0; i < favoriteMaps.Length; i++) {
                CNadeoServicesMap@ nadeoMap = favoriteMaps[i];
                Logging::Trace("[GetFavorites] Loading favorite map #" + i + ": " + nadeoMap.Name + " (" + nadeoMap.Uid + ")");

                auto map = TM::MapInfo(nadeoMap);
                map.Position = i;
    
                g_favoriteMaps.InsertLast(map);
                mapUids.InsertLast(map.Uid);
            }

            menu.DataFileMgr.TaskResult_Release(res.Id);

            Logging::Debug("[GetFavorites] Loaded " + favoriteMaps.Length + " favorites.");

            if (g_favoriteMaps.IsEmpty()) return;

            Logging::Debug("[GetFavorites] Checking for favorite maps on MX...");

            array<array<string>> uidChunks = Chunks(mapUids, MX::maxMapsRequest);

            foreach (array<string> currentChunk : uidChunks) {
                // we do + 10 in case multiple maps have the same UID, which can happen
                string reqUrl = MXURL + "/api/maps?fields=" + MX::mapFields + "&count=" + (MX::maxMapsRequest + 10) + "&uid=" + string::Join(currentChunk, ",");

                Logging::Debug("[GetFavorites] Loading map MX infos: " + reqUrl);

                Net::HttpRequest@ mxReq = API::Get(reqUrl);

                while (!mxReq.Finished()) {
                    yield();
                }

                Logging::Debug("[GetFavorites] Map MX info response: " + mxReq.String());

                auto mxJson = mxReq.Json();

                if (mxReq.ResponseCode() >= 400 || mxJson.GetType() == Json::Type::Null || !mxJson.HasKey("Results")) {
                    Logging::Error("[GetFavorites] Invalid MX map info response");
                    continue;
                }

                Json::Value mapResults = mxJson["Results"];
                array<string> foundUids;

                for (uint i = 0; i < mapResults.Length; i++) {
                    Logging::Trace("[GetFavorites] Loading map MX info " + currentChunk[i]);

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
                        Logging::Trace("[GetFavorites] Failed to find map with UID " + currentChunk[f] + " on MX. The map will be ignored");
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
                Logging::Trace("[GetFavorites] Fetching " + accountIds.Length + " missing account names.");

                dictionary displayNames = NadeoServices::GetDisplayNamesAsync(accountIds);

                for (uint i = 0; i < g_favoriteMaps.Length; i++) {
                    string name;

                    if (displayNames.Get(g_favoriteMaps[i].AuthorId, name)) {
                        g_favoriteMaps[i].Author = name;
                    }
                }
            }

            SortFavorites();

            Logging::Info("[GetFavorites] Loaded " + g_favoriteMaps.Length + " favorite maps.");
        } catch {
            Logging::Error("[GetFavorites] Failed to load favorite maps: " + getExceptionInfo(), true);
        }
    }

    void ReloadFavorites() {
        try {
            APIRefresh = true;
            if (g_favoriteMaps.Length > 0) g_favoriteMaps.RemoveRange(0, g_favoriteMaps.Length);
            g_fetchedFavorites = false;
            GetFavorites();
            APIRefresh = false;
        } catch {
            Logging::Error("[ReloadFavorites] Error reloading favorite maps: " + getExceptionInfo());
            APIRefresh = false;
        }
    }

    void FavoriteMapsLoop() {
        if (g_favoriteMaps.Length > 0) {
            g_favoriteMaps.RemoveRange(0, g_favoriteMaps.Length);
        }

        GetFavorites();

        while (true) {
            sleep(Setting_FavoritesRefreshDelay * 60 * 1000);
            Logging::Debug('Refreshing favorite maps...');
            ReloadFavorites();
        }
    }

    void AddMapToFavorites(ref@ mapData)
    {
        MX::MapInfo@ map = cast<MX::MapInfo>(mapData);

        string url = NadeoServices::BaseURLLive() + "/api/token/map/favorite/" + map.MapUid + "/add";
        Logging::Debug("[AddMapToFavorites] URL: " + url);

        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", url);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        if (req.ResponseCode() >= 400) {
            auto res = req.Json();

            if (res.GetType() != Json::Type::Array) {
                Logging::Error("[AddMapToFavorites] Error adding map to favorites: " + req.String());
            } else {
                Logging::Error("[AddMapToFavorites] Error adding map to favorites: Failed to find a map with UID " + map.MapUid);
            }
        } else {
            Logging::Debug("[AddMapToFavorites] Succesfully added map with UID " + map.MapUid + " to your favorites");
            startnew(ReloadFavorites);
        }
    }

    void RemoveMapFromFavorites(ref@ mapData)
    {
        TM::MapInfo@ map = cast<TM::MapInfo>(mapData);

        string url = NadeoServices::BaseURLLive() + "/api/token/map/favorite/" + map.Uid + "/remove";
        Logging::Debug("[RemoveMapFromFavorites] URL: " + url);

        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", url);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        if (req.ResponseCode() >= 400) {
            auto res = req.Json();

            if (res.GetType() != Json::Type::Array) {
                Logging::Error("[RemoveMapFromFavorites] Error removing map from favorites: " + req.String());
            } else {
                string errorText = res[0];
                if (errorText == "map:error-notFound") {
                    Logging::Error("[RemoveMapFromFavorites] Error removing map from favorites: Failed to find a map with UID " + map.Uid);
                } else {
                    Logging::Error("[RemoveMapFromFavorites] Error removing map from favorites: A map with UID" + map.Uid + " doesn't exist in your favorites");
                }
            }
        } else {
            Logging::Debug("[RemoveMapFromFavorites] Succesfully removed map with UID " + map.Uid + " from favorites");
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