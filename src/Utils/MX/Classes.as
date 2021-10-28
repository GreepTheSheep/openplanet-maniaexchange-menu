namespace MX
{
    class MapInfo
    {
        int TrackID;
        string TrackUID;
        int UserID;
        string Username;
        string AuthorLogin;
        string UploadedAt;
        string UpdatedAt;
        string Name;
        string GbxMapName;
        string Comments;
        string TitlePack;
        bool Hide;
        bool Unlisted;
        string Mood;
        int DisplayCost;
        string ModName;
        string LengthName;
        int Laps;
        string DifficultyName;
        int AuthorTime;
        int TrackValue;
        int AwardCount;
        bool IsMP4;
        array<MapTag@> Tags;
    }

    class MapTag
    {
        int ID;
        string Name;
        string Color;
    }
}