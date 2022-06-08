namespace ManiaExchange
{
    void ShowMapInfo(int mapID)
    {
        if (!mxMenu.isOpened) mxMenu.isOpened = true;
        mxMenu.AddTab(MapTab(mapID), true);
    }

    void ShowMapPackInfo(int mapPackID)
    {
        if (!mxMenu.isOpened) mxMenu.isOpened = true;
        mxMenu.AddTab(MapPackTab(mapPackID), true);
    }
}