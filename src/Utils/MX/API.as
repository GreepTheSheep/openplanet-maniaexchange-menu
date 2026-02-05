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

    array<MapComment@> GetMapComments(int mapId) {
        if (MX::APIDown) {
            return {};
        }

        string url = MXURL + "/api/maps/comments?trackId=" + mapId + "&count=100&fields=" + MX::commentFields;
        Logging::Debug("[MX::GetMapComments] URL: " + url);

        Net::HttpRequest@ req = API::Get(url);

        while (!req.Finished()) {
            yield();
        }

        int resCode = req.ResponseCode();
        auto json = req.Json();

        Logging::Debug("[MX::GetMapComments] API response: " + req.String());

        if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
            Logging::Error("[MX::GetMapComments] Error parsing response");
            return {};
        }

        Json::Value@ results = json["Results"];
        array<MapComment@> comments;

        for (uint i = 0; i < results.Length; i++) {
            auto comment = MX::MapComment(results[i]);
            comments.InsertLast(comment);
        }

        return comments;
    }

    array<MapEmbeddedObject@> GetMapObjects(int mapId) {
        if (MX::APIDown) {
            return {};
        }

        string url = MXURL + "/api/maps/objects?trackId=" + mapId + "&count=1000";
        Logging::Debug("[MX::GetMapObjects] URL: " + url);

        Net::HttpRequest@ req = API::Get(url);

        while (!req.Finished()) {
            yield();
        }

        int resCode = req.ResponseCode();
        auto json = req.Json();

        Logging::Debug("[MX::GetMapObjects] API response: " + req.String());

        if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
            Logging::Error("[MX::GetMapObjects] Error parsing response");
            return {};
        }
        
        if (json["Results"].Length == 0) {
            Logging::Error("[MX::GetMapObjects] API returned 0 embedded objects!");
            return {};
        }

        Json::Value@ results = json["Results"];
        array<MapEmbeddedObject@> objects;

        for (uint i = 0; i < results.Length; i++) {
            auto object = MX::MapEmbeddedObject(results[i], int(i) < Setting_EmbeddedObjectsLimit);
            objects.InsertLast(object);
        }

        return objects;
    }
}
