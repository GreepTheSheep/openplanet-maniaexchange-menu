namespace ManiaExchange
{
    void ShowMapInfo(int mapID)
    {
        if (!mxMenu.isOpened) Setting_ShowMenu = true;
        mxMenu.AddTab(MapTab(mapID), true);
    }

    void ShowMapPackInfo(int mapPackID)
    {
        if (!mxMenu.isOpened) Setting_ShowMenu = true;
        mxMenu.AddTab(MapPackTab(mapPackID), true);
    }

    void ShowUserInfo(int userID)
    {
        if (!mxMenu.isOpened) Setting_ShowMenu = true;
        mxMenu.AddTab(UserTab(userID), true);
    }

    int GetCurrentMapID()
    {
        return currentMapID;
    }

    Json::Value GetCurrentMapInfo()
    {
        return currentMapInfo.ToJson();
    }

    Json::Value GetMapInfoAsync(int mapID)
    {
        string url = "https://"+MXURL+"/api/maps/get_map_info/multi/"+mapID;
        if (isDevMode) print("Exports::GetMapInfoAsync::StartRequest : "+url);
        Json::Value mxRes = API::GetAsync(url);
        if (mxRes.Length == 0) {
            if (isDevMode) print("Exports::GetMapInfoAsync::CheckRequest : Error parsing response");
            return Json::Parse("");
        }
        // Handle the response
        return MX::MapInfo(mxRes[0]).ToJson();
    }
}