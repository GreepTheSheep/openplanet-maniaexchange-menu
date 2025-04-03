namespace MXNadeoServicesGlobal
{
    bool APIDown = false;
    bool APIRefresh = false;
    array<NadeoServices::MapInfo@> g_favoriteMaps;
    int g_totalFavoriteMaps;
    string m_mapUidToAction;

#if DEPENDENCY_NADEOSERVICES
    void LoadNadeoLiveServices()
    {
        try {
            APIRefresh = true;

            CheckAuthentication();

            if (g_favoriteMaps.Length > 0) g_favoriteMaps.RemoveRange(0, g_favoriteMaps.Length);
            g_totalFavoriteMaps = 0;
            GetFavoriteMapsAsync();

            APIRefresh = false;
            APIDown = false;

            startnew(RefreshFavoriteMapsLoop);
        } catch {
            Logging::Error("Failed to load NadeoLiveServices: " + getExceptionInfo());
            APIDown = true;
        }
    }

    void CheckAuthentication()
    {
        NadeoServices::AddAudience("NadeoLiveServices");
        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }
        Logging::Debug("NadeoLiveServices authenticated");
    }

    void GetFavoriteMapsAsync()
    {
        Logging::Info("NadeoServices - Loading Favorite tracks...");
        try {
            int offset = 0;
            int length = 100;
            string sort = "date";
            string order = "desc";
            if (Setting_NadeoServices_FavoriteMaps_Sort == NadeoServicesFavoriteMapListSort::Name) sort = "name";
            if (Setting_NadeoServices_FavoriteMaps_SortOrder == NadeoServicesFavoriteMapListSortOrder::Ascending) order = "asc";
            string url = NadeoServices::BaseURLLive()+"/api/token/map/favorite?offset="+offset+"&length="+length+"&sort="+sort+"&order="+order;
            Logging::Debug("NadeoServices - Loading favorite maps: " + url);
            Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);
            req.Start();
            while (!req.Finished()) {
                yield();
            }
            Logging::Debug("NadeoServices - Check favorite maps: " + req.String());
            auto res = req.Json();

            g_totalFavoriteMaps = res["itemCount"];

            if (g_totalFavoriteMaps == 0) return;

            for (uint i = 0; i < res["mapList"].Length; i++) {
                string mapName = res["mapList"][i]["name"];
                string mapUid = res["mapList"][i]["uid"];
                Logging::Trace("Loading favorite map #"+i+": " + Text::StripFormatCodes(mapName) + " (" + mapUid + ")");
                NadeoServices::MapInfo@ map = NadeoServices::MapInfo(res["mapList"][i]);
                g_favoriteMaps.InsertLast(map);
            }

            // 2023-03-13: Infinite loop fixed, big ups to Nadeo devs (shoutouts to Tsurenas ^^)

            offset += int(res["mapList"].Length);

            while (offset < g_totalFavoriteMaps) {
                url = NadeoServices::BaseURLLive()+"/api/token/map/favorite?offset="+offset+"&length="+length+"&sort="+sort+"&order="+order;
                Logging::Debug("NadeoServices - Loading favorite maps: " + url);
                @req = NadeoServices::Get("NadeoLiveServices", url);
                req.Start();
                while (!req.Finished()) {
                    yield();
                }
                Logging::Debug("NadeoServices - Check favorite maps: " + req.String());
                res = req.Json();

                for (uint i = 0; i < res["mapList"].Length; i++) {
                    string mapName = res["mapList"][i]["name"];
                    string mapUid = res["mapList"][i]["uid"];
                    Logging::Trace("Loading favorite map #"+i+": " + Text::StripFormatCodes(mapName) + " (" + mapUid + ")");
                    NadeoServices::MapInfo@ map = NadeoServices::MapInfo(res["mapList"][i]);
                    g_favoriteMaps.InsertLast(map);
                }

                offset += int(res["mapList"].Length);
                sleep(1000);
            }

            Logging::Debug("NadeoServices - Checking for map on MX...");

            uint mapUidsCheckDone = 0;
            uint mapUidsPartLength = 0;

            while (mapUidsCheckDone < g_favoriteMaps.Length) {
                array<string> mapUidsPart;
                for (uint i = 0; i < MX::maxMapsRequest; i++) {
                    if (mapUidsPartLength >= g_favoriteMaps.Length) break;
                    mapUidsPart.InsertLast(g_favoriteMaps[mapUidsPartLength].uid);
                    mapUidsPartLength++;
                }

                string mapUidsPartString = string::Join(mapUidsPart, ",");

                // we do + 10 in case multiple maps have the same UID, which can happen
                string mxUrl = "https://"+MXURL+"/api/maps?fields=" + MX::mapFields + "&count=" + (MX::maxMapsRequest + 10) + "&uid=" +mapUidsPartString;
                Logging::Debug("NadeoServices - Loading map MX infos: " + mxUrl);
                Net::HttpRequest@ mxReq = API::Get(mxUrl);
                while (!mxReq.Finished()) {
                    yield();
                }
                Logging::Debug("NadeoServices - Map MX infos: " + mxReq.String());
                auto mxJson = mxReq.Json();
                int resCode = mxReq.ResponseCode();

                if (resCode >= 400 || mxJson.GetType() == Json::Type::Null || !mxJson.HasKey("Results")) {
                    throw("NadeoServices - Invalid MX map infos response");
                    mapUidsCheckDone += mapUidsPart.Length;
                    continue;
                }

                Json::Value mapResults = mxJson["Results"];
                array<string> foundUids;

                for (uint i = 0; i < mapResults.Length; i++) {
                    Logging::Trace("Loading map MX info "+mapUidsPart[i]);
                    string resMapUid = mapResults[i]["MapUid"];
                    foundUids.InsertLast(resMapUid);

                    for (uint u = 0; u < g_favoriteMaps.Length; u++) {
                        if (resMapUid == g_favoriteMaps[u].uid) {
                            g_favoriteMaps[u].MXId = mapResults[i]["MapId"];
                            @g_favoriteMaps[u].MXMapInfo = MX::MapInfo(mapResults[i]);
                            break;
                        }
                    }
                }

                for (uint f = 0; f < mapUidsPart.Length; f++) {
                    if (foundUids.Find(mapUidsPart[f]) == -1) {
                        Logging::Warn("NadeoServices - Failed to find map with UID " + mapUidsPart[f] + " on MX. The map will be ignored");
                    }
                }

                mapUidsCheckDone += mapUidsPart.Length;
                sleep(1000);
            }

            Logging::Debug("NadeoServices - Loading favorites map author usernames...");

            for (uint i = 0; i < g_favoriteMaps.Length; i++) {
                if (g_favoriteMaps[i].MXMapInfo !is null) {
                    continue;
                }

                g_favoriteMaps[i].authorUsername = NadeoServices::GetDisplayNameAsync(g_favoriteMaps[i].author);
                Logging::Trace("NadeoServices - Author Username for "+Text::StripFormatCodes(g_favoriteMaps[i].name)+" found: "+Text::StripFormatCodes(g_favoriteMaps[i].authorUsername));
            }

            Logging::Info("NadeoServices - Favorite maps: loaded "+g_favoriteMaps.Length+" maps. NadeoServices total: " + g_totalFavoriteMaps + " maps.");
        } catch {
            Logging::Error("Failed to load favorite maps: " + getExceptionInfo(), true);
        }
    }

    void ReloadFavoriteMapsAsync() {
        try {
            MXNadeoServicesGlobal::APIRefresh = true;
            if (g_favoriteMaps.Length > 0) g_favoriteMaps.RemoveRange(0, g_favoriteMaps.Length);
            g_totalFavoriteMaps = 0;
            GetFavoriteMapsAsync();
            MXNadeoServicesGlobal::APIRefresh = false;
        } catch {
            Logging::Error("NadeoServices: Error reloading favorite maps: " + getExceptionInfo());
            MXNadeoServicesGlobal::APIRefresh = false;
        }
    }

    void RefreshFavoriteMapsLoop() {
        while (true) {
            sleep(Setting_NadeoServices_FavoriteMaps_RefreshDelay * 60 * 1000);
            Logging::Debug('NadeoServices: Refreshing favorite maps...');
            ReloadFavoriteMapsAsync();
        }
    }

    bool CheckIfMapExistsAsync(const string &in mapUid)
    {
        string url = NadeoServices::BaseURLLive()+"/api/token/map/"+mapUid;
        Logging::Debug("NadeoServices - Check if map exists: " + url);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        auto res = req.Json();

        if (res.GetType() != Json::Type::Object) {
            if (res.GetType() == Json::Type::Array && res[0].GetType() == Json::Type::String) {
                string errorMsg = res[0];
                if (errorMsg.Contains("notFound")) return false;
            }
            Logging::Error("NadeoServices - Error checking if map exists: " + req.String());
            return false;
        }

        try {
            string resMapUid = res["uid"];
            return resMapUid == mapUid;
        } catch {
            return false;
        }
    }

    Json::Value@ GetMapInfoAsync(const string &in mapUid)
    {
        string url = NadeoServices::BaseURLLive()+"/api/token/map/"+mapUid;
        Logging::Debug("NadeoServices - Get map information: " + url);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        auto res = req.Json();

        if (res.GetType() != Json::Type::Object) {
            Logging::Error("NadeoServices - Error getting map information: " + req.String());
            return null;
        }

        return NadeoServices::MapInfo(res).ToJson();
    }

    void AddMapToFavoritesAsync()
    {
        string url = NadeoServices::BaseURLLive()+"/api/token/map/favorite/"+m_mapUidToAction+"/add";
        Logging::Debug("NadeoServices - Add map to favorites: " + url);
        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", url);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        if (req.ResponseCode() != 200) {
            Logging::Error("NadeoServices - Error adding map to favorites: " + req.String());
        } else {
            Logging::Debug("NadeoServices - "+req.String()+": " + m_mapUidToAction);
        }
        m_mapUidToAction = "";
        startnew(MXNadeoServicesGlobal::ReloadFavoriteMapsAsync);
    }

    void RemoveMapFromFavoritesAsync()
    {
        string url = NadeoServices::BaseURLLive()+"/api/token/map/favorite/"+m_mapUidToAction+"/remove";
        Logging::Debug("NadeoServices - Remove map from favorites: " + url);
        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", url);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        if (req.ResponseCode() != 200) {
            Logging::Error("NadeoServices - Error removing map from favorites: " + req.String());
        } else {
            Logging::Debug("NadeoServices - "+req.String()+": " + m_mapUidToAction);
        }
        m_mapUidToAction = "";
        startnew(MXNadeoServicesGlobal::ReloadFavoriteMapsAsync);
    }
#endif
}