namespace TMNext
{
    bool g_checkingRoom = false;
    string roomCheckError = "";
    NadeoServices::ClubRoom@ foundRoom;

    [Setting hidden]
    int AddMapToServer_ClubId = 0;
    [Setting hidden]
    int AddMapToServer_RoomId = 0;

    bool get_IsCheckingRoom() {
        return g_checkingRoom;
    }

    void CheckNadeoRoomAsync() {
#if DEPENDENCY_NADEOSERVICES
        g_checkingRoom = true;
        roomCheckError = "";

        string url = NadeoServices::BaseURLLive() + "/api/token/club/" + AddMapToServer_ClubId + "/room/" + AddMapToServer_RoomId;

        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();
        while (!req.Finished()) {
            yield();
        }

        g_checkingRoom = false;

        auto res = req.Json();
        Logging::Trace("NadeoServices - Check server: " + req.String());

        switch (res.GetType()) {
            case Json::Type::Object:
                @foundRoom = NadeoServices::ClubRoom(res);
                break;
            case Json::Type::Array:
                if (string(res[0]).Contains("notFound")) {
                    roomCheckError = "Failed to find room";
                } else {
                    roomCheckError = res[0];
                }

                break;
            default:
                roomCheckError = "Unexpected API response";
                break;
        }
#endif
    }

    void UploadMapToNadeoServices(MX::MapInfo@ map) {
#if TMNEXT
        MX::DownloadMap(map.MapId, "", map.MapUid);

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

        string mapLocation = IO::FromUserGameFolder("Maps/Downloaded/" + pluginName) + "/" + map.MapUid + ".Map.Gbx";

        if (IO::FileExists(mapLocation)) {
            IO::Delete(mapLocation);
        }
#endif
    }

    void AddMapToRoom(ref@ mapRef) {
        auto map = cast<MX::MapInfo>(mapRef);

        if (map !is null) {
            UpdateRoomMaps(map);
        }
    }

    void PlayMapInRoom(ref@ mapRef) {
        auto map = cast<MX::MapInfo>(mapRef);

        if (map !is null) {
            UpdateRoomMaps(map, true);
        }
    }

    void UpdateRoomMaps(MX::MapInfo@ map, bool switchToMap = false) {
#if DEPENDENCY_NADEOSERVICES
        if (!MXNadeoServicesGlobal::CheckIfMapExistsAsync(map.MapUid)) {
            UploadMapToNadeoServices(map);
        }

        Logging::Trace("Adding map '" + map.MapUid + "' to Nadeo Room #" + AddMapToServer_ClubId + "-" + AddMapToServer_RoomId);

        array<string> mapList = foundRoom.room.maps;

        if (mapList.Length > 0) {
            const string mapUid = foundRoom.room.currentMapUid.Length > 0 ? foundRoom.room.currentMapUid : mapList[0];
            Json::Value mapInfo = MXNadeoServicesGlobal::GetMapInfoAsync(mapUid);

            if (mapInfo is null) {
                Logging::Warn("Couldn't find information for map UID " + mapUid, true);
                return;
            } else {
                string serverMapType = CleanMapType(string(mapInfo["mapType"]));

                if (serverMapType != map.MapType) {
                    Logging::Error("Map type doesn't match the room's current game mode", true);
                    return;
                }
            }
        }

        Json::Value bodyJson = Json::Object();

        if (switchToMap && !mapList.IsEmpty()) {
            for (uint i = 0; i < mapList.Length; i++) {
                if (mapList[i] == foundRoom.room.currentMapUid) {
                    mapList[i] = map.MapUid;
                    break;
                }

                if (i == mapList.Length - 1) {
                    mapList.InsertLast(map.MapUid);
                }
            }
        } else {
            mapList.InsertLast(map.MapUid);
        }

        bodyJson["maps"] = mapList.ToJson();

        if (switchToMap) {
            Json::Value timeJson = Json::Object();
            timeJson["key"] = "S_TimeLimit";
            timeJson["value"] = "1";
            timeJson["type"] = "integer";

            Json::Value roomSettings = Json::Array();
            roomSettings.Add(timeJson);

            bodyJson["settings"] = roomSettings;
        }

        string roomUrl = NadeoServices::BaseURLLive() + "/api/token/club/" + AddMapToServer_ClubId + "/room/" + AddMapToServer_RoomId + "/edit";

        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", roomUrl, Json::Write(bodyJson));
        req.Start();
        while (!req.Finished()) yield();

        Logging::Trace("NadeoServices::UpdateRoom - " + req.String());

        if (switchToMap) {
            sleep(1500);

            // revert time limit to its user-set (else set to 0)
            if (Text::ParseInt(foundRoom.room.timeLimit) > 10) {
                bodyJson["settings"][0]["value"] = foundRoom.room.timeLimit;
            } else {
                bodyJson["settings"][0]["value"] = "0";
            }

            @req = NadeoServices::Post("NadeoLiveServices", roomUrl, Json::Write(bodyJson));
            req.Start();
            while (!req.Finished()) yield();
            Logging::Trace("NadeoServices::UpdateRoom (reset S_TimeLimit) - " + req.String());
        }
#endif
    }
}