namespace MX
{
    void GetAllMapTags()
    {
        string url = "https://"+MXURL+"/api/tags/gettags";
        if (isDevMode) trace("Loading tags: " + url);
        Json::Value resNet = API::GetAsync(url);

        try {
            for (uint i = 0; i < resNet.Length; i++)
            {
                int tagID = resNet[i]["ID"];
                string tagName = resNet[i]["Name"];

                if (isDevMode) trace("Loading tag #"+tagID+" - "+tagName);

                m_mapTags.InsertLast(MapTag(resNet[i]));
            }

            m_mapTags.Sort(function(a,b) { return a.Name < b.Name; });

            print(m_mapTags.Length + " tags loaded");
        } catch {
            throw("Error while loading tags: " + getExceptionInfo());
        }
    }

    void GetAllVehicles()
    {
        string url = "https://"+MXURL+"/api/meta/vehicles";
        if (isDevMode) trace("Loading vehicles: " + url);
        Json::Value res = API::GetAsync(url);

        try {
            m_vehicles.InsertLast("Any");

            for (uint i = 0; i < res.Length; i++)
            {
                string vehicleName = res[i];

                if (vehicleName != "") {
                    if (isDevMode) trace("Loading vehicle " + vehicleName);
                    m_vehicles.InsertLast(vehicleName);
                }
            }

            print(m_vehicles.Length + " vehicles loaded");
        } catch {
            throw("Error while loading vehicles: " + getExceptionInfo());
        }
    }

    void GetAllLeaderboardSeasons()
    {
        string url = "https://"+MXURL+"/api/leaderboard/getseasons";
        if (isDevMode) trace("Loading seasons: " + url);
        Json::Value resNet = API::GetAsync(url);

        try {
            for (uint i = 0; i < resNet.Length; i++)
            {
                int seasonID = resNet[i]["SeasonID"];
                string seasonName = resNet[i]["Name"];

                if (isDevMode) trace("Loading season #"+seasonID+" - "+seasonName);

                m_leaderboardSeasons.InsertLast(LeaderboardSeason(resNet[i]));
            }

            print(m_leaderboardSeasons.Length + " seasons loaded");
        } catch {
            throw("Error while loading seasons: " + getExceptionInfo());
        }
    }

    void LoadEnvironments()
    {
#if TMNEXT
        m_environments.InsertLast(Environment(1, "Stadium"));
#else
        if (repo == MP4mxRepos::Trackmania) {
            m_environments.InsertLast(Environment(-1, "Any"));
            m_environments.InsertLast(Environment(0, "Custom"));
            m_environments.InsertLast(Environment(1, "Canyon"));
            m_environments.InsertLast(Environment(2, "Stadium"));
            m_environments.InsertLast(Environment(3, "Valley"));
            m_environments.InsertLast(Environment(4, "Lagoon"));
            m_environments.InsertLast(Environment(5, "Desert / TMOne Speed"));
            m_environments.InsertLast(Environment(6, "Snow / TMOne Alpine"));
            // m_environments.InsertLast(Environment(7, "Rally (not available)"));
            // m_environments.InsertLast(Environment(8, "Coast (not available)"));
            m_environments.InsertLast(Environment(9, "Bay / TMOne Bay"));
            m_environments.InsertLast(Environment(10, "Island / TM²U Island"));
        } else {
            m_environments.InsertLast(Environment(1, "Storm"));
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
#if MP4
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
            mxWarn("API set to forced down", true);
#else
            APIDown = false;
#endif
        } catch {
            mxError(getExceptionInfo(), isDevMode);
            mxError(pluginName + " API is not responding, it must be down.", true);
            APIDown = true;
            APIRefresh = false;
        }
    }


    void LoadMap(int mapId, bool intoEditor = false)
    {
        try {
#if MP4
            if (CurrentTitlePack() == "") {
                mxError("You must select a title pack before opening a map", true);
                return;
            }
#endif

            auto json = API::GetAsync("https://"+MXURL+"/api/maps?fields=" + mapFields + "&id=" +mapId);
            if (json.GetType() == Json::Type::Null || !json.HasKey("Results") || json["Results"].Length == 0) {
                mxError("Track not found.", true);
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
                ) app.ManiaTitleControlScriptAPI.EditMap("https://"+MXURL+"/maps/download/"+mapId, "", "");
                else {
                    string Mode = "";
                    Json::Value Modes = MX::ModesFromMapType();

                    if (Modes.HasKey(map.MapType)) {
                        Mode = Modes[map.MapType];
                    }

#if MP4
                    if (Mode == "" && repo == MP4mxRepos::Trackmania) {
                        Json::Value TitlePackModes = MX::ModesFromTitlePack();
                        const string loadedTP = CurrentTitlePack();

                        if (TitlePackModes.HasKey(loadedTP)) {
                            Mode = TitlePackModes[loadedTP];
                        }
                    }
#endif

                    app.ManiaTitleControlScriptAPI.PlayMap("https://"+MXURL+"/maps/download/"+mapId, Mode, "");
                }
#if TMNEXT
            } else mxError("You don't have permission to play custom maps.", true);
#endif
        } catch {
            mxError("Error while loading map: " + getExceptionInfo());
            mxError(pluginName + " API is not responding, it must be down.", true);
            APIDown = true;
        }
    }

    void DownloadMap(int mapId, const string &in mapPackName = "", string _fileName = "")
    {
        try {
            auto json = API::GetAsync("https://"+MXURL+"/api/maps?fields=" + mapFields + "&id=" +mapId);
            if (json.GetType() == Json::Type::Null || !json.HasKey("Results") || json["Results"].Length == 0) {
                mxError("Track not found.", true);
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

            Net::HttpRequest@ netMap = API::Get("https://"+MXURL+"/maps/download/"+mapId);
            mapDownloadInProgress = true;
            trace("Started downloading map "+map.Name+" ("+mapId+") to "+mxDLFolder);
            while(!netMap.Finished()) {
                yield();
            }
            mapDownloadInProgress = false;

            if (_fileName.Length == 0) _fileName = map.MapId + " - " + map.Name;
            _fileName = Path::SanitizeFileName(_fileName);
            netMap.SaveToFile(mxDLFolder + "/" + _fileName + ".Map.Gbx");
            print("Map downloaded to " + mxDLFolder + "/" + _fileName + ".Map.Gbx");
        } catch {
            mxError("Error while downloading map: " + getExceptionInfo());
            mxError(pluginName + " API is not responding, it must be down.", true);
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
                    if (isDevMode) trace("LoadCurrentMap::StartRequest: " + url);
                    @req = API::Get(url);
                }

                if (req !is null && req.Finished()) {
                    string response = req.String();
                    @req = null;
                    if (isDevMode) trace("LoadCurrentMap::CheckResponse: " + response);

                    // Evaluate reqest result
                    Json::Value returnedObject = Json::Parse(response);
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
                urlParams += key + "=" + Net::UrlEncode(value);
            }
        }

        return urlParams;
    }
}