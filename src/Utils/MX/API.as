namespace MX {
    array<MapInfo@> GetMaps(dictionary parameters) {
        if (MX::APIDown) {
            return {};
        }

        if (!parameters.Exists("fields")) {
            parameters.Set("fields", MX::mapFields);
        }

        if (!parameters.Exists("count")) {
            parameters.Set("count", "100");
        }

        string urlParams = MX::DictToApiParams(parameters);

        string url = MXURL + "/api/maps" + urlParams;
        Logging::Debug("[MX::GetMaps] URL: " + url);

        Net::HttpRequest@ req = API::Get(url);

        while (!req.Finished()) {
            yield();
        }

        int resCode = req.ResponseCode();
        auto json = req.Json();

        Logging::Debug("[MX::GetMaps] API response: " + req.String());

        if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
            Logging::Error("[MX::GetMaps] Error parsing response");
            return {};
        }

        Json::Value@ results = json["Results"];
        bool moreItems = json["More"];
        array<MapInfo@> maps;

        for (uint i = 0; i < results.Length; i++) {
            auto map = MX::MapInfo(results[i]);
            maps.InsertLast(map);
        }

        if (!maps.IsEmpty() && !moreItems) {
            maps[maps.Length - 1].LastItem = true;
        }

        return maps;
    }

    MapInfo@ GetMapById(int mapId) {
        dictionary parameters = {
            { "id", tostring(mapId) },
            { "fields", MX::mapFields }
        };

        array<MapInfo@> maps = GetMaps(parameters);

        if (maps.IsEmpty()) {
            Logging::Error("[MX::GetMapById] Failed to get a map with ID " + mapId);
            return null;
        }

        return maps[0];
    }

    MapInfo@ GetMapByUid(const string &in mapUid) {
        dictionary parameters = {
            { "uid", mapUid },
            { "fields", MX::mapFields }
        };

        array<MapInfo@> maps = GetMaps(parameters);

        if (maps.IsEmpty()) {
            Logging::Error("[MX::GetMapByUid] Failed to get a map with UID " + mapUid);
            return null;
        }

        return maps[0];
    }

    array<MapPackInfo@> GetMappacks(dictionary parameters) {
        if (MX::APIDown) {
            return {};
        }

        if (!parameters.Exists("fields")) {
            parameters.Set("fields", MX::mapPackFields);
        }

        if (!parameters.Exists("count")) {
            parameters.Set("count", "100");
        }

        string urlParams = MX::DictToApiParams(parameters);

        string url = MXURL + "/api/mappacks" + urlParams;
        Logging::Debug("[MX::GetMappacks] URL: " + url);

        Net::HttpRequest@ req = API::Get(url);

        while (!req.Finished()) {
            yield();
        }

        int resCode = req.ResponseCode();
        auto json = req.Json();

        Logging::Debug("[MX::GetMappacks] API response: " + req.String());

        if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
            Logging::Error("[MX::GetMappacks] Error parsing response");
            return {};
        }

        Json::Value@ results = json["Results"];
        bool moreItems = json["More"];
        array<MapPackInfo@> mappacks;

        for (uint i = 0; i < results.Length; i++) {
            auto pack = MX::MapPackInfo(results[i]);
            mappacks.InsertLast(pack);
        }

        if (!mappacks.IsEmpty() && !moreItems) {
            mappacks[mappacks.Length - 1].LastItem = true;
        }

        return mappacks;
    }

    array<UserInfo@> GetUsers(dictionary parameters) {
        if (MX::APIDown) {
            return {};
        }

        if (!parameters.Exists("fields")) {
            parameters.Set("fields", MX::userFields);
        }

        if (!parameters.Exists("count")) {
            parameters.Set("count", "100");
        }

        string urlParams = MX::DictToApiParams(parameters);

        string url = MXURL + "/api/users" + urlParams;
        Logging::Debug("[MX::GetUsers] URL: " + url);

        Net::HttpRequest@ req = API::Get(url);

        while (!req.Finished()) {
            yield();
        }

        int resCode = req.ResponseCode();
        auto json = req.Json();

        Logging::Debug("[MX::GetUsers] API response: " + req.String());

        if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
            Logging::Error("[MX::GetUsers] Error parsing response");
            return {};
        }

        Json::Value@ results = json["Results"];
        bool moreItems = json["More"];
        array<UserInfo@> users;

        for (uint i = 0; i < results.Length; i++) {
            auto user = MX::UserInfo(results[i]);
            users.InsertLast(user);
        }

        if (!users.IsEmpty() && !moreItems) {
            users[users.Length - 1].LastItem = true;
        }

        return users;
    }

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
