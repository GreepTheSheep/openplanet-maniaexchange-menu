bool IsDevMode(){
    return Meta::ExecutingPlugin().get_Type() == Meta::PluginType::Folder;
}

CGameCtnChallenge@ GetCurrentMap(){
    CTrackMania@ g_app = cast<CTrackMania>(GetApp());
    return g_app.RootMap;
}

array<MX::MapInfo@> LoadPlayLater() {
    array<MX::MapInfo@> m_maps;
    Json::Value FileData = Json::FromFile(PlayLaterJSON);
    if (FileData.GetType() == Json::Type::Null) {
        UI::ShowNotification("\\$afa" + Icons::InfoCircle + " Thanks for installing "+pluginName+"!","No data file was detected, that means it's your first install. Welcome!", 15000);
        SavePlayLater(m_maps);
        return m_maps;
    } else if (FileData.GetType() != Json::Type::Array) {
        error("The data file seems to yield invalid data. If it persists, consider deleting the file " + PlayLaterJSON, "is not of the correct JSON type.");
        return m_maps;
    } else {
        for (uint i = 0; i < FileData.get_Length(); i++) {
            if (IsDevMode()) {
                string mapName = FileData[i]["Name"];
                log("Loading map #"+i+" from Play later: " + mapName);
            }
            if (FileData[i].GetType() != Json::Type::Object) {
                error("The data file seems to yield invalid data. If it persists, consider deleting the file " + PlayLaterJSON, "is not of the correct JSON type.");
                return m_maps;
            }
            MX::MapInfo@ map = MX::MapInfo(FileData[i]);
            m_maps.InsertAt(0, map);
        }
        log(tostring(m_maps.Length) + " maps loaded from Play Later list.");
        return m_maps;
    }
}

void SavePlayLater(array<MX::MapInfo@> maps) {
    Json::Value FileData = Json::Array();
    for (uint i = 0; i < maps.get_Length(); i++) {
        FileData.Add(maps[i].ToJson());
    }
    Json::ToFile(PlayLaterJSON, FileData);
}