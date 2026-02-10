namespace MX
{
    class MapReplay // TODO finish once the documentation is complete
    {
        int ReplayId;
        int UserId;
        string Username;
        int Timestamp;
        uint ReplayTime;
        int Percentage;
        int ReplayPoints;
        int Respawns;
        int Position;
        int Score;
        bool HasFile;

        bool m_downloading;

        MapReplay(const Json::Value &in json)
        {
            try {
                ReplayId = json["ReplayId"];
                if (json["User"].GetType() != Json::Type::Null) {
                    UserId = json["User"]["UserId"];
                    Username = json["User"]["Name"];
                }
                ReplayTime = json["ReplayTime"];
                ReplayPoints = json["ReplayPoints"];
                Respawns = json["Respawns"];
                // Percentage = json["Percentage"]; TODO missing
                Score = json["Score"];
                HasFile = json["HasFile"];

                if (json["Position"].GetType() != Json::Type::Null) {
                    Position = json["Position"]; // TODO off by one
                }

                // ReplayAt sometimes doesn't have milliseconds / thousands, see map ID 10 (index 3) and ID 100 on TMX
                string timeStr = json["ReplayAt"];
                Timestamp = Time::ParseFormatString("%FT%T", timeStr.Split(".")[0]);
            } catch {
                Logging::Warn("Error parsing info for replay ID " + ReplayId + ": " + getExceptionInfo(), true);
            }
        }

        bool get_IsValid() {
            return Position >= 0; // TODO change to 1 when Position gets fixed
        }

        bool get_IsLocalUser() {
            return Setting_Tab_YourProfile_UserID == UserId;
        }

        bool get_Downloading() {
            return m_downloading;
        }

        void Download() {
            if (!HasFile || Downloading) {
                return;
            }

            m_downloading = true;
            Net::HttpRequest@ req = API::Get(MXURL + "/recordgbx/" + ReplayId);

            while (!req.Finished()) {
                yield();
            }

            string fileName = GetFileNameFromHeader(req.ResponseHeaders());

            if (fileName == "") {
                fileName = Username + "_" + ReplayId + "_" + Time::FormatString("%F_%H_%M_%S", Timestamp) + ".Replay.Gbx";
            }

            string folder = IO::FromUserGameFolder("Replays\\Downloaded\\");
            string path = folder + Path::SanitizeFileName(fileName);

            req.SaveToFile(path);
            m_downloading = false;

            Logging::Info("Succesfully downloaded replay to " + folder, true);
        }
    }
}