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
        int CommentCount;
        uint EmbeddedObjectsCount;
        int EmbeddedItemsSize;
        bool ServerSizeExceeded;
        array<MapImage@> Images;
        array<MapAuthorInfo@> Authors;
        array<MapTag@> Tags;
        bool m_isUploaded;

        // Leaderboard
        array<NadeoServices::LeaderboardRecord@> Records;
        Status m_recordsStatus;

        // Download
        Status m_downloadStatus;

        // Replays
        array<MapReplay@> Replays;
        Status m_replaysStatus;

        // Comments
        array<MapComment@> Comments;
        Status m_commentsStatus;

        // Objects
        array<MapEmbeddedObject@> Objects;
        Status m_objectsStatus;

        // For pagination
        bool LastItem;

        string MapPackName;
        Json::Value@ jsonCache;

        MapInfo(const Json::Value &in json) {
            try {
                MapId = json["MapId"];
                MapUid = json["MapUid"];
                Name = Format::GbxText(json["Name"]);
                if (json["OnlineMapId"].GetType() != Json::Type::Null) OnlineMapId = json["OnlineMapId"];
                MapType = json["MapType"];
                UploadedAt = json["UploadedAt"];
                if (json["GbxMapName"].GetType() != Json::Type::Null) GbxMapName = Format::GbxText(json["GbxMapName"]);
                if (json["AuthorComments"].GetType() != Json::Type::Null) AuthorComments = Format::MXText(json["AuthorComments"]);
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
                if (json.HasKey("CommentCount")) CommentCount = json["CommentCount"];
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
                Logging::Warn("Error parsing infos for the map " + Name + ": " + getExceptionInfo(), true);
            }
        }

        Json::Value ToJson() {
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
                json["CommentCount"] = CommentCount;
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
                Logging::Warn("Error converting map info to json for map " + Name + ": " + getExceptionInfo());
            }

            return json;
        }

        void PlayMap() {
            MX::LoadMap(MapId);
        }

        void EditMap() {
            MX::LoadMap(MapId, true);
        }

        // Download

        void DownloadMap() {
            m_downloadStatus = Status::Loading;

            MX::DownloadMap(this, MapPackName);

            m_downloadStatus = Status::Completed;
        }

        bool get_Downloading() { return m_downloadStatus == Status::Loading; }
        bool get_Downloaded()  { return m_downloadStatus == Status::Completed; }

        // Records

        void FetchRecords() {
            if (FetchedRecords || LoadingRecords) {
                return;
            }

            m_recordsStatus = Status::Loading;
#if DEPENDENCY_NADEOSERVICES
            Records = NadeoServices::GetMapRecords(MapUid);
#endif
            m_recordsStatus = Status::Completed;

#if DEPENDENCY_NADEOSERVICES
            NadeoServices::GetRecordsData(Records, OnlineMapId, GameMode);
#endif
        }

        void LoadMoreRecords() {
            if (!HasMoreRecords || LoadingRecords) {
                return;
            }

            m_recordsStatus = Status::Loading;

#if DEPENDENCY_NADEOSERVICES
            array<NadeoServices::LeaderboardRecord@> times = NadeoServices::GetMapRecords(MapUid, Records.Length);

            for (uint i = 0; i < times.Length; i++) {
                Records.InsertLast(times[i]);
            }
#endif

            m_recordsStatus = Status::Completed;

#if DEPENDENCY_NADEOSERVICES
            NadeoServices::GetRecordsData(times, OnlineMapId, GameMode);
#endif
        }

        bool get_HasMoreRecords() {
            // if Records is not a multiply of 100, there's no more records, since API returns 100 at a time
            return Records.Length % 100 == 0;
        }

        bool get_LoadingRecords() { return m_recordsStatus == Status::Loading; }
        bool get_FetchedRecords() { return m_recordsStatus == Status::Completed; }
        void set_FetchedRecords(bool b) { b ? m_recordsStatus = Status::Completed : m_recordsStatus = Status::Not_Started; }

        // Replays

        void FetchReplays() {
            if (FetchedReplays || LoadingReplays) {
                return;
            }

            m_replaysStatus = Status::Loading;
            Replays = MX::GetMapReplays(MapId);

            if (Replays.IsEmpty() && ReplayCount > 0) {
                m_replaysStatus = Status::Error;
            }

            m_replaysStatus = Status::Completed;
        }

        bool get_LoadingReplays() { return m_replaysStatus == Status::Loading; }
        bool get_ReplaysError() { return m_replaysStatus == Status::Error; }
        bool get_FetchedReplays() { return m_replaysStatus == Status::Completed; }
        void set_FetchedReplays(bool b) { b ? m_replaysStatus = Status::Completed : m_replaysStatus = Status::Not_Started; }

        // Comments

        void FetchComments() {
            if (FetchedComments || LoadingComments) {
                return;
            }

            m_commentsStatus = Status::Loading;
            Comments = MX::GetMapComments(MapId);

            if (Comments.IsEmpty() && CommentCount > 0) {
                m_commentsStatus = Status::Error;
            }

            m_commentsStatus = Status::Completed;
        }

        bool get_LoadingComments() { return m_commentsStatus == Status::Loading; }
        bool get_CommentsError() { return m_commentsStatus == Status::Error; }
        bool get_FetchedComments() { return m_commentsStatus == Status::Completed; }
        void set_FetchedComments(bool b) { b ? m_commentsStatus = Status::Completed : m_commentsStatus = Status::Not_Started; }

        // Objects

        void FetchObjects() {
            if (FetchedObjects || LoadingObjects) {
                return;
            }

            m_objectsStatus = Status::Loading;
            Objects = MX::GetMapObjects(MapId);

            if (Objects.IsEmpty() && EmbeddedObjectsCount > 0) {
                m_objectsStatus = Status::Error;
            }

            m_objectsStatus = Status::Completed;
        }

        bool get_LoadingObjects() { return m_objectsStatus == Status::Loading; }
        bool get_ObjectsError() { return m_objectsStatus == Status::Error; }
        bool get_FetchedObjects() { return m_objectsStatus == Status::Completed; }
        void set_FetchedObjects(bool b) { b ? m_objectsStatus = Status::Completed : m_objectsStatus = Status::Not_Started; }

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

        GameModes get_GameMode() {
            if (MapType == "Platform" || MapType == "TM_Platform") return GameModes::Platform;
            else if (MapType == "Puzzle") return GameModes::Puzzle;
            else if (MapType == "EW Stunts - Score Attack" || MapType == "Stunts" || MapType == "TM_Stunt") return GameModes::Stunt;
            else if (MapType == "TM_Royal") return GameModes::Royal;

            return GameModes::Race;
        }

        bool get_SupportsLeaderboard() {
            // Whether the map type supports online records (TMNEXT only)
            return GameMode == GameModes::Race || GameMode == GameModes::Stunt;
        }

        bool get_InPlayLater() {
            return g_PlayLaterMaps.Find(this) > -1;
        }

        bool get_InFavorites() {
            foreach (NadeoServices::MapInfo@ map : MXNadeoServicesGlobal::g_favoriteMaps) {
                if (MapUid == map.uid) {
                    return true;
                }
            }

            return false;
        }

#if DEPENDENCY_NADEOSERVICES
        void CheckIfUploaded() {
            if (OnlineMapId != "") {
                m_isUploaded = true;
                return;
            }

            m_isUploaded = MXNadeoServicesGlobal::CheckIfMapExistsAsync(MapUid);
        }
#endif

        bool get_IsUploadedToServers() { return m_isUploaded; }

        bool opEquals(MapInfo@ b) {
            return MapId == b.MapId || MapUid == b.MapUid;
        }
    }
}