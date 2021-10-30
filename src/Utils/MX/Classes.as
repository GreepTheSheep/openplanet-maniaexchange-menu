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
        string LengthName;
        int Laps;
        string DifficultyName;
        int AuthorTime;
        int TrackValue;
        int AwardCount;
        bool IsMP4;
        array<MapTag@> Tags;

        MapInfo(const Json::Value &in json)
        {
            TrackID = json["TrackID"];
            TrackUID = json["TrackUID"];
            UserID = json["UserID"];
            Username = json["Username"];
            AuthorLogin = json["AuthorLogin"];
            UploadedAt = json["UploadedAt"];
            UpdatedAt = json["UpdatedAt"];
            Name = json["Name"];
            GbxMapName = json["GbxMapName"];
            Comments = json["Comments"];
            TitlePack = json["TitlePack"];
            Hide = json["Hide"];
            Unlisted = json["Unlisted"];
            Mood = json["Mood"];
            DisplayCost = json["DisplayCost"];
            LengthName = json["LengthName"];
            Laps = json["Laps"];
            DifficultyName = json["DifficultyName"];
            AuthorTime = json["AuthorTime"];
            TrackValue = json["TrackValue"];
            AwardCount = json["AwardCount"];
            IsMP4 = json["IsMP4"];

            // Tags is a string of ids separated by commas
            // gets the ids and fetches the tags from m_mapTags
            string tagIds = json["Tags"];
            string[] tagIdsSplit = tagIds.Split(",");
            for (uint i = 0; i < tagIdsSplit.get_Length(); i++)
            {
                int tagId = Text::ParseInt(tagIdsSplit[i]);
                //int tagIndex = m_mapTags.Find(a>a.ID == tagId);
                //Tags.InsertLast(m_mapTags[tagIndex]);
                for (uint j = 0; j < m_mapTags.get_Length(); j++)
                {
                    if (m_mapTags[j].ID == tagId)
                    {
                        Tags.InsertLast(m_mapTags[j]);
                        break;
                    }
                }
            }
        }
    }

    class MapTag
    {
        int ID;
        string Name;
        string Color;

        MapTag(const Json::Value &in json)
        {
            ID = json["ID"];
            Name = json["Name"];
            Color = json["Color"];
        }
    }
}