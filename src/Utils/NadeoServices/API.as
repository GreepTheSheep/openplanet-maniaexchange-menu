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
            Logging::Error("[GetMapRecords] Error when getting map records: API didn't return an object!", true);
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
            Logging::Error("[GetMapRecords] Failed to get map records: " + getExceptionInfo(), true);
            return {};
        }
    }

    void GetRecordsData(array<LeaderboardRecord@> records, const string &in mapId, MX::GameModes mapMode) {
        while (!NadeoServices::IsAuthenticated("NadeoServices")) {
            yield();
        }

        array<string> accountIds;

        foreach (LeaderboardRecord@ record : records) {
            if (record.Url == "") {
                accountIds.InsertLast(record.AccountId);
            }
        }

        if (accountIds.IsEmpty()) {
            return;
        }
        
        string gameMode;

        if (mapMode == MX::GameModes::Stunt) {
            gameMode = "Stunt";
        } else {
            gameMode = "TimeAttack";
        }

        string url = NadeoServices::BaseURLCore() + "/v2/mapRecords/by-account/?accountIdList=" + string::Join(accountIds, ",") + "&mapId=" + mapId + "&gameMode=" + gameMode;

        Net::HttpRequest@ req = NadeoServices::Get("NadeoServices", url);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        Logging::Trace("[GetRecordsData] Response: " + req.String());
        Json::Value@ res = req.Json();

        if (res.GetType() != Json::Type::Array) {
            Logging::Error("[GetRecordsData] Error when getting records data: API didn't return an array!");
            return;
        }

        for (uint i = 0; i < res.Length; i++) {
            Json::Value@ data = res[i];

            int index = accountIds.Find(data["accountId"]);
            if (index == -1) continue;

            LeaderboardRecord@ record = records[index];

            // Nadeo API calls them replays despite being ghosts
            record.FileName = Path::GetFileName(data["filename"]).Replace(".replay", ".Ghost");
            record.RecordId = data["mapRecordId"];
            record.Medal = int(data["medal"]);
            record.Url = data["url"];
        }
    }
#endif
}
