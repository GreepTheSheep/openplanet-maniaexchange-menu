namespace TM {
    dictionary g_checkedMaps;

    array<LeaderboardRecord@> GetMapRecords(const string &in mapUid, int offset = 0) {
#if DEPENDENCY_NADEOSERVICES
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
#else
        return {};
#endif
    }

    void GetRecordsData(array<LeaderboardRecord@> records, const string &in mapId, MX::GameModes mapMode) {
#if DEPENDENCY_NADEOSERVICES
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
#endif
    }

    void UploadMapToNadeoServices(MX::MapInfo@ map) {
#if TMNEXT
        if (!Permissions::CreateAndUploadMap()) {
            Logging::Error("You don't have permission to upload maps.", true);
            return;
        }

        auto app = cast<CGameManiaPlanet>(GetApp());
        auto cma = app.MenuManager.MenuCustom_CurrentManiaApp;
        auto dfm = cma.DataFileMgr;
        auto userId = cma.UserMgr.Users[0].Id;

        yield();

        auto regScript = dfm.Map_NadeoServices_Register(userId, map.MapUid);

        while (regScript.IsProcessing) yield();

        if (regScript.HasFailed) {
            Logging::Error("[UploadMapToNadeoServices] Map upload failed: " + regScript.ErrorType + ", " + regScript.ErrorCode + ", " + regScript.ErrorDescription);
        } else if (regScript.HasSucceeded) {
            Logging::Trace("[UploadMapToNadeoServices] Map uploaded: " +  map.MapUid);
        }

        dfm.TaskResult_Release(regScript.Id);
#endif
    }

    bool IsMapUploaded(const string &in mapUid) {
        if (g_checkedMaps.Exists(mapUid)) {
            return bool(g_checkedMaps[mapUid]);
        }

        TM::MapInfo@ map = GetMapInfo(mapUid);

        if (map is null) {
            g_checkedMaps.Set(mapUid, false);
            return false;
        }

        try {
            g_checkedMaps.Set(map.Uid, map.Uid == mapUid);
            return map.Uid == mapUid;
        } catch {
            g_checkedMaps.Set(mapUid, false);
            return false;
        }
    }

    TM::MapInfo@ GetMapInfo(const string &in mapUid) {
#if TMNEXT
        Logging::Debug("[GetMapInfo] Getting map information for UID " + mapUid);

        auto app = cast<CGameManiaPlanet>(GetApp());
        auto menu = app.MenuManager.MenuCustom_CurrentManiaApp;
        MwId userId = menu.UserMgr.Users[0].Id;
        auto res = menu.DataFileMgr.Map_NadeoServices_GetFromUid(userId, mapUid);

        while (res.IsProcessing) {
            yield();
        }

        if (!res.HasSucceeded || res.HasFailed || res.Map is null) {
            Logging::Error("[GetMapInfo] Failed to get favorite maps: Error " + res.ErrorCode + " - " + res.ErrorDescription);
            menu.DataFileMgr.TaskResult_Release(res.Id);
            return null;
        }

        auto mapInfo = TM::MapInfo(res.Map);
        menu.DataFileMgr.TaskResult_Release(res.Id);

        return mapInfo;
#else
        return null;
#endif
    }
}
