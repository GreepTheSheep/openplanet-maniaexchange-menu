namespace MX
{
    array<MapTag@> m_mapTags;

    Net::HttpRequest@ req;

    int mapToLoad = -1;
    int mapToDL = -1;

    bool mapDownloadInProgress = false;
}