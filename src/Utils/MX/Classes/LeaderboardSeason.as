namespace MX
{
    class LeaderboardSeason
    {
        int SeasonID;
        string Name;
        string StartDate;
        string EndDate;

        LeaderboardSeason(const Json::Value &in json)
        {
            try {
                SeasonID = json["SeasonID"];
                Name = json["Name"];
                StartDate = json["StartDate"];
                EndDate = json["EndDate"];
            } catch {
                mxWarn("Failed to parse Leaderboard Season for season " + SeasonID + ": " + getExceptionInfo());
            }
        }

        Json::Value ToJSON()
        {
            Json::Value json = Json::Object();
            try {
                json["SeasonID"] = SeasonID;
                json["Name"] = Name;
                json["StartDate"] = StartDate;
                json["EndDate"] = EndDate;
            } catch {
                mxWarn("Failed to convert Leaderboard Season to JSON for season " + SeasonID + ": " + getExceptionInfo());
            }
            return json;
        }
    }
}