namespace TMIO
{
    class Leaderboard
    {
        int position;
        uint time;
        string ghostURL;
        string playerName;
        string playerID;

        Leaderboard(Json::Value leaderboard){
            try {
                position = leaderboard["position"];
                time = leaderboard["time"];
                ghostURL = "https://trackmania.io";
                ghostURL += leaderboard["url"];
                playerName = leaderboard["player"]["name"];
                playerID = leaderboard["player"]["id"];
            } catch {
                Logging::Warn("Error parsing info for TM.io leaderboard: " + getExceptionInfo(), true);
            }
        }
    }
}