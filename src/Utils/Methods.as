bool IsInEditor(){
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    auto editor = cast<CGameCtnEditorCommon@>(app.Editor);
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

array<MX::MapInfo@> LoadPlayLater() {
    array<MX::MapInfo@> m_maps;
    Json::Value FileData = Json::FromFile(PlayLaterJSON);
    if (FileData.GetType() == Json::Type::Null) {

        // Check if we have a old PlayLater File (migration to PluginStorage directory for version 1.2)
        Json::Value FileData_Old = Json::FromFile(IO::FromDataFolder("ManiaExchange_PlayLater.json"));
        if (FileData_Old.GetType() == Json::Type::Array) {
            for (uint i = 0; i < FileData_Old.Length; i++) {
                if (isDevMode) {
                    string mapName = FileData_Old[i]["Name"];
                    trace("Loading map #"+i+" from Old Play later file: " + mapName);
                }
                MX::MapInfo@ map = MX::MapInfo(FileData_Old[i]);
                m_maps.InsertAt(0, map);
            }
            SavePlayLater(m_maps);
            IO::Delete(IO::FromDataFolder("ManiaExchange_PlayLater.json"));
            print(tostring(m_maps.Length) + " maps loaded from Play Later list and migrated to PluginStorage.");
        } else {
            UI::ShowNotification("\\$afa" + Icons::InfoCircle + " Thanks for installing "+pluginName+"!","No data file was detected, that means it's your first install. Welcome!", 15000);
            SavePlayLater(m_maps);
        }

        return m_maps;
    } else if (FileData.GetType() != Json::Type::Array) {
        mxError("The data file seems to yield invalid data. If it persists, consider deleting the file " + PlayLaterJSON, true);
        return m_maps;
    } else {
        for (uint i = 0; i < FileData.Length; i++) {
            if (isDevMode) {
                string mapName = FileData[i]["Name"];
                trace("Loading map #"+i+" from Play later: " + mapName);
            }
            if (FileData[i].GetType() != Json::Type::Object) {
                mxError("The data file seems to yield invalid data. If it persists, consider deleting the file " + PlayLaterJSON, true);
                return m_maps;
            }
            MX::MapInfo@ map = MX::MapInfo(FileData[i]);
            m_maps.InsertAt(0, map);
        }
        print(tostring(m_maps.Length) + " maps loaded from Play Later list.");
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