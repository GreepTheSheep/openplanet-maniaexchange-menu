namespace MX
{
    void GetAllMapTags()
    {
        Json::Value resNet = API::GetAsync("https://"+MXURL+"/api/tags/gettags");
        
        for (uint i = 0; i < resNet.get_Length(); i++)
        {
            int tagID = resNet[i]["ID"];
            string tagName = resNet[i]["Name"];

            if (IsDevMode()) log("Loading tag #"+tagID+" - "+tagName);

            m_mapTags.InsertLast(MapTag(resNet[i]));
        }

        log(m_mapTags.get_Length() + " tags loaded");
    }

    void LookForMapToLoad(){
        while(true){
            yield();
            if (mapToLoad != -1){
                LoadMap(mapToLoad);
                mapToLoad = -1;
            }
            if (mapToDL != -1){
                DownloadMap(mapToDL);
                mapToDL = -1;
            }
        }
    }

    void LoadMap(int mapId)
    {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        app.BackToMainMenu(); // If we're on a map, go back to the main menu else we'll get stuck on the current map
        while(!app.ManiaTitleControlScriptAPI.IsReady) {
            yield(); // Wait until the ManiaTitleControlScriptAPI is ready for loading the next map
        }
        app.ManiaTitleControlScriptAPI.PlayMap("https://"+MXURL+"/maps/download/"+mapId, "", "");
    }

    void DownloadMap(int mapId)
    {
        string downloadedMapFolder = UserMapsFolder() + "Downloaded";
        string mxDLFolder = downloadedMapFolder + "/ManiaExchange";
        if (!IO::FolderExists(downloadedMapFolder)) IO::CreateFolder(downloadedMapFolder);
        if (!IO::FolderExists(mxDLFolder)) IO::CreateFolder(mxDLFolder);

        Net::HttpRequest@ netMap = API::Get("https://"+MXURL+"/maps/download/"+mapId);
        mapDownloadInProgress = true;
        while(!netMap.Finished()) {
            yield();
        }
        mapDownloadInProgress = false;
        netMap.SaveToFile(mxDLFolder + "/" + mapId + ".Map.Gbx");
        log("Map downloaded to " + mxDLFolder + "/" + mapId + ".Map.Gbx");
    }

    void CheckCurrentMap()
    {
        while (true){
            yield();
            auto currentMap = GetCurrentMap();
            if (currentMap !is null){
                if (currentMapID < 0 && currentMapID != -1) {
                    currentMapID = MX::GetCurrentMapMXID();
                    if (currentMapID < 0 && currentMapID != -3) {
                        if (IsDevMode()) log("MX ID error: " + currentMapID);
                        sleep(30000);
                    }
                }
            } else {
                currentMapID = -4;
            }
        }
    }

    /* 
    * MX ID Error codes:
    * > 0 = MX ID
    * -1 = Map not found
    * -2 = Server error
    * -3 = Loading request
    * -4 = Not in a map
    */
    int GetCurrentMapMXID(){
        auto currentMap = GetCurrentMap();
        if (currentMap !is null) {
            string UIDMap = currentMap.MapInfo.MapUid;
            string url = "https://"+MXURL+"/api/maps/get_map_info/multi/" + UIDMap;
            if (req is null){
                if (IsDevMode()) log("LoadCurrentMap::StartRequest: " + url);
                @req = API::Get(url);
            }
            
            if (req !is null && req.Finished()) {
                string response = req.String();
                @req = null;
                if (IsDevMode()) log("LoadCurrentMap::CheckResponse: " + response);

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
    }
}