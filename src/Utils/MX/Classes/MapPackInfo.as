namespace MX
{
    class MapPackInfo
    {
        int MappackId;
        int UserId;
        string Username;
        string CreatedAt;
        string UpdatedAt;
        string Description;
        string Name;
        int Type;
        bool IsPublic;
        bool MaplistReleased;
        bool Downloadable;
        bool IsRequest;
        int MapCount;
        array<MapTag@> Tags;

        MapPackInfo(const Json::Value &in json)
        {
            try {
                MappackId = json["MappackId"];
                Name = json["Name"];
                CreatedAt = json["CreatedAt"];
                if (json["Description"].GetType() != Json::Type::Null) Description = Format::MXText(json["Description"]);
                Type = json["Type"];
                IsPublic = json["IsPublic"];
                MaplistReleased = json["MaplistReleased"];
                Downloadable = json["Downloadable"];
                IsRequest = json["IsRequest"];
                MapCount = json["MapCount"];

                if (json["UpdatedAt"].GetType() != Json::Type::Null) {
                    UpdatedAt = json["UpdatedAt"];
                } else {
                    UpdatedAt = json["CreatedAt"];
                }

                if (json["Owner"].GetType() != Json::Type::Null) {
                    UserId = json["Owner"]["UserId"];
                    Username = json["Owner"]["Name"];
                }

                // Tags is an array of tag objects
                if (json["Tags"].GetType() != Json::Type::Null) {
                    const Json::Value@ tagObjects = json["Tags"];

                    for (uint i = 0; i < tagObjects.Length; i++)
                    {
                        for (uint j = 0; j < m_mapTags.Length; j++)
                        {
                            if (m_mapTags[j].ID == tagObjects[i]["TagId"]) {
                                Tags.InsertLast(m_mapTags[j]);
                                break;
                            }
                        }
                    }
                }
            } catch {
                Name = json["Name"];
                Logging::Warn("Error parsing infos for the map pack " + Name + ": " + getExceptionInfo(), true);
            }
        }

        Json::Value ToJson()
        {
            Json::Value json = Json::Object();
            try {
                json["MappackId"] = MappackId;
                json["UserId"] = UserId;
                json["Username"] = Username;
                json["CreatedAt"] = CreatedAt;
                json["UpdatedAt"] = UpdatedAt;
                json["Description"] = Description;
                json["Name"] = Name;
                json["Type"] = Type;
                json["IsPublic"] = IsPublic;
                json["MaplistReleased"] = MaplistReleased;
                json["Downloadable"] = Downloadable;
                json["IsRequest"] = IsRequest;
                json["MapCount"] = MapCount;

                Json::Value ownerObject = Json::Object();
                ownerObject["UserId"] = UserId;
                ownerObject["Name"] = Username;

                json["Owner"] = ownerObject;

                Json::Value tagArray = Json::Array();
                for (uint i = 0; i < Tags.Length; i++)
                {
                    tagArray.Add(Tags[i].ToJson());
                }

                json["Tags"] = tagArray;
            } catch {
                Logging::Warn("Error converting map pack info to json for map pack " + Name + ": " + getExceptionInfo(), true);
            }
            return json;
        }

        string get_TypeName() {
            return tostring(MappackTypes(Type));
        }
    }
}