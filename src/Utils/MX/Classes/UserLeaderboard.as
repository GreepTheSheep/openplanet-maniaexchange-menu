namespace MX
{
    class UserLeaderboard
    {
        int UserID;
        string Username;
        int Position;
        int PositionChange;
        int PreviousPosition;
        float Score;
        float ScoreChange;
        int WorldRecords;
        int WRChange;
        int ReplayCount;
        int ReplayCountChange;
        int TOP2s;
        int TOP2Change;
        int TOP3s;
        int TOP3Change;
        int AveragePosition;
        int SeasonID;

        UserLeaderboard(const Json::Value &in json)
        {
            try {
                UserID = json["UserID"];
                Username = json["Username"];
                Position = json["Position"];
                PositionChange = json["PositionChange"];
                PreviousPosition = json["PreviousPosition"];
                Score = json["Score"];
                ScoreChange = json["ScoreChange"];
                WorldRecords = json["WorldRecords"];
                WRChange = json["WRChange"];
                ReplayCount = json["ReplayCount"];
                ReplayCountChange = json["ReplayCountChange"];
                TOP2s = json["TOP2s"];
                TOP2Change = json["TOP2Change"];
                TOP3s = json["TOP3s"];
                TOP3Change = json["TOP3Change"];
                AveragePosition = json["AveragePosition"];
                SeasonID = json["SeasonID"];
            } catch {
                mxWarn("Failed to parse User Leaderboard for user " + Username + ": " + getExceptionInfo());
            }
        }

        Json::Value ToJSON()
        {
            Json::Value json = Json::Object();
            try {
                json["UserID"] = UserID;
                json["Username"] = Username;
                json["Position"] = Position;
                json["PositionChange"] = PositionChange;
                json["PreviousPosition"] = PreviousPosition;
                json["Score"] = Score;
                json["ScoreChange"] = ScoreChange;
                json["WorldRecords"] = WorldRecords;
                json["WRChange"] = WRChange;
                json["ReplayCount"] = ReplayCount;
                json["ReplayCountChange"] = ReplayCountChange;
                json["TOP2s"] = TOP2s;
                json["TOP2Change"] = TOP2Change;
                json["TOP3s"] = TOP3s;
                json["TOP3Change"] = TOP3Change;
                json["AveragePosition"] = AveragePosition;
                json["SeasonID"] = SeasonID;
            } catch {
                mxWarn("Failed to convert User Leaderboard to JSON for user " + Username + ": " + getExceptionInfo());
            }
            return json;
        }
    }
}