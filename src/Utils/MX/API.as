namespace MX {
    array<MapReplay@> GetMapReplays(int mapId) {
        if (MX::APIDown) {
            return {};
        }

        string url = MXURL + "/api/replays?best=1&count=100&mapId=" + mapId;
        Logging::Debug("[MX::GetMapReplays] URL: " + url);

        Net::HttpRequest@ req = API::Get(url);

        while (!req.Finished()) {
            yield();
        }

        int resCode = req.ResponseCode();
        auto json = req.Json();

        Logging::Debug("[MX::GetMapReplays] API response: " + req.String());

        if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
            Logging::Error("[MX::GetMapReplays] Error parsing response");
            return {};
        }
        
        if (json["Results"].Length == 0) {
            Logging::Error("[MX::GetMapReplays] API returned 0 replays!");
            return {};
        }

        Json::Value@ results = json["Results"];
        array<MapReplay@> replays;

        for (uint i = 0; i < results.Length; i++) {
            auto replay = MX::MapReplay(results[i]);
            replays.InsertLast(replay);
        }

        return replays;
    }
}
