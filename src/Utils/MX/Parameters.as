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
    array<SortingOrder@> m_userSortingOrders;

    Net::HttpRequest@ req;

    bool mapDownloadInProgress = false;

    bool APIDown = false;
    bool APIRefresh = true;
}