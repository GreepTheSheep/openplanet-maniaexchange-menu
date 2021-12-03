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

        Json::Value ToJson()
        {
            Json::Value json = Json::Object();
            json["TrackID"] = TrackID;
            json["TrackUID"] = TrackUID;
            json["UserID"] = UserID;
            json["Username"] = Username;
            json["AuthorLogin"] = AuthorLogin;
            json["UploadedAt"] = UploadedAt;
            json["UpdatedAt"] = UpdatedAt;
            json["Name"] = Name;
            json["GbxMapName"] = GbxMapName;
            json["Comments"] = Comments;
            json["TitlePack"] = TitlePack;
            json["Unlisted"] = Unlisted;
            json["Mood"] = Mood;
            json["DisplayCost"] = DisplayCost;
            json["LengthName"] = LengthName;
            json["Laps"] = Laps;
            json["DifficultyName"] = DifficultyName;
            json["AuthorTime"] = AuthorTime;
            json["TrackValue"] = TrackValue;
            json["AwardCount"] = AwardCount;
            json["IsMP4"] = IsMP4;

            string tagsStr = "";
            for (uint i = 0; i < Tags.get_Length(); i++)
            {
                tagsStr += tostring(Tags[i].ID);
                if (i < Tags.get_Length() - 1) tagsStr += ",";
            }
            json["Tags"] = tagsStr;

            return json;
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