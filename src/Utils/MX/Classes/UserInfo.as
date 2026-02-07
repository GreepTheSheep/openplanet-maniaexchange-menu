namespace MX
{
    class UserInfo
    {
        int UserId;
        string Name;
        string IngameLogin;
        string Bio;
        string RegisteredAt;
        int RegisteredTimestamp;
        int MapCount;
        int MappackCount;
        int ReplayCount;
        int AwardsReceivedCount;
        int AwardsGivenCount;
        int CommentsReceivedCount;
        int CommentsGivenCount;
        int FavoritesReceivedCount;
        int VideosReceivedCount;
        int VideosPostedCount;
        int VideosCreatedCount;
        int FeaturedTrackID;
        int AchievementCount;

        // Featured map
        MapInfo@ FeaturedMap;
        Status m_featuredStatus;

        // Created maps
        array<MapInfo@> CreatedMaps;
        Status m_createdStatus;
        MapColumns@ createdWidths = MapColumns();

        // Awarded maps
        array<MapInfo@> AwardedMaps;
        Status m_awardedStatus;
        MapColumns@ awardedWidths = MapColumns();

        // Mappacks
        array<MapPackInfo@> Mappacks;
        Status m_mappacksStatus;

        // For pagination
        bool LastItem;

        UserInfo(const Json::Value &in json)
        {
            try {
                UserId = json["UserId"];
                Name = json["Name"];
                if (json["IngameLogin"].GetType() != Json::Type::Null) IngameLogin = json["IngameLogin"];
                if (json["Bio"].GetType() != Json::Type::Null) Bio = Format::MXText(json["Bio"]);
                RegisteredAt = json["RegisteredAt"];
                MapCount = json["MapCount"];
                MappackCount = json["MappackCount"];
                ReplayCount = json["ReplayCount"];
                AwardsReceivedCount = json["AwardsReceivedCount"];
                AwardsGivenCount = json["AwardsGivenCount"];
                CommentsReceivedCount = json["CommentsReceivedCount"];
                CommentsGivenCount = json["CommentsGivenCount"];
                FavoritesReceivedCount = json["FavoritesReceivedCount"];
                VideosReceivedCount = json["VideosReceivedCount"];
                VideosPostedCount = json["VideosPostedCount"];
                VideosCreatedCount = json["VideosCreatedCount"];
                AchievementCount = json["AchievementCount"];
                // FeaturedTrackID = json["FeaturedTrackID"]; // TODO missing

                try {
                    RegisteredTimestamp = Time::ParseFormatString("%FT%T", RegisteredAt);
                } catch {
                    RegisteredTimestamp = 0;
                }
            } catch {
                Logging::Warn("Error parsing user info for user " + Name + ": " + getExceptionInfo(), true);
                Logging::Debug(Json::Write(ToJson()));
            }
        }

        Json::Value ToJson()
        {
            Json::Value json = Json::Object();
            try {
                json["UserId"] = UserId;
                json["Name"] = Name;
                json["IngameLogin"] = IngameLogin;
                json["Bio"] = Bio;
                json["RegisteredAt"] = RegisteredAt;
                json["MapCount"] = MapCount;
                json["MappackCount"] = MappackCount;
                json["ReplayCount"] = ReplayCount;
                json["AwardsReceivedCount"] = AwardsReceivedCount;
                json["AwardsGivenCount"] = AwardsGivenCount;
                json["CommentsReceivedCount"] = CommentsReceivedCount;
                json["CommentsGivenCount"] = CommentsGivenCount;
                json["FavoritesReceivedCount"] = FavoritesReceivedCount;
                json["VideosReceivedCount"] = VideosReceivedCount;
                json["VideosPostedCount"] = VideosPostedCount;
                json["VideosCreatedCount"] = VideosCreatedCount;
                json["AchievementCount"] = AchievementCount;
                // json["FeaturedTrackID"] = FeaturedTrackID; // TODO missing
            } catch {
                Logging::Warn("Error converting user info to json for user " + Name + ": " + getExceptionInfo(), true);
            }
            return json;
        }

        // Featured

        bool get_HasFeaturedMap() {
            return FeaturedTrackID > 0;
        }

        bool get_FeaturedMapError()   { return m_featuredStatus == Status::Error; }
        bool get_LoadingFeaturedMap() { return m_featuredStatus == Status::Loading; }
        bool get_FetchedFeaturedMap() { return m_featuredStatus == Status::Completed; }
        void set_FetchedFeaturedMap(bool b) { b ? m_featuredStatus = Status::Completed : m_featuredStatus = Status::Not_Started; }

        void FetchFeaturedMap() {
            if (!HasFeaturedMap || FetchedFeaturedMap) {
                return;
            }

            m_featuredStatus = Status::Loading;
            @FeaturedMap = MX::GetMapById(FeaturedTrackID);
            m_featuredStatus = Status::Completed;

            if (FeaturedMap is null) {
                m_featuredStatus = Status::Error;
            }
        }

        // Created

        bool get_CreatedMapsError()   { return m_createdStatus == Status::Error; }
        bool get_LoadingCreatedMaps() { return m_createdStatus == Status::Loading; }
        bool get_FetchedCreatedMaps() { return m_createdStatus == Status::Completed; }
        void set_FetchedCreatedMaps(bool b) { b ? m_createdStatus = Status::Completed : m_createdStatus = Status::Not_Started; }

        bool get_MoreCreatedItems() {
            if (CreatedMaps.IsEmpty()) {
                return true;
            }

            return !CreatedMaps[CreatedMaps.Length - 1].LastItem;
        }

        int get_LastCreatedMapsId() {
            if (CreatedMaps.IsEmpty()) {
                return 0;
            }

            return CreatedMaps[CreatedMaps.Length - 1].MapId;
        }

        void FetchCreatedMaps() {
            if (FetchedCreatedMaps || LoadingCreatedMaps) {
                return;
            }

            m_createdStatus = Status::Loading;

            dictionary parameters = {
                { "fields", MX::mapFields },
                { "count", "100" },
                { "authoruserid", tostring(UserId) }
            };

            CreatedMaps = MX::GetMaps(parameters);
            m_createdStatus = Status::Completed;

            if (CreatedMaps.IsEmpty()) {
                m_createdStatus = Status::Error;
            }

            createdWidths.Update(CreatedMaps);
        }

        void LoadMoreCreated() {
            if (!MoreCreatedItems || LoadingCreatedMaps) {
                return;
            }

            m_createdStatus = Status::Loading;

            dictionary parameters = {
                { "fields", MX::mapFields },
                { "count", "100" },
                { "authoruserid", tostring(UserId) },
                { "after", tostring(LastCreatedMapsId) }
            };

            array<MapInfo@> maps = MX::GetMaps(parameters);

            for (uint i = 0; i < maps.Length; i++) {
                CreatedMaps.InsertLast(maps[i]);
            }

            createdWidths.Update(CreatedMaps);

            m_createdStatus = Status::Completed;
        }

        // Awarded

        bool get_AwardedMapsError()   { return m_awardedStatus == Status::Error; }
        bool get_LoadingAwardedMaps() { return m_awardedStatus == Status::Loading; }
        bool get_FetchedAwardedMaps() { return m_awardedStatus == Status::Completed; }
        void set_FetchedAwardedMaps(bool b) { b ? m_awardedStatus = Status::Completed : m_awardedStatus = Status::Not_Started; }

        bool get_MoreAwardedItems() {
            if (AwardedMaps.IsEmpty()) {
                return true;
            }

            return !AwardedMaps[AwardedMaps.Length - 1].LastItem;
        }

        int get_LastAwardedMapsId() {
            if (AwardedMaps.IsEmpty()) {
                return 0;
            }

            return AwardedMaps[AwardedMaps.Length - 1].MapId;
        }

        void FetchAwardedMaps() {
            if (FetchedAwardedMaps || LoadingAwardedMaps) {
                return;
            }

            m_awardedStatus = Status::Loading;

            dictionary parameters = {
                { "fields", MX::mapFields },
                { "count", "100" },
                { "awardedby", Name },
                { "order1", "24"}
            };

            AwardedMaps = MX::GetMaps(parameters);
            m_awardedStatus = Status::Completed;

            if (AwardedMaps.IsEmpty()) {
                m_awardedStatus = Status::Error;
            }

            awardedWidths.Update(AwardedMaps);
        }

        void LoadMoreAwarded() {
            if (!MoreAwardedItems || LoadingAwardedMaps) {
                return;
            }

            m_awardedStatus = Status::Loading;

            dictionary parameters = {
                { "fields", MX::mapFields },
                { "count", "100" },
                { "awardedby", Name },
                { "order1", "24"},
                { "after", tostring(LastAwardedMapsId) }
            };

            array<MapInfo@> maps = MX::GetMaps(parameters);

            for (uint i = 0; i < maps.Length; i++) {
                AwardedMaps.InsertLast(maps[i]);
            }

            awardedWidths.Update(AwardedMaps);

            m_awardedStatus = Status::Completed;
        }

        // Mappacks

        bool get_MappacksError()   { return m_mappacksStatus == Status::Error; }
        bool get_LoadingMappacks() { return m_mappacksStatus == Status::Loading; }
        bool get_FetchedMappacks() { return m_mappacksStatus == Status::Completed; }
        void set_FetchedMappacks(bool b) { b ? m_mappacksStatus = Status::Completed : m_mappacksStatus = Status::Not_Started; }

        bool get_MoreMappacksItems() {
            if (Mappacks.IsEmpty()) {
                return true;
            }

            return !Mappacks[Mappacks.Length - 1].LastItem;
        }

        int get_LastMappacksId() {
            if (Mappacks.IsEmpty()) {
                return 0;
            }

            return Mappacks[Mappacks.Length - 1].MappackId;
        }

        void FetchMappacks() {
            if (FetchedMappacks || LoadingMappacks) {
                return;
            }

            m_mappacksStatus = Status::Loading;

            dictionary parameters = {
                { "fields", MX::mapPackFields },
                { "count", "100" },
                { "owneruserid", tostring(UserId) },
                { "order1", "3"}
            };

            Mappacks = MX::GetMappacks(parameters);
            m_mappacksStatus = Status::Completed;

            if (Mappacks.IsEmpty()) {
                m_mappacksStatus = Status::Error;
            }
        }

        void LoadMoreMappacks() {
            if (!MoreMappacksItems || LoadingMappacks) {
                return;
            }

            m_mappacksStatus = Status::Loading;

            dictionary parameters = {
                { "fields", MX::mapPackFields },
                { "count", "100" },
                { "owneruserid", tostring(UserId) },
                { "order1", "3"},
                { "after", tostring(LastMappacksId) }
            };

            array<MapPackInfo@> packs = MX::GetMappacks(parameters);

            for (uint i = 0; i < packs.Length; i++) {
                Mappacks.InsertLast(packs[i]);
            }

            m_mappacksStatus = Status::Completed;
        }
    }
}