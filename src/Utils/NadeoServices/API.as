namespace NadeoServices {
#if DEPENDENCY_NADEOSERVICES
    array<LeaderboardRecord@> GetMapRecords(const string &in mapUid, int offset = 0) {
        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }

        string url = NadeoServices::BaseURLLive() + "/api/token/leaderboard/group/Personal_Best/map/" + mapUid + "/top?length=100&onlyWorld=true&offset=" + offset;

        Logging::Trace("[GetMapRecords] URL: " + url);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        Logging::Trace("[GetMapRecords] Response: " + req.String());
        auto res = req.Json();

        if (res.GetType() != Json::Type::Object) {
            Logging::Error("[GetMapRecords] Error when getting map records: API didn't return an object!");
            return {};
        }

        array<LeaderboardRecord@> leaderboard;
        array<string> accountIds;

        try {
            Json::Value@ records = res["tops"][0]["top"];

            for (uint i = 0; i < records.Length; i++) {
                auto record = LeaderboardRecord(records[i]);
                accountIds.InsertLast(record.AccountId);
                leaderboard.InsertLast(record);
            }

            dictionary displayNames = NadeoServices::GetDisplayNamesAsync(accountIds);

            for (uint i = 0; i < leaderboard.Length; i++) {
                string name;

                if (displayNames.Get(leaderboard[i].AccountId, name)) {
                    leaderboard[i].DisplayName = name;
                }
            }

            Logging::Trace("[GetMapRecords] Found " + leaderboard.Length + " records for map UID " + mapUid);
            return leaderboard;
        } catch {
            Logging::Error("[GetMapRecords] Failed to get map records: " + getExceptionInfo());
            return {};
        }
    }
#endif
}
