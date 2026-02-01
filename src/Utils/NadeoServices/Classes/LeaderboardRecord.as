namespace NadeoServices {
    class LeaderboardRecord {
        uint Position;
        uint Score;
        uint Timestamp;
        string ZoneName;
        string ZoneId;
        string AccountId;
        string DisplayName;

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
    }
}
