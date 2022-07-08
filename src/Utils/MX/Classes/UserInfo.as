namespace MX
{
    class UserInfo
    {
        int UserID;
        string Username;
        string PlayerLogin;
        string UplayLogin;
        string Comments;
        bool IsDuo;
        string Registered;
        int TrackCount;
        int MappackCount;
        int ReplayCount;
        int AwardsReceived;
        int AwardsGiven;
        int CommentsReceived;
        int CommentsGiven;
        int FavouritesCount;
        int FavouritesGivenCount;
        int VideosReceivedCount;
        int VideosSubmittedCount;
        int VideosCreatedCount;
        int FeaturedTrackID;
        int WorldRecords;
        int TOP10s;

        UserInfo(const Json::Value &in json)
        {
            try {
                UserID = json["UserID"];
                Username = json["Username"];
                if (json["PlayerLogin"].GetType() != Json::Type::Null) PlayerLogin = json["PlayerLogin"];
                if (json["UplayLogin"].GetType() != Json::Type::Null) UplayLogin = json["UplayLogin"];
                if (json["Comments"].GetType() != Json::Type::Null) Comments = json["Comments"];
                IsDuo = json["IsDuo"];
                Registered = json["Registered"];
                TrackCount = json["TrackCount"];
                MappackCount = json["MappackCount"];
                ReplayCount = json["ReplayCount"];
                AwardsReceived = json["AwardsReceived"];
                AwardsGiven = json["AwardsGiven"];
                CommentsReceived = json["CommentsReceived"];
                CommentsGiven = json["CommentsGiven"];
                FavouritesCount = json["FavouritesCount"];
                FavouritesGivenCount = json["FavouritesGivenCount"];
                VideosReceivedCount = json["VideosReceivedCount"];
                VideosSubmittedCount = json["VideosSubmittedCount"];
                VideosCreatedCount = json["VideosCreatedCount"];
                FeaturedTrackID = json["FeaturedTrackID"];
                WorldRecords = json["WorldRecords"];
                TOP10s = json["TOP10s"];
            } catch {
                mxWarn("Error parsing user info for user "+Username, true);
                print(Json::Write(ToJson()));
            }
        }

        Json::Value ToJson()
        {
            Json::Value json = Json::Object();
            try {
                json["UserID"] = UserID;
                json["Username"] = Username;
                json["PlayerLogin"] = PlayerLogin;
                json["UplayLogin"] = UplayLogin;
                json["Comments"] = Comments;
                json["IsDuo"] = IsDuo;
                json["Registered"] = Registered;
                json["TrackCount"] = TrackCount;
                json["MappackCount"] = MappackCount;
                json["ReplayCount"] = ReplayCount;
                json["AwardsReceived"] = AwardsReceived;
                json["AwardsGiven"] = AwardsGiven;
                json["CommentsReceived"] = CommentsReceived;
                json["CommentsGiven"] = CommentsGiven;
                json["FavouritesCount"] = FavouritesCount;
                json["FavouritesGivenCount"] = FavouritesGivenCount;
                json["VideosReceivedCount"] = VideosReceivedCount;
                json["VideosSubmittedCount"] = VideosSubmittedCount;
                json["VideosCreatedCount"] = VideosCreatedCount;
                json["FeaturedTrackID"] = FeaturedTrackID;
                json["WorldRecords"] = WorldRecords;
                json["TOP10s"] = TOP10s;
            } catch {
                mxWarn("Error converting user info to json for user "+Username, true);
            }
            return json;
        }
    }
}