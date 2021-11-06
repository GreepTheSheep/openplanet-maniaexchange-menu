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
            position = leaderboard["position"];
            time = leaderboard["time"];
            ghostURL = "https://trackmania.io";
            ghostURL += leaderboard["url"];
            playerName = leaderboard["player"]["name"];
            playerID = leaderboard["player"]["id"];
        }
    }
}