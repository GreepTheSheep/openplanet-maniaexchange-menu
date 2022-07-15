namespace MX
{
    class MapReplay
    {
        int ReplayID;
        int UserID;
        string Username;
        int TrackID;
        string UploadedAt;
        uint ReplayTime;
        uint StuntScore;
        uint Respawns;
        int Position;
        int Beaten;
        int Percentage;
        int ReplayPoints;
        int NadeoPoints;
        string ExeBuild;
        string PlayerModel;

        MapReplay(const Json::Value &in json)
        {
            ReplayID = json["ReplayID"];
            UserID = json["UserID"];
            Username = json["Username"];
            TrackID = json["TrackID"];
            UploadedAt = json["UploadedAt"];
            ReplayTime = json["ReplayTime"];
            StuntScore = json["StuntScore"];
            Respawns = json["Respawns"];
            Position = json["Position"];
            Beaten = json["Beaten"];
            Percentage = json["Percentage"];
            ReplayPoints = json["ReplayPoints"];
            NadeoPoints = json["NadeoPoints"];
            ExeBuild = json["ExeBuild"];
            PlayerModel = json["PlayerModel"];
        }
    }
}