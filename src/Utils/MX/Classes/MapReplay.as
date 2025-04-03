namespace MX
{
    class MapReplay // TODO finish once the documentation is complete
    {
        int ReplayId;
        int UserId;
        string Username;
        string ReplayAt;
        uint ReplayTime;
        int Percentage;
        int ReplayPoints;
        int Respawns;
        int Position;
        int Score;

        MapReplay(const Json::Value &in json)
        {
            try {
                ReplayId = json["ReplayId"];
                if (json["User"].GetType() != Json::Type::Null) {
                    UserId = json["User"]["UserId"];
                    Username = json["User"]["Name"];
                }
                ReplayAt = json["ReplayAt"];
                ReplayTime = json["ReplayTime"];
                ReplayPoints = json["ReplayPoints"];
                Respawns = json["Respawns"];
                // Percentage = json["Percentage"]; TODO missing
                Score = json["Score"];

                if (json["Position"].GetType() != Json::Type::Null) {
                    Position = json["Position"]; // TODO off by one
                } else {
                    Position = -1;
                }
            } catch {
                Logging::Warn("Error parsing info for replay ID " + ReplayId + ": " + getExceptionInfo(), true);
            }
        }

        bool get_IsValid() const {
            return Position >= 0; // TODO change to 1 when Position gets fixed
        }
    }
}