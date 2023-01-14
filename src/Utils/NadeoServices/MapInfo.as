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
            } catch {
                mxWarn("Error parsing infos for map: " + name);
            }
        }
    }
}