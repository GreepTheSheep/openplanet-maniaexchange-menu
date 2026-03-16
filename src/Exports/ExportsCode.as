namespace ManiaExchange
{
    void ShowMapInfo(int mapID)
    {
        if (!UI::IsOverlayShown()) UI::ShowOverlay();
        if (!mxMenu.isOpened) Setting_ShowMenu = true;
        mxMenu.AddTab(MapTab(mapID), true);
    }

    void ShowMapInfo(const string &in mapUid)
    {
        if (!UI::IsOverlayShown()) UI::ShowOverlay();
        if (!mxMenu.isOpened) Setting_ShowMenu = true;
        mxMenu.AddTab(MapTab(mapUid), true);
    }

    void ShowMapPackInfo(int mapPackID)
    {
        if (!UI::IsOverlayShown()) UI::ShowOverlay();
        if (!mxMenu.isOpened) Setting_ShowMenu = true;
        mxMenu.AddTab(MapPackTab(mapPackID), true);
    }

    void ShowUserInfo(int userID)
    {
        if (!UI::IsOverlayShown()) UI::ShowOverlay();
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
        MX::MapInfo@ map = MX::GetMapById(mapID);

        if (map is null) {
            Logging::Warn("[Exports::GetMapInfoAsync] Couldn't find a " + shortMXName + " map with the ID " + mapID);
            return Json::Parse("");
        }

        return map.ToJson();
    }

    Json::Value GetMapInfoAsync(const string &in MapUID)
    {
        MX::MapInfo@ map = MX::GetMapByUid(MapUID);

        if (map is null) {
            Logging::Warn("[Exports::GetMapInfoAsync] Couldn't find a " + shortMXName + " map with the UID " + MapUID);
            return Json::Parse("");
        }

        return map.ToJson();
    }
}