namespace ManiaExchange
{
    void ShowMapInfo(int mapID)
    {
        if (!mxMenu.isOpened) Setting_ShowMenu = true;
        mxMenu.AddTab(MapTab(mapID), true);
    }

    void ShowMapInfo(const string &in mapUid)
    {
        if (!mxMenu.isOpened) Setting_ShowMenu = true;
        mxMenu.AddTab(MapTab(mapUid), true);
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
        dictionary params;
        params.Set("fields", MX::mapFields);
        params.Set("id", tostring(mapID));
        string urlParams = MX::DictToApiParams(params);

        string url = "https://"+MXURL+"/api/maps" + urlParams;
        Logging::Debug("Exports::GetMapInfoAsync::StartRequest : "+url);
        Json::Value mxRes = API::GetAsync(url);
        if (mxRes.GetType() == Json::Type::Null || mxRes.Length == 0 || !mxRes.HasKey("Results") || mxRes["Results"].Length == 0) {
            Logging::Info("Exports::GetMapInfoAsync::CheckRequest : Error parsing response");
            return Json::Parse("");
        }
        // Handle the response
        return MX::MapInfo(mxRes["Results"][0]).ToJson();
    }

    Json::Value GetMapInfoAsync(const string &in MapUID)
    {
        dictionary params;
        params.Set("fields", MX::mapFields);
        params.Set("uid", MapUID);
        string urlParams = MX::DictToApiParams(params);

        string url = "https://"+MXURL+"/api/maps" + urlParams;
        Logging::Debug("Exports::GetMapInfoAsync::StartRequest : " + url);

        Json::Value mxRes = API::GetAsync(url);

        if (mxRes.GetType() == Json::Type::Null || mxRes.Length == 0 || !mxRes.HasKey("Results") || mxRes["Results"].Length == 0) {
            Logging::Info("Exports::GetMapInfoAsync::CheckRequest : Error parsing response");
            return Json::Parse("");
        }

        return MX::MapInfo(mxRes["Results"][0]).ToJson();
    }
}