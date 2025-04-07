namespace MX
{
    void GetAllMapTags()
    {
        string url = "https://"+MXURL+"/api/meta/tags";
        Logging::Debug("Loading tags: " + url);
        Json::Value resNet = API::GetAsync(url);

        try {
            for (uint i = 0; i < resNet.Length; i++)
            {
                int tagID = resNet[i]["ID"];
                string tagName = resNet[i]["Name"];

                Logging::Trace("Loading tag #"+tagID+" - "+tagName);

                m_mapTags.InsertLast(MapTag(resNet[i]));
            }

            m_mapTags.Sort(function(a,b) { return a.Name < b.Name; });

            Logging::Info(m_mapTags.Length + " tags loaded");
        } catch {
            throw("Error while loading tags: " + getExceptionInfo());
        }
    }

    void GetAllVehicles()
    {
        string url = "https://"+MXURL+"/api/meta/vehicles";
        Logging::Debug("Loading vehicles: " + url);
        Json::Value res = API::GetAsync(url);

        try {
            for (uint i = 0; i < res.Length; i++)
            {
                string vehicleName = res[i];

                if (vehicleName != "") {
                    Logging::Trace("Loading vehicle " + vehicleName);
                    m_vehicles.InsertLast(vehicleName);
                }
            }

            Logging::Info(m_vehicles.Length + " vehicles loaded");
        } catch {
            throw("Error while loading vehicles: " + getExceptionInfo());
        }
    }

    // TODO change to v2 once the endpoint is added
    void GetAllLeaderboardSeasons()
    {
        string url = "https://"+MXURL+"/api/leaderboard/getseasons";
        Logging::Debug("Loading seasons: " + url);
        Json::Value resNet = API::GetAsync(url);

        try {
            for (uint i = 0; i < resNet.Length; i++)
            {
                int seasonID = resNet[i]["SeasonID"];
                string seasonName = resNet[i]["Name"];

                Logging::Trace("Loading season #"+seasonID+" - "+seasonName);

                m_leaderboardSeasons.InsertLast(LeaderboardSeason(resNet[i]));
            }

            Logging::Info(m_leaderboardSeasons.Length + " seasons loaded");
        } catch {
            throw("Error while loading seasons: " + getExceptionInfo());
        }
    }

    void GetMapSearchOrders()
    {
        string url = "https://"+MXURL+"/api/meta/maporders";
        Logging::Debug("Loading map search orders: " + url);
        Json::Value resNet = API::GetAsync(url);

        try {
            for (uint i = 0; i < resNet.Length; i++)
            {
                int orderKey = resNet[i]["Key"];
                string orderName = resNet[i]["Name"];

                // TODO No way of using these orders yet
                if (orderName.Contains("User") || orderName.Contains("Video")) continue;

                // TODO currently broken and raise error 500
                if (orderName.Contains("Rating") || orderName.Contains("Replay")) continue;

                m_mapSortingOrders.InsertLast(SortingOrder(resNet[i]));
            }

            Logging::Info(m_mapSortingOrders.Length + " map sorting orders loaded");
        } catch {
            throw("Error while loading map sorting orders: " + getExceptionInfo());
        }
    }

    void GetTitlepacks()
    {
        string url = "https://"+MXURL+"/api/meta/titlepacks";
        Logging::Debug("Loading titlepacks: " + url);
        Json::Value res = API::GetAsync(url);

        try {
            m_titlepacks.InsertLast("Any");

            for (uint i = 0; i < res.Length; i++) {
                if (res[i] != "") m_titlepacks.InsertLast(res[i]);
            }

            Logging::Info(m_titlepacks.Length + " titlepacks loaded");
        } catch {
            throw("Error while loading titlepacks: " + getExceptionInfo());
        }
    }

    void GetMapTypes()
    {
        string url = "https://"+MXURL+"/api/meta/maptypes";
        Logging::Debug("Loading map types: " + url);
        Json::Value res = API::GetAsync(url);

        try {
            m_maptypes.InsertLast("Any");

            for (uint i = 0; i < res.Length; i++) {
                if (res[i] != "") m_maptypes.InsertLast(res[i]);
            }

            Logging::Info(m_maptypes.Length + " map types loaded");
        } catch {
            throw("Error while loading map types: " + getExceptionInfo());
        }
    }

    void LoadEnvironments()
    {
#if TMNEXT
        m_environments.InsertLast(MapEnvironment(1, "Stadium"));
#else
        if (repo == MP4mxRepos::Trackmania) {
            m_environments.InsertLast(MapEnvironment(0, "Custom"));
            m_environments.InsertLast(MapEnvironment(1, "Canyon"));
            m_environments.InsertLast(MapEnvironment(2, "Stadium"));
            m_environments.InsertLast(MapEnvironment(3, "Valley"));
            m_environments.InsertLast(MapEnvironment(4, "Lagoon"));
            m_environments.InsertLast(MapEnvironment(5, "Desert / TMOne Speed"));
            m_environments.InsertLast(MapEnvironment(6, "Snow / TMOne Alpine"));
            // m_environments.InsertLast(MapEnvironment(7, "Rally (not available)"));
            // m_environments.InsertLast(MapEnvironment(8, "Coast (not available)"));
            m_environments.InsertLast(MapEnvironment(9, "Bay / TMOne Bay"));
            m_environments.InsertLast(MapEnvironment(10, "Island / TM²U Island"));
        } else {
            m_environments.InsertLast(MapEnvironment(1, "Storm"));
        }
#endif
    }

    void CheckForAPILoaded()
    {
        try {
            APIRefresh = true;
            if (m_mapTags.Length > 0) m_mapTags.RemoveRange(0, m_mapTags.Length);
            GetAllMapTags();
            if (m_environments.Length > 0) m_environments.RemoveRange(0, m_environments.Length);
            LoadEnvironments();
            if (m_vehicles.Length > 0) m_vehicles.RemoveRange(0, m_vehicles.Length);
            GetAllVehicles();
            if (m_mapSortingOrders.Length > 0) m_mapSortingOrders.RemoveRange(0, m_mapSortingOrders.Length);
            GetMapSearchOrders();
            if (m_maptypes.Length > 0) m_maptypes.RemoveRange(0, m_maptypes.Length);
            GetMapTypes();
#if MP4
            if (m_titlepacks.Length > 0) m_titlepacks.RemoveRange(0, m_titlepacks.Length);
            GetTitlepacks();

            if (repo == MP4mxRepos::Trackmania) {
#endif
            if (m_leaderboardSeasons.Length > 0) m_leaderboardSeasons.RemoveRange(0, m_leaderboardSeasons.Length);
            GetAllLeaderboardSeasons();
#if MP4
            }
#endif
            APIRefresh = false;
#if FORCE_API_DOWN
            APIDown = true;
            Logging::Warn("API set to forced down", true);
#else
            APIDown = false;
#endif
        } catch {
            Logging::Error(getExceptionInfo());
            Logging::Error(pluginName + " API is not responding, it must be down.", true);
            APIDown = true;
            APIRefresh = false;
        }
    }


    void LoadMap(int mapId, bool intoEditor = false)
    {
        try {
#if MP4
            if (CurrentTitlePack() == "") {
                Logging::Error("You must select a title pack before opening a map", true);
                return;
            }
#endif

            auto json = API::GetAsync("https://"+MXURL+"/api/maps?fields=" + mapFields + "&id=" +mapId);
            if (json.GetType() == Json::Type::Null || !json.HasKey("Results") || json["Results"].Length == 0) {
                Logging::Error("Track not found.", true);
                return;
            }
            MX::MapInfo@ map = MX::MapInfo(json["Results"][0]);

#if TMNEXT
            if (Permissions::PlayLocalMap()) {
#endif
                CTrackMania@ app = cast<CTrackMania>(GetApp());
                app.BackToMainMenu(); // If we're on a map, go back to the main menu else we'll get stuck on the current map
                while(!app.ManiaTitleControlScriptAPI.IsReady) {
                    yield(); // Wait until the ManiaTitleControlScriptAPI is ready for loading the next map
                }
                if (
                    intoEditor
#if TMNEXT
                    && Permissions::OpenAdvancedMapEditor()
#endif
                ) app.ManiaTitleControlScriptAPI.EditMap("https://"+MXURL+"/mapgbx/"+mapId, "", "");
                else {
                    string Mode = "";
                    MX::ModesFromMapType.Get(map.MapType, Mode);

#if MP4
                    if (Mode == "" && repo == MP4mxRepos::Trackmania){
                        const string loadedTP = CurrentTitlePack();
                        MX::ModesFromTitlePack.Get(loadedTP, Mode);
                    }
#endif

                    app.ManiaTitleControlScriptAPI.PlayMap("https://"+MXURL+"/mapgbx/"+mapId, Mode, "");
                }
#if TMNEXT
            } else Logging::Error("You don't have permission to play custom maps.", true);
#endif
        } catch {
            Logging::Error("Error while loading map: " + getExceptionInfo());
            Logging::Error(pluginName + " API is not responding, it must be down.", true);
            APIDown = true;
        }
    }

    void DownloadMap(int mapId, const string &in mapPackName = "", string _fileName = "")
    {
        try {
            auto json = API::GetAsync("https://"+MXURL+"/api/maps?fields=" + mapFields + "&id=" +mapId);
            if (json.GetType() == Json::Type::Null || !json.HasKey("Results") || json["Results"].Length == 0) {
                Logging::Error("Track not found.", true);
                return;
            }
            MX::MapInfo@ map = MX::MapInfo(json["Results"][0]);

            string downloadedMapFolder = IO::FromUserGameFolder("Maps/Downloaded");
            string mxDLFolder = downloadedMapFolder + "/" + pluginName;
            if (!IO::FolderExists(downloadedMapFolder)) IO::CreateFolder(downloadedMapFolder);
            if (!IO::FolderExists(mxDLFolder)) IO::CreateFolder(mxDLFolder);
            if (mapPackName.Length > 0) {
                mxDLFolder = mxDLFolder + "/Packs";
                if (!IO::FolderExists(mxDLFolder)) IO::CreateFolder(mxDLFolder);
                mxDLFolder = mxDLFolder + "/" + Path::SanitizeFileName(mapPackName);
                if (!IO::FolderExists(mxDLFolder)) IO::CreateFolder(mxDLFolder);
            }

            Net::HttpRequest@ netMap = API::Get("https://"+MXURL+"/mapgbx/"+mapId);
            mapDownloadInProgress = true;
            Logging::Debug("Started downloading map "+map.Name+" ("+mapId+") to "+mxDLFolder);
            while(!netMap.Finished()) {
                yield();
            }
            mapDownloadInProgress = false;

            if (_fileName.Length == 0) _fileName = map.MapId + " - " + map.Name;
            _fileName = Path::SanitizeFileName(_fileName);
            netMap.SaveToFile(mxDLFolder + "/" + _fileName + ".Map.Gbx");
            Logging::Info("Map downloaded to " + mxDLFolder + "/" + _fileName + ".Map.Gbx");
        } catch {
            Logging::Error("Error while downloading map: " + getExceptionInfo());
            Logging::Error(pluginName + " API is not responding, it must be down.", true);
            APIDown = true;
        }
    }

    /*
     * MX ID Error codes:
     * > 0 = MX ID
     * -1 = Map not found
     * -2 = Server error
     * -3 = Loading request
     * -4 = Not in a map
     * -5 = In Map Editor
    */
    int GetCurrentMapMXID(){
        auto currentMap = GetCurrentMap();
        if (!IsInEditor()){
            if (currentMap !is null) {
                string UIDMap = currentMap.MapInfo.MapUid;
                string url = "https://"+MXURL+"/api/maps?fields=" + mapFields + "&uid=" + UIDMap;
                if (req is null){
                    Logging::Debug("LoadCurrentMap::StartRequest: " + url);
                    @req = API::Get(url);
                }

                if (req !is null && req.Finished()) {
                    string response = req.String();
                    Json::Value returnedObject = req.Json();
                    @req = null;
                    Logging::Trace("LoadCurrentMap::CheckResponse: " + response);

                    try {
                        if (returnedObject["Results"].Length > 0) {
                            @currentMapInfo = MapInfo(returnedObject["Results"][0]);
                            int g_MXId = returnedObject["Results"][0]["MapId"];
                            return g_MXId;
                        } else {
                            return -1;
                        }
                    } catch {
                        return -2;
                    }
                } else {
                    return -3;
                }
            } else {
                return -4;
            }
        } else {
            return -5;
        }
    }

    string DictToApiParams(dictionary params) {
        string urlParams = "";
        if (!params.IsEmpty()) {
            auto keys = params.GetKeys();
            for (uint i = 0; i < keys.Length; i++) {
                string key = keys[i];
                string value;
                params.Get(key, value);

                urlParams += (i == 0 ? "?" : "&");
                urlParams += key + "=" + Net::UrlEncode(value.Trim());
            }
        }

        return urlParams;
    }
}