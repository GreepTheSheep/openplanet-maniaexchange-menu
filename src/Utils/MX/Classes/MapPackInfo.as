namespace MX
{
    class MapPackInfo
    {
        int ID;
        int UserID;
        string Username;
        string Created;
        string Edited;
        string Description;
        string Name;
        string TypeName;
        bool Unreleased;
        bool Downloadable;
        int Downloads;
        bool Request;
        int TrackCount;
        array<MapTag@> Tags;

        MapPackInfo(const Json::Value &in json)
        {
            try {
                ID = json["ID"];
                UserID = json["UserID"];
                Username = json["Username"];
                Created = json["Created"];
                Edited = json["Edited"];
                Description = json["Description"];
                Name = json["Name"];
                TypeName = json["TypeName"];
                Unreleased = json["Unreleased"];
                Downloadable = json["Downloadable"];
                Downloads = json["Downloads"];
                Request = json["Request"];
                TrackCount = json["TrackCount"];

                // Tags is a string of ids separated by commas
                // gets the ids and fetches the tags from m_mapTags
                string tagIds = json["TagsString"];
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
            } catch {
                Name = json["Name"];
                mxWarn("Error parsing infos for the map pack: "+ Name, true);
            }
        }

        Json::Value ToJson()
        {
            Json::Value json = Json::Object();
            try {
                json["ID"] = ID;
                json["UserID"] = UserID;
                json["Username"] = Username;
                json["Created"] = Created;
                json["Edited"] = Edited;
                json["Description"] = Description;
                json["Name"] = Name;
                json["TypeName"] = TypeName;
                json["Unreleased"] = Unreleased;
                json["Downloadable"] = Downloadable;
                json["Downloads"] = Downloads;
                json["Request"] = Request;
                json["TrackCount"] = TrackCount;

                string tagsStr = "";
                for (uint i = 0; i < Tags.get_Length(); i++)
                {
                    tagsStr += tostring(Tags[i].ID);
                    if (i < Tags.get_Length() - 1) tagsStr += ",";
                }
                json["Tags"] = tagsStr;
            } catch {
                mxWarn("Error converting map pack info to json for map pack "+Name, true);
            }
            return json;
        }
    }
}