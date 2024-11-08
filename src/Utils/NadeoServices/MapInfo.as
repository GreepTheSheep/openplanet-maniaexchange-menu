namespace NadeoServices
{
    class MapInfo
    {
        string uid;
        string mapId;
        string name;
        string author;
        string authorUsername;
        uint authorTime;
        uint goldTime;
        uint silverTime;
        uint bronzeTime;
        int nbLaps;
        bool valid;
        string downloadUrl;
        string thumbnailUrl;
        int uploadTimestamp;
        int updateTimestamp;
        int fileSize;
        bool public;
        bool favorite;
        bool playable;
        string mapStyle;
        string mapType;
        string collectionName;
        int MXId;
        MX::MapInfo@ MXMapInfo;
        Json::Value@ jsonCache;

        MapInfo(const Json::Value &in json)
        {
            try {
                uid = json["uid"];
                mapId = json["mapId"];
                name = json["name"];
                author = json["author"];
                authorTime = json["authorTime"];
                goldTime = json["goldTime"];
                silverTime = json["silverTime"];
                bronzeTime = json["bronzeTime"];
                nbLaps = json["nbLaps"];
                valid = json["valid"];
                downloadUrl = json["downloadUrl"];
                thumbnailUrl = json["thumbnailUrl"];
                uploadTimestamp = json["uploadTimestamp"];
                updateTimestamp = json["updateTimestamp"];
                if (json["fileSize"].GetType() != Json::Type::Null) fileSize = json["fileSize"];
                public = json["public"];
                favorite = json["favorite"];
                playable = json["playable"];
                mapStyle = json["mapStyle"];
                mapType = json["mapType"];
                collectionName = json["collectionName"];

                @jsonCache = ToJson();
            } catch {
                mxWarn("Error parsing infos for map: " + name);
            }
        }

        Json::Value ToJson()
        {
            if (jsonCache !is null) return jsonCache;

            Json::Value json = Json::Object();
            try {
                json["uid"] = uid;
                json["mapId"] = mapId;
                json["name"] = name;
                json["author"] = author;
                json["authorTime"] = authorTime;
                json["goldTime"] = goldTime;
                json["silverTime"] = silverTime;
                json["bronzeTime"] = bronzeTime;
                json["nbLaps"] = nbLaps;
                json["valid"] = valid;
                json["downloadUrl"] = downloadUrl;
                json["thumbnailUrl"] = thumbnailUrl;
                json["uploadTimestamp"] = uploadTimestamp;
                json["updateTimestamp"] = updateTimestamp;
                json["fileSize"] = fileSize;
                json["public"] = public;
                json["favorite"] = favorite;
                json["playable"] = playable;
                json["mapStyle"] = mapStyle;
                json["mapType"] = mapType;
                json["collectionName"] = collectionName;
            } catch {
                mxWarn("Error converting map info to json for map " + name);
            }

            return json;
        }
    }
}