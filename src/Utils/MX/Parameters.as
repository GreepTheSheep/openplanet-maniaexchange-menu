namespace MX
{
    array<MapTag@> m_mapTags;
    array<LeaderboardSeason@> m_leaderboardSeasons;
    array<MapEnvironment@> m_environments;
    array<string> m_vehicles;
    array<string> m_titlepacks;
    array<string> m_maptypes;
    array<SortingOrder@> m_mapSortingOrders;
    array<SortingOrder@> m_mappackSortingOrders;

    Net::HttpRequest@ req;

    int mapToLoad = -1;
    int mapToEdit = -1;
    int mapToDL = -1;

    bool mapDownloadInProgress = false;

    bool APIDown = false;
    bool APIRefresh = true;
}