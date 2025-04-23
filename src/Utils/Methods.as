bool IsInEditor(){
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    auto editor = cast<CGameCtnEditorCommon>(app.Editor);
    return editor !is null;
}

bool IsInServer(){
    CTrackManiaNetwork@ Network = cast<CTrackManiaNetwork>(GetApp().Network);
    CGameCtnNetServerInfo@ ServerInfo = cast<CGameCtnNetServerInfo>(Network.ServerInfo);
    return  ServerInfo.JoinLink != "";
}

CGameCtnChallenge@ GetCurrentMap(){
    CTrackMania@ g_app = cast<CTrackMania>(GetApp());
    return g_app.RootMap;
}

string CleanMapType(const string &in mapType) {
    const int slashIndex = mapType.IndexOf("\\");

    if (slashIndex == -1) return mapType;

    return mapType.SubStr(slashIndex+1);
}

string CurrentTitlePack() {
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    if (app.LoadedManiaTitle is null) return "";

    string titleId = app.LoadedManiaTitle.TitleId;

#if MP4
    return titleId.SubStr(0, titleId.IndexOf("@"));
#else
    return titleId;
#endif
}

array<MX::MapInfo@> LoadPlayLater() {
    array<MX::MapInfo@> m_maps;
    Json::Value FileData = Json::FromFile(PlayLaterJSON);
    if (FileData.GetType() == Json::Type::Null) {

        // Check if we have a old PlayLater File (migration to PluginStorage directory for version 1.2)
        Json::Value FileData_Old = Json::FromFile(IO::FromDataFolder("ManiaExchange_PlayLater.json"));
        if (FileData_Old.GetType() == Json::Type::Array) {
            for (uint i = 0; i < FileData_Old.Length; i++) {

                string mapName = FileData_Old[i]["Name"];
                Logging::Trace("Loading map #"+i+" from Old Play later file: " + mapName);

                MX::MapInfo@ map = MX::MapInfo(FileData_Old[i]);
                m_maps.InsertAt(0, map);
            }
            SavePlayLater(m_maps);
            IO::Delete(IO::FromDataFolder("ManiaExchange_PlayLater.json"));
            Logging::Info(tostring(m_maps.Length) + " maps loaded from Play Later list and migrated to PluginStorage.");
        } else {
            UI::ShowNotification("\\$afa" + Icons::InfoCircle + " Thanks for installing "+pluginName+"!","No data file was detected, that means it's your first install. Welcome!", 15000);
            SavePlayLater(m_maps);
        }

        return m_maps;
    } else if (FileData.GetType() != Json::Type::Array) {
        Logging::Error("The data file seems to yield invalid data. If it persists, consider deleting the file " + PlayLaterJSON, true);
        return m_maps;
    } else {
        if (FileData.Length > 0 && !FileData[0].HasKey("MapId")) {
            UI::ShowNotification("PlayLater.json v1 detected!", "Migrating file to v2...");

            uint currentMapId = 0;

            while (currentMapId < FileData.Length) {
                array<string> idBatch;

                for (uint i = currentMapId; i < currentMapId + MX::maxMapsRequest && i < FileData.Length; i++) {
                    if (FileData[i].HasKey("TrackID")) {
                        idBatch.InsertLast(tostring(int(FileData[i]["TrackID"])));
                    }
                }

                string mxUrl = "https://" + MXURL + "/api/maps?fields=" + MX::mapFields + "&count=" + (MX::maxMapsRequest + 10) + "&id=" + string::Join(idBatch, ",");
                Json::Value res = API::GetAsync(mxUrl);

                if (res.GetType() == Json::Type::Null || !res.HasKey("Results") || res["Results"].Length == 0) {
                    Logging::Error("Something went wrong when getting PlayLater maps from MX. Stopping migration...", true);
                    return m_maps;
                }

                Json::Value maps = res["Results"];

                for (uint m = 0; m < maps.Length; m++) {
                    MX::MapInfo@ map = MX::MapInfo(maps[m]);
                    m_maps.InsertLast(map);
                }

                currentMapId += MX::maxMapsRequest;
                sleep(1500);
            }

            Logging::Info("Finished to fetch PlayLater.json maps. Found " + m_maps.Length + " maps out of " + FileData.Length);

            if (m_maps.Length < FileData.Length) {
                Logging::Warn("Failed to convert all maps in PlayLater.json, missing " + (FileData.Length - m_maps.Length) + " map/s!", true);
            }

            IO::Copy(PlayLaterJSON, IO::FromStorageFolder("PlayLaterOld.json"));
            SavePlayLater(m_maps);

            UI::ShowNotification("Migration completed", "Succesfully migrated PlayLater.json to v2!", UI::HSV(0.33, 0.7, 0.65), 10000);
            return m_maps;
        } else {
            for (uint i = 0; i < FileData.Length; i++) {
                if (FileData[i].GetType() != Json::Type::Object) {
                    Logging::Error("The data file seems to yield invalid data. If it persists, consider deleting the file " + PlayLaterJSON, true);
                    return m_maps;
                }

                string mapName = FileData[i]["Name"];
                Logging::Trace("Loading map #"+i+" from Play later: " + mapName);

                MX::MapInfo@ map = MX::MapInfo(FileData[i]);
                m_maps.InsertAt(0, map);
            }
        }
        Logging::Info(tostring(m_maps.Length) + " maps loaded from Play Later list.");
        return m_maps;
    }
}

void SavePlayLater(array<MX::MapInfo@> maps) {
    Json::Value FileData = Json::Array();
    for (uint i = 0; i < maps.Length; i++) {
        FileData.Add(maps[i].ToJson());
    }
    Json::ToFile(PlayLaterJSON, FileData);
}