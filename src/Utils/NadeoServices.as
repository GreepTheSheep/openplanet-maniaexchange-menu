namespace MXNadeoServicesGlobal
{
    bool APIDown = false;
    bool APIRefresh = false;

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

                startnew(CoroutineFunc(TryGetMXInfo));
#if DEPENDENCY_NADEOSERVICES
                startnew(CoroutineFunc(TryGetUsernameAsync));
#endif
            } catch {
                mxWarn("Error parsing infos for map: " + name);
            }
        }

        void TryGetMXInfo()
        {
            string url = "https://"+MXURL+"/api/maps/get_map_info/multi/"+uid;
            if (IsDevMode()) trace("NadeoServicesMap::StartRequest (TryGetMXInfo): "+url);
            auto json = API::GetAsync(url);

            if (json.Length > 0) {
                @MXMapInfo = MX::MapInfo(json[0]);
                MXId = json[0]["TrackID"];
                trace("NadeoServices - MX Map Info found for map '" + name + "' : " + MXId);
            }
        }

#if DEPENDENCY_NADEOSERVICES
        void TryGetUsernameAsync()
        {
            authorUsername = NadeoServices::GetDisplayNameAsync(author);
            if (IsDevMode()) trace("NadeoServices: Username found for '"+ author +"': " + authorUsername);
        }
#endif
    }

#if DEPENDENCY_NADEOSERVICES
    void ReloadFavoriteMapsAsync() {
        try {
            MXNadeoServicesGlobal::APIRefresh = true;
            if (g_nadeoServices.m_favoriteMaps.Length > 0) g_nadeoServices.m_favoriteMaps.RemoveRange(0, g_nadeoServices.m_favoriteMaps.Length);
            g_nadeoServices.m_totalFavoriteMaps = 0;
            g_nadeoServices.GetFavoriteMapsAsync();
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
#endif
}

#if DEPENDENCY_NADEOSERVICES
class MXNadeoServices
{
    array<MXNadeoServicesGlobal::NadeoServicesMap@> m_favoriteMaps;
    int m_totalFavoriteMaps;
    string m_mapUidToAction;

    void LoadNadeoLiveServices()
    {
        try {
            MXNadeoServicesGlobal::APIRefresh = true;

            CheckAuthentication();

            if (m_favoriteMaps.Length > 0) m_favoriteMaps.RemoveRange(0, m_favoriteMaps.Length);
            m_totalFavoriteMaps = 0;
            GetFavoriteMapsAsync();

            MXNadeoServicesGlobal::APIRefresh = false;
            MXNadeoServicesGlobal::APIDown = false;

            startnew(MXNadeoServicesGlobal::RefreshFavoriteMapsLoop);
        } catch {
            mxError("Failed to load NadeoLiveServices", IsDevMode());
            MXNadeoServicesGlobal::APIDown = true;
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
        int offset = 0;
        int length = 100;
        string sort = "date";
        string order = "desc";
        if (Setting_NadeoServices_FavoriteMaps_Sort == NadeoServicesFavoriteMapListSort::Name) sort = "name";
        if (Setting_NadeoServices_FavoriteMaps_SortOrder == NadeoServicesFavoriteMapListSortOrder::Ascending) order = "asc";
        string url = NadeoServices::BaseURL()+"/api/token/map/favorite?offset="+offset+"&length="+length+"&sort="+sort+"&order="+order;
        if (IsDevMode()) trace("NadeoServices - Loading favorite maps: " + url);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        auto res = Json::Parse(req.String());

        m_totalFavoriteMaps = res["itemCount"];

        if (m_totalFavoriteMaps == 0) return;

        for (uint i = 0; i < res["mapList"].Length; i++) {
            string mapName = res["mapList"][i]["name"];
            string mapUid = res["mapList"][i]["uid"];
            if (IsDevMode()) trace("Loading favorite map #"+i+": " + mapName + " (" + mapUid + ")");
            MXNadeoServicesGlobal::NadeoServicesMap@ map = MXNadeoServicesGlobal::NadeoServicesMap(res["mapList"][i]);
            m_favoriteMaps.InsertLast(map);
        }

        while (res["mapList"].Length < m_totalFavoriteMaps) {
            offset += res["mapList"].Length;
            url = NadeoServices::BaseURL()+"/api/token/map/favorite?offset="+offset+"&length="+length+"&sort="+sort+"&order="+order;
            if (IsDevMode()) trace("NadeoServices - Loading favorite maps: " + url);
            @req = NadeoServices::Get("NadeoLiveServices", url);
            req.Start();
            while (!req.Finished()) {
                yield();
            }
            res = Json::Parse(req.String());

            for (uint i = 0; i < res["mapList"].Length; i++) {
                string mapName = res["mapList"][i]["name"];
                string mapUid = res["mapList"][i]["uid"];
                if (IsDevMode()) trace("Loading favorite map #"+i+": " + mapName + " (" + mapUid + ")");
                MXNadeoServicesGlobal::NadeoServicesMap@ map = MXNadeoServicesGlobal::NadeoServicesMap(res["mapList"][i]);
                m_favoriteMaps.InsertLast(map);
            }
        }

        print("NadeoServices - Favorite maps: loaded "+m_favoriteMaps.Length+" maps. Total: "+m_totalFavoriteMaps);
    }

    bool CheckIfMapExistsAsync(string mapUid)
    {
        string url = NadeoServices::BaseURL()+"/api/token/map/"+mapUid;
        if (IsDevMode()) trace("NadeoServices - Check if map exists: " + url);
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

    void SendAddMapToFavorites(string mapUid)
    {
        m_mapUidToAction = mapUid;
        startnew(CoroutineFunc(AddMapToFavoritesAsync));
    }

    void SendRemoveMapToFavorites(string mapUid)
    {
        m_mapUidToAction = mapUid;
        startnew(CoroutineFunc(RemoveMapFromFavoritesAsync));
    }

    void AddMapToFavoritesAsync()
    {
        string url = NadeoServices::BaseURL()+"/api/token/map/favorite/"+m_mapUidToAction+"/add";
        if (IsDevMode()) trace("NadeoServices - Add map to favorites: " + url);
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
        if (IsDevMode()) trace("NadeoServices - Remove map from favorites: " + url);
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
}
#endif