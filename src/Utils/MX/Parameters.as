namespace MX
{
    array<MapTag@> m_mapTags;
    array<LeaderboardSeason@> m_leaderboardSeasons;
    array<Environment@> m_environments;

    Net::HttpRequest@ req;

    int mapToLoad = -1;
    int mapToEdit = -1;
    int mapToDL = -1;

    bool mapDownloadInProgress = false;

    bool APIDown = false;
    bool APIRefresh = true;
}