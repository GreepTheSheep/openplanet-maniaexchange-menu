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
            Net::HttpRequest@ req = API::Get(url);
            while (!req.Finished()) {
                yield();
            }
            string res = req.String();
            if (IsDevMode()) trace("NadeoServicesMap::CheckRequest (TryGetMXInfo): " + res);
            @req = null;
            auto json = Json::Parse(res);

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
        if (g_nadeoServices.m_favoriteMaps.Length > 0) g_nadeoServices.m_favoriteMaps.RemoveRange(0, g_nadeoServices.m_favoriteMaps.Length);
        g_nadeoServices.m_totalFavoriteMaps = 0;
        g_nadeoServices.GetFavoriteMapsAsync();
    }
#endif
}

#if DEPENDENCY_NADEOSERVICES
class MXNadeoServices
{
    array<MXNadeoServicesGlobal::NadeoServicesMap@> m_favoriteMaps;
    int m_totalFavoriteMaps;
    dictionary g_cachedUsernames;

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

    void GetFavoriteMapsAsync(int offset = 0, int length = 100, string sort = "date", string order = "desc")
    {
        string url = NadeoServices::BaseURL()+"/api/token/map/favorite?offset="+offset+"&length="+length+"&sort="+sort+"&order="+order;
        if (IsDevMode()) trace("NadeoServices - Loading favorite maps: " + url);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        auto res = Json::Parse(req.String());

        m_totalFavoriteMaps = res["itemCount"];

        for (uint i = 0; i < res["mapList"].Length; i++) {
            string mapName = res["mapList"][i]["name"];
            string mapUid = res["mapList"][i]["uid"];
            if (IsDevMode()) trace("Loading favorite map #"+i+": " + mapName + " (" + mapUid + ")");
            MXNadeoServicesGlobal::NadeoServicesMap@ map = MXNadeoServicesGlobal::NadeoServicesMap(res["mapList"][i]);
            m_favoriteMaps.InsertLast(map);
        }

        print("NadeoServices - Favorite maps: loaded "+m_favoriteMaps.Length+" maps. Total: "+m_totalFavoriteMaps);
    }
}
#endif