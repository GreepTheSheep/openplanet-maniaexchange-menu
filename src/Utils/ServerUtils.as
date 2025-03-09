namespace TMNext
{

    bool isCheckingRoom = false;
    string roomCheckErrorCode = "";
    string roomCheckError = "";
    NadeoServices::ClubRoom@ foundRoom;
    bool AddMapToServer_PlayMapNow = false;

    [Setting hidden]
    int AddMapToServer_ClubId = 0;
    [Setting hidden]
    int AddMapToServer_RoomId = 0;

    string AddMapToServer_MapUid = "";
    int AddMapToServer_MapMXId;
    string AddMapToServer_MapType = "";

    void CheckNadeoRoomAsync() {
#if DEPENDENCY_NADEOSERVICES && TMNEXT
        // Step 1: Check if we can access to the room
        isCheckingRoom = true;
        roomCheckErrorCode = "";
        roomCheckError = "";
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", NadeoServices::BaseURLLive()+"/api/token/club/"+AddMapToServer_ClubId+"/room/"+AddMapToServer_RoomId);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        auto res = req.Json();
        isCheckingRoom = false;

        if (isDevMode) trace("NadeoServices - Check server: " + req.String());

        if (res.GetType() == Json::Type::Array) {
            roomCheckErrorCode = res[0];
            if (roomCheckErrorCode.Contains("notFound")) roomCheckError = "Room is not Found";
            else roomCheckError = "Unknown error";
            return;
        }

        if (res.GetType() == Json::Type::Object)
            @foundRoom = NadeoServices::ClubRoom(res);
#endif
    }

    void UploadMapToNadeoServices() {
        MX::DownloadMap(AddMapToServer_MapMXId, "", AddMapToServer_MapUid);
#if TMNEXT
        auto app = cast<CGameManiaPlanet>(GetApp());
        auto cma = app.MenuManager.MenuCustom_CurrentManiaApp;
        auto dfm = cma.DataFileMgr;
        auto userId = cma.UserMgr.Users[0].Id;
        yield();
        auto regScript = dfm.Map_NadeoServices_Register(userId, AddMapToServer_MapUid);
        while (regScript.IsProcessing) yield();
        if (regScript.HasFailed)
            mxError("Uploading map failed: " + regScript.ErrorType + ", " + regScript.ErrorCode + ", " + regScript.ErrorDescription);
        else if (regScript.HasSucceeded)
            trace("UploadMapFromLocal: Map uploaded: " + AddMapToServer_MapUid);
        dfm.TaskResult_Release(regScript.Id);
#endif
        string downloadedMapFolder = IO::FromUserGameFolder("Maps/Downloaded");
        string mxDLFolder = downloadedMapFolder + "/" + pluginName;
        IO::Delete(mxDLFolder + "/" + AddMapToServer_MapUid + ".Map.Gbx");
    }

    void PlayMapInRoom() {
#if DEPENDENCY_NADEOSERVICES
        if (!MXNadeoServicesGlobal::CheckIfMapExistsAsync(AddMapToServer_MapUid))
            UploadMapToNadeoServices();

        trace("Adding map '" + AddMapToServer_MapUid + "' to Nadeo Room #"+AddMapToServer_ClubId+"-"+AddMapToServer_RoomId);

        if (foundRoom.room.maps.Length > 0) {
            const string mapUid = foundRoom.room.currentMapUid.Length > 0 ? foundRoom.room.currentMapUid : foundRoom.room.maps[0];
            Json::Value mapInfo = MXNadeoServicesGlobal::GetMapInfoAsync(mapUid);

            if (mapInfo is null) {
                mxWarn("Couldn't find information for map UID " + mapUid, true);
                return;
            } else {
                string serverMapType = CleanMapType(string(mapInfo["mapType"]));

                if (serverMapType != AddMapToServer_MapType) {
                    mxError("Map type doesn't match the room's current game mode", true);
                    return;
                }
            }
        }

        Json::Value bodyJson = Json::Object();
        if (AddMapToServer_PlayMapNow) {
            if (foundRoom.room.maps.Length > 0) {
                for (uint i = 0; i < foundRoom.room.maps.Length; i++) {
                    if (foundRoom.room.maps[i] == foundRoom.room.currentMapUid)
                        foundRoom.room.maps[i] = AddMapToServer_MapUid;
                    else
                        foundRoom.room.maps.InsertLast(AddMapToServer_MapUid);
                    break;
                }
            } else foundRoom.room.maps.InsertLast(AddMapToServer_MapUid);
        } else foundRoom.room.maps.InsertLast(AddMapToServer_MapUid);

        Json::Value bodyJsonMaps = Json::Array();
        for (uint j = 0; j < foundRoom.room.maps.Length; j++) {
            bodyJsonMaps.Add(foundRoom.room.maps[j]);
        }

        bodyJson["maps"] = bodyJsonMaps;

        if (AddMapToServer_PlayMapNow) {
            Json::Value bodyJsonSettingTimeLimit = Json::Object();
            bodyJsonSettingTimeLimit["key"] = "S_TimeLimit";
            bodyJsonSettingTimeLimit["value"] = "1";
            bodyJsonSettingTimeLimit["type"] = "integer";

            Json::Value bodyJsonSettings = Json::Array();
            bodyJsonSettings.Add(bodyJsonSettingTimeLimit);

            bodyJson["settings"] = bodyJsonSettings;
        }

        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", NadeoServices::BaseURLLive()+"/api/token/club/"+AddMapToServer_ClubId+"/room/"+AddMapToServer_RoomId+"/edit", Json::Write(bodyJson));
        req.Start();
        while (!req.Finished()) yield();
        print("NadeoServices::UpdateRoom - "+req.String());

        if (AddMapToServer_PlayMapNow) {
            if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
            // revert time limit to its user-set (else set to 0)
            sleep(1500);
            Json::Value bodyJsonSettingTimeLimit = Json::Object();
            bodyJsonSettingTimeLimit["key"] = "S_TimeLimit";
            bodyJsonSettingTimeLimit["type"] = "integer";
            if (Text::ParseInt(foundRoom.room.timeLimit) > 60)
                bodyJsonSettingTimeLimit["value"] = foundRoom.room.timeLimit;
            else
                bodyJsonSettingTimeLimit["value"] = "0";

            Json::Value bodyJsonSettings = Json::Array();
            bodyJsonSettings.Add(bodyJsonSettingTimeLimit);

            bodyJson = Json::Object();
            bodyJson["settings"] = bodyJsonSettings;

            @req = NadeoServices::Post("NadeoLiveServices", NadeoServices::BaseURLLive()+"/api/token/club/"+AddMapToServer_ClubId+"/room/"+AddMapToServer_RoomId+"/edit", Json::Write(bodyJson));
            req.Start();
            while (!req.Finished()) yield();
            print("NadeoServices::UpdateRoom (reset S_TimeLimit to 0) - "+req.String());
            AddMapToServer_PlayMapNow = false;
        }
#endif
    }
}