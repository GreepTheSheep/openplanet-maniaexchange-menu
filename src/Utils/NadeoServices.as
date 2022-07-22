namespace MXNadeoServicesGlobal
{
    bool APIDown = false;
    bool APIRefresh = false;
    array<NadeoServicesMap@> g_favoriteMaps;
    int g_totalFavoriteMaps;
    string m_mapUidToAction;

    class NadeoServicesMap
    {
        string uid;
        string mapId;
        string name;
        string author;
        string authorUsername;
        uint authorTime;
        uint goldTime;
        uint silverTime;
        uint bronzeTime;
        int nbLaps;
        bool valid;
        string downloadUrl;
        string thumbnailUrl;
        int uploadTimestamp;
        int updateTimestamp;
        int fileSize;
        bool public;
        bool favorite;
        bool playable;
        string mapStyle;
        string mapType;
        string collectionName;
        int MXId;
        MX::MapInfo@ MXMapInfo;

        NadeoServicesMap(const Json::Value &in json)
        {
            try {
                uid = json["uid"];
                mapId = json["mapId"];
                name = json["name"];
                author = json["author"];
                authorTime = json["authorTime"];
                goldTime = json["goldTime"];
                silverTime = json["silverTime"];
                bronzeTime = json["bronzeTime"];
                nbLaps = json["nbLaps"];
                valid = json["valid"];
                downloadUrl = json["downloadUrl"];
                thumbnailUrl = json["thumbnailUrl"];
                uploadTimestamp = json["uploadTimestamp"];
                updateTimestamp = json["updateTimestamp"];
                if (json["fileSize"].GetType() != Json::Type::Null) fileSize = json["fileSize"];
                public = json["public"];
                favorite = json["favorite"];
                playable = json["playable"];
                mapStyle = json["mapStyle"];
                mapType = json["mapType"];
                collectionName = json["collectionName"];
            } catch {
                mxWarn("Error parsing infos for map: " + name);
            }
        }
    }

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
            mxError("Failed to load NadeoLiveServices", isDevMode);
            APIDown = true;
        }
    }

    void CheckAuthentication()
    {
        NadeoServices::AddAudience("NadeoLiveServices");
        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }
        trace("NadeoLiveServices authenticated");
    }

    void GetFavoriteMapsAsync()
    {
        trace("NadeoServices - Loading Favorite tracks...");

        int offset = 0;
        int length = 100;
        string sort = "date";
        string order = "desc";
        if (Setting_NadeoServices_FavoriteMaps_Sort == NadeoServicesFavoriteMapListSort::Name) sort = "name";
        if (Setting_NadeoServices_FavoriteMaps_SortOrder == NadeoServicesFavoriteMapListSortOrder::Ascending) order = "asc";
        string url = NadeoServices::BaseURL()+"/api/token/map/favorite?offset="+offset+"&length="+length+"&sort="+sort+"&order="+order;
        if (isDevMode) trace("NadeoServices - Loading favorite maps: " + url);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        if (isDevMode) trace("NadeoServices - Check favorite maps: " + req.String());
        auto res = Json::Parse(req.String());

        g_totalFavoriteMaps = res["itemCount"];

        if (g_totalFavoriteMaps == 0) return;

        for (uint i = 0; i < res["mapList"].Length; i++) {
            string mapName = res["mapList"][i]["name"];
            string mapUid = res["mapList"][i]["uid"];
            if (isDevMode) trace("Loading favorite map #"+i+": " + mapName + " (" + mapUid + ")");
            MXNadeoServicesGlobal::NadeoServicesMap@ map = MXNadeoServicesGlobal::NadeoServicesMap(res["mapList"][i]);
            g_favoriteMaps.InsertLast(map);
        }

        while (int(res["mapList"].Length) < g_totalFavoriteMaps) {
            offset += int(res["mapList"].Length);
            url = NadeoServices::BaseURL()+"/api/token/map/favorite?offset="+offset+"&length="+length+"&sort="+sort+"&order="+order;
            if (isDevMode) trace("NadeoServices - Loading favorite maps: " + url);
            @req = NadeoServices::Get("NadeoLiveServices", url);
            req.Start();
            while (!req.Finished()) {
                yield();
            }
            if (isDevMode) trace("NadeoServices - Check favorite maps: " + req.String());
            res = Json::Parse(req.String());

            for (uint i = 0; i < res["mapList"].Length; i++) {
                string mapName = res["mapList"][i]["name"];
                string mapUid = res["mapList"][i]["uid"];
                if (isDevMode) trace("Loading favorite map #"+i+": " + StripFormatCodes(mapName) + " (" + mapUid + ")");
                MXNadeoServicesGlobal::NadeoServicesMap@ map = MXNadeoServicesGlobal::NadeoServicesMap(res["mapList"][i]);
                g_favoriteMaps.InsertLast(map);
            }
        }

        trace("NadeoServices - Checking for map on MX...");

        uint splitMapUids = 5;
        uint mapUidsCheckDone = 0;
        uint mapUidsPartLength = 0;

        while (mapUidsCheckDone < g_favoriteMaps.Length) {
            array<string> mapUidsPart;
            for (uint i = 0; i < splitMapUids; i++) {
                if (mapUidsPartLength >= g_favoriteMaps.Length) break;
                mapUidsPart.InsertLast(g_favoriteMaps[mapUidsPartLength].uid);
                mapUidsPartLength++;
            }

            string mapUidsPartString = "";
            for (uint i = 0; i < mapUidsPart.Length; i++) {
                mapUidsPartString += mapUidsPart[i];
                if (i < mapUidsPart.Length - 1) mapUidsPartString += ",";
            }

            string mxUrl = "https://"+MXURL+"/api/maps/get_map_info/multi/"+mapUidsPartString;
            if (isDevMode) trace("NadeoServices - Loading map MX infos: " + mxUrl);
            Net::HttpRequest@ mxReq = API::Get(mxUrl);
            while (!mxReq.Finished()) {
                yield();
            }
            if (isDevMode) trace("NadeoServices - Map MX infos: " + mxReq.String());
            auto mxJson = Json::Parse(mxReq.String());

            if (mxJson.GetType() != Json::Type::Array) {
                mxError("NadeoServices - Invalid MX map infos response", isDevMode);
                mapUidsCheckDone += mapUidsPartLength;
                continue;
            }

            for (uint i = 0; i < mxJson.Length; i++) {
                if (isDevMode) trace("Loading map MX info "+mapUidsPart[i]);
                string resMapUid = mxJson[i]["TrackUID"];
                while (resMapUid != g_favoriteMaps[mapUidsCheckDone].uid) {
                    if (isDevMode) mxWarn("NadeoServices - Map UID mismatch: " + resMapUid + " != " + mapUidsPart[i] + "\nThe map will be ignored");
                    mapUidsCheckDone++;
                }
                g_favoriteMaps[mapUidsCheckDone].MXId = mxJson[i]["TrackID"];
                @g_favoriteMaps[mapUidsCheckDone].MXMapInfo = MX::MapInfo(mxJson[i]);
                mapUidsCheckDone++;
            }
        }

        trace("NadeoServices - Loading favorites map author usernames (using tm.io)...");

        for (uint i = 0; i < g_favoriteMaps.Length; i++) {
            if (g_favoriteMaps[i].MXMapInfo !is null) {
                if (isDevMode) trace("NadeoServices - Author Username for "+StripFormatCodes(g_favoriteMaps[i].name)+" Skipping because MX map info is already loaded.");
                continue;
            }

            try {
                bool tmioError = true;
                while (tmioError) {
                    string tmioUrl = "https://trackmania.io/api/player/"+g_favoriteMaps[i].author;
                    if (isDevMode) trace("NadeoServices - Loading map author from tm.io: " + tmioUrl);
                    Net::HttpRequest@ tmioReq = API::Get(tmioUrl);
                    while (!tmioReq.Finished()) {
                        yield();
                    }
                    if (isDevMode) trace("NadeoServices - Map author from tm.io: " + tmioReq.String());
                    auto tmioJson = Json::Parse(tmioReq.String());

                    if (tmioJson.HasKey("error")) {
                        tmioError = true;
                        string errMsg = tmioJson["error"];
                        mxWarn("NadeoServices - Tm.io API Error: " + errMsg + "\nRetrying in 1min...", isDevMode);
                        sleep(60*60*1000);
                    } else {
                        tmioError = false;
                        g_favoriteMaps[i].authorUsername = tmioJson["displayname"];
                        if (isDevMode) trace("NadeoServices - Author Username for "+StripFormatCodes(g_favoriteMaps[i].name)+" '"+g_favoriteMaps[i].author+"': " + g_favoriteMaps[i].authorUsername);
                    }
                }
            } catch {
                mxWarn("NadeoServices - Author Username for "+StripFormatCodes(g_favoriteMaps[i].name)+" '"+g_favoriteMaps[i].author+"': Failed", isDevMode);
            }
        }

        print("NadeoServices - Favorite maps: loaded "+g_favoriteMaps.Length+" maps." + (isDevMode ? (" NadeoServices total: " + g_totalFavoriteMaps + " maps.") :""));
    }

    void ReloadFavoriteMapsAsync() {
        try {
            MXNadeoServicesGlobal::APIRefresh = true;
            if (g_favoriteMaps.Length > 0) g_favoriteMaps.RemoveRange(0, g_favoriteMaps.Length);
            g_totalFavoriteMaps = 0;
            GetFavoriteMapsAsync();
            MXNadeoServicesGlobal::APIRefresh = false;
        } catch {
            mxError("NadeoServices: Error reloading favorite maps");
            MXNadeoServicesGlobal::APIRefresh = false;
        }
    }

    void RefreshFavoriteMapsLoop() {
        while (true) {
            sleep(Setting_NadeoServices_FavoriteMaps_RefreshDelay * 60 * 1000);
            trace('NadeoServices: Refreshing favorite maps...');
            ReloadFavoriteMapsAsync();
        }
    }

    bool CheckIfMapExistsAsync(string mapUid)
    {
        string url = NadeoServices::BaseURL()+"/api/token/map/"+mapUid;
        if (isDevMode) trace("NadeoServices - Check if map exists: " + url);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        auto res = Json::Parse(req.String());

        if (res.GetType() != Json::Type::Object) {
            if (res.GetType() == Json::Type::Array && res[0].GetType() == Json::Type::String) {
                string errorMsg = res[0];
                if (errorMsg.Contains("notFound")) return false;
            }
            mxError("NadeoServices - Error checking if map exists: " + req.String());
            return false;
        }

        try {
            string resMapUid = res["uid"];
            return resMapUid == mapUid;
        } catch {
            return false;
        }
    }

    void AddMapToFavoritesAsync()
    {
        string url = NadeoServices::BaseURL()+"/api/token/map/favorite/"+m_mapUidToAction+"/add";
        if (isDevMode) trace("NadeoServices - Add map to favorites: " + url);
        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", url);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        if (req.ResponseCode() != 200) {
            mxError("NadeoServices - Error adding map to favorites: " + req.String());
        } else {
            print("NadeoServices - "+req.String()+": " + m_mapUidToAction);
        }
        m_mapUidToAction = "";
        startnew(MXNadeoServicesGlobal::ReloadFavoriteMapsAsync);
    }

    void RemoveMapFromFavoritesAsync()
    {
        string url = NadeoServices::BaseURL()+"/api/token/map/favorite/"+m_mapUidToAction+"/remove";
        if (isDevMode) trace("NadeoServices - Remove map from favorites: " + url);
        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", url);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        if (req.ResponseCode() != 200) {
            mxError("NadeoServices - Error removing map from favorites: " + req.String());
        } else {
            print("NadeoServices - "+req.String()+": " + m_mapUidToAction);
        }
        m_mapUidToAction = "";
        startnew(MXNadeoServicesGlobal::ReloadFavoriteMapsAsync);
    }
#endif
}