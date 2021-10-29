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

        if (IsDevMode()) log(m_mapTags.get_Length() + " tags loaded");
    }

    void LookForMapToLoad(){
        while(true){
            yield();
            if (mapToLoad != -1){
                LoadMap(mapToLoad);
                mapToLoad = -1;
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
}