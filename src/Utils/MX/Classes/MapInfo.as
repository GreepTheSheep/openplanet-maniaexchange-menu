namespace MX
{
    class MapInfo
    {
        int MapId;
        string MapUid;
        string Name;
        string OnlineMapId;
        int UserId;
        string Username;
        string MapType;
        string UploadedAt;
        string UpdatedAt;
        string GbxMapName;
        string AuthorComments;
        string TitlePack;
        string Mood;
        int DisplayCost;
        int Laps;
        int Environment;
        int Difficulty;
        string VehicleName;
        int Length;
        int AuthorTime;
        int TrackValue;
        int AwardCount;
        int ReplayCount;
        uint EmbeddedObjectsCount;
        int EmbeddedItemsSize;
        bool ServerSizeExceeded;
        array<MapImage@> Images;
        array<MapAuthorInfo@> Authors;
        array<MapTag@> Tags;

        string MapPackName;
        Json::Value@ jsonCache;

        MapInfo(const Json::Value &in json)
        {
            try {
                MapId = json["MapId"];
                MapUid = json["MapUid"];
                Name = json["Name"];
                if (json["OnlineMapId"].GetType() != Json::Type::Null) OnlineMapId = json["OnlineMapId"];
                MapType = json["MapType"];
                UploadedAt = json["UploadedAt"];
                if (json["GbxMapName"].GetType() != Json::Type::Null) GbxMapName = json["GbxMapName"];
                if (json["AuthorComments"].GetType() != Json::Type::Null) AuthorComments = json["AuthorComments"];
                TitlePack = json["TitlePack"];
                Mood = json["Mood"];
                DisplayCost = json["DisplayCost"];
                Laps = json["Laps"];
                Environment = json["Environment"];
                Difficulty = json["Difficulty"];
                VehicleName = json["VehicleName"];
                TrackValue = json["TrackValue"];
                AwardCount = json["AwardCount"];
                ReplayCount = json["ReplayCount"];
                EmbeddedObjectsCount = json["EmbeddedObjectsCount"];
                EmbeddedItemsSize = json["EmbeddedItemsSize"];
                ServerSizeExceeded = json["ServerSizeExceeded"];
    
                if (json["UpdatedAt"].GetType() != Json::Type::Null) {
                    UpdatedAt = json["UpdatedAt"];
                } else {
                    UpdatedAt = json["UploadedAt"];
                }

                if (json["Images"].GetType() != Json::Type::Null) {
                    const Json::Value@ imagesObject = json["Images"];

                    for (uint i = 0; i < imagesObject.Length; i++) {
                        Images.InsertLast(MapImage(imagesObject[i]));
                    }
                }

                if (json["Uploader"].GetType() != Json::Type::Null) {
                    UserId = json["Uploader"]["UserId"];
                    Username = json["Uploader"]["Name"];
                }

                if (json["Medals"].GetType() != Json::Type::Null) {
                    AuthorTime = json["Medals"]["Author"];
                }

                if (json["Length"].GetType() != Json::Type::Null) {
                    Length = json["Length"];
                } else {
                    Length = AuthorTime;
                }

                if (json["Authors"].GetType() != Json::Type::Null) {
                    const Json::Value@ authorsObjects = json["Authors"];

                    for (uint i = 0; i < authorsObjects.Length; i++) {
                        bool IsUploader = string(authorsObjects[i]["User"]["Name"]) == string(json["Uploader"]["Name"]);
                        Authors.InsertLast(MapAuthorInfo(authorsObjects[i], IsUploader));
                    }
                }

                // Tags is an array of tag objects
                if (json["Tags"].GetType() != Json::Type::Null) {
                    const Json::Value@ tagObjects = json["Tags"];

                    for (uint i = 0; i < tagObjects.Length; i++) {
                        for (uint j = 0; j < m_mapTags.Length; j++) {
                            if (m_mapTags[j].ID == tagObjects[i]["TagId"]) {
                                Tags.InsertLast(m_mapTags[j]);
                                break;
                            }
                        }
                    }
                }

                @jsonCache = ToJson();
            } catch {
                Name = json["Name"];
                mxWarn("Error parsing infos for the map " + Name + ": " + getExceptionInfo(), true);
            }
        }

        Json::Value ToJson()
        {
            if (jsonCache !is null) return jsonCache;
            Json::Value json = Json::Object();
            try {
                json["MapId"] = MapId;
                json["MapUid"] = MapUid;
                json["Name"] = Name;
                json["OnlineMapId"] = OnlineMapId;
                json["MapType"] = MapType;
                json["UploadedAt"] = UploadedAt;
                json["UpdatedAt"] = UpdatedAt;
                json["GbxMapName"] = GbxMapName;
                json["AuthorComments"] = AuthorComments;
                json["TitlePack"] = TitlePack;
                json["Mood"] = Mood;
                json["DisplayCost"] = DisplayCost;
                json["Laps"] = Laps;
                json["Environment"] = Environment;
                json["Difficulty"] = Difficulty;
                json["Length"] = Length;
                json["VehicleName"] = VehicleName;
                json["TrackValue"] = TrackValue;
                json["AwardCount"] = AwardCount;
                json["ReplayCount"] = ReplayCount;
                json["EmbeddedObjectsCount"] = EmbeddedObjectsCount;
                json["EmbeddedItemsSize"] = EmbeddedItemsSize;
                json["ServerSizeExceeded"] = ServerSizeExceeded;

                Json::Value uploaderObject = Json::Object();
                uploaderObject["UserId"] = UserId;
                uploaderObject["Name"] = Username;

                json["Uploader"] = uploaderObject;

                Json::Value medalsObject = Json::Object();
                medalsObject["Author"] = AuthorTime;

                json["Medals"] = medalsObject;

                Json::Value imagesArray = Json::Array();
                for (uint i = 0; i < Images.Length; i++) {
                    imagesArray.Add(Images[i].ToJson());
                }

                json["Images"] = imagesArray;

                Json::Value authorsArray = Json::Array();
                for (uint i = 0; i < Authors.Length; i++) {
                    authorsArray.Add(Authors[i].ToJson());
                }

                json["Authors"] = authorsArray;

                Json::Value tagArray = Json::Array();
                for (uint i = 0; i < Tags.Length; i++) {
                    tagArray.Add(Tags[i].ToJson());
                }

                json["Tags"] = tagArray;

                // Legacy
                json["TrackID"] = MapId;
                json["TrackUID"] = MapUid;
            } catch {
                mxWarn("Error converting map info to json for map " + Name + ": " + getExceptionInfo());
            }
            return json;
        }

        void PlayMap()
        {
            MX::LoadMap(MapId);
        }

        void EditMap()
        {
            MX::LoadMap(MapId, true);
        }

        void DownloadMap()
        {
            MX::DownloadMap(MapId, MapPackName);
        }

        string get_DifficultyName() {
            return tostring(Difficulties(Difficulty));
        }

        string get_EnvironmentName() {
            for (uint i =  0; i < m_environments.Length; i++) {
                if (m_environments[i].ID == Environment) {
                    return m_environments[i].Name;
                }
            }
            return "Unknown";
        }
    }
}