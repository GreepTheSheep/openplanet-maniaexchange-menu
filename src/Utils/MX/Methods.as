namespace MX
{
    void GetAllMapTags()
    {
        Json::Value resNet = API::GetAsync("https://"+MXURL+"/api/tags/gettags");

        try {
            for (uint i = 0; i < resNet.get_Length(); i++)
            {
                int tagID = resNet[i]["ID"];
                string tagName = resNet[i]["Name"];

                if (IsDevMode()) trace("Loading tag #"+tagID+" - "+tagName);

                m_mapTags.InsertLast(MapTag(resNet[i]));
            }

            print(m_mapTags.get_Length() + " tags loaded");
            MX::APIDown = false;
        } catch {
            mxError("Error while loading tags");
            mxError(pluginName + " API is not responding, it must be down.", true);
            APIDown = true;
        }
    }


    void LoadMap(int mapId)
    {
        try {
            MX::MapInfo@ map = MX::MapInfo(API::GetAsync("https://"+MXURL+"/api/maps/get_map_info/multi/"+mapId)[0]);

            string Mode = "";
            Json::Value Modes = MX::ModesFromMapType();

            if (Modes.HasKey(map.MapType)) {
                Mode = Modes[map.MapType];
            }

            CTrackMania@ app = cast<CTrackMania>(GetApp());
            app.BackToMainMenu(); // If we're on a map, go back to the main menu else we'll get stuck on the current map
            while(!app.ManiaTitleControlScriptAPI.IsReady) {
                yield(); // Wait until the ManiaTitleControlScriptAPI is ready for loading the next map
            }
            app.ManiaTitleControlScriptAPI.PlayMap("https://"+MXURL+"/maps/download/"+mapId, Mode, "");
        } catch {
            mxError("Error while loading map");
            mxError(pluginName + " API is not responding, it must be down.", true);
            APIDown = true;
        }
    }

    void DownloadMap(int mapId)
    {
        if (UserMapsFolder() == "<Invalid>") return;

        try {
            string downloadedMapFolder = UserMapsFolder() + "Downloaded";
            string mxDLFolder = downloadedMapFolder + "/" + pluginName;
            if (!IO::FolderExists(downloadedMapFolder)) IO::CreateFolder(downloadedMapFolder);
            if (!IO::FolderExists(mxDLFolder)) IO::CreateFolder(mxDLFolder);

            Net::HttpRequest@ netMap = API::Get("https://"+MXURL+"/maps/download/"+mapId);
            mapDownloadInProgress = true;
            while(!netMap.Finished()) {
                yield();
            }
            MX::MapInfo@ map = MX::MapInfo(API::GetAsync("https://"+MXURL+"/api/maps/get_map_info/multi/"+mapId)[0]);
            mapDownloadInProgress = false;
            netMap.SaveToFile(mxDLFolder + "/" + map.TrackID + " - " + map.Name + ".Map.Gbx");
            print("Map downloaded to " + mxDLFolder + "/" + map.TrackID + " - " + map.Name + ".Map.Gbx");
        } catch {
            mxError("Error while downloading map");
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
                string url = "https://"+MXURL+"/api/maps/get_map_info/multi/" + UIDMap;
                if (req is null){
                    if (IsDevMode()) trace("LoadCurrentMap::StartRequest: " + url);
                    @req = API::Get(url);
                }

                if (req !is null && req.Finished()) {
                    string response = req.String();
                    @req = null;
                    if (IsDevMode()) trace("LoadCurrentMap::CheckResponse: " + response);

                    // Evaluate reqest result
                    Json::Value returnedObject = Json::Parse(response);
                    try {
                        if (returnedObject.get_Length() > 0) {
                            int g_MXId = returnedObject[0]["TrackID"];
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
}