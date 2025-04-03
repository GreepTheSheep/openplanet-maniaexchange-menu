namespace MX
{
    class UserInfo
    {
        int UserId;
        string Name;
        string IngameLogin;
        string Bio;
        string RegisteredAt;
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

        UserInfo(const Json::Value &in json)
        {
            try {
                UserId = json["UserId"];
                Name = json["Name"];
                if (json["IngameLogin"].GetType() != Json::Type::Null) IngameLogin = json["IngameLogin"];
                if (json["Bio"].GetType() != Json::Type::Null) Bio = json["Bio"];
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
                // FeaturedTrackID = json["FeaturedTrackID"]; // TODO missing
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
                // json["FeaturedTrackID"] = FeaturedTrackID; // TODO missing
            } catch {
                Logging::Warn("Error converting user info to json for user " + Name + ": " + getExceptionInfo(), true);
            }
            return json;
        }
    }
}