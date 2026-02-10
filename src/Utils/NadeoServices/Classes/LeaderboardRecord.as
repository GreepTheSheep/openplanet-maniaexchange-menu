namespace NadeoServices {
    class LeaderboardRecord {
        uint Position;
        uint Score;
        uint Timestamp;
        string ZoneName;
        string ZoneId;
        string AccountId;
        string DisplayName;
        string FileName;
        string Url;
        int Medal;
        string RecordId;

        bool m_downloading;

        LeaderboardRecord(Json::Value@ json) {
            try {
                Position    = json["position"];
                Score       = json["score"];
                Timestamp   = json["timestamp"];
                ZoneName    = json["zoneName"];
                ZoneId      = json["zoneId"];
                AccountId   = json["accountId"];
                DisplayName = AccountId;
            } catch {
                Logging::Warn("Error parsing leaderboard record: " + getExceptionInfo());
            }
        }

        bool get_IsLocalPlayer() {
#if DEPENDENCY_NADEOSERVICES
            return AccountId == NadeoServices::GetAccountID();
#else
            return false;
#endif
        }

        bool get_Downloading() {
            return m_downloading;
        }

        void Download() {
            if (Url == "" || Downloading) {
                return;
            }

            m_downloading = true;

            string folder = IO::FromUserGameFolder("Replays\\Downloaded\\");
            string path = folder + Path::SanitizeFileName(FileName);

            auto req = Net::HttpRequest(Url);
            req.StartToFile(path);

            while (!req.Finished()) {
		        yield();
	        }

            m_downloading = false;

            Logging::Info("Succesfully downloaded replay to " + folder, true);
        }
    }
}
