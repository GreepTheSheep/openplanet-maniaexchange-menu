bool IsDevMode(){
    return Meta::ExecutingPlugin().get_Type() == Meta::PluginType::Folder;
}

bool IsInEditor(){
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    auto editor = cast<CGameCtnEditorCommon@>(app.Editor);
    return editor !is null && app.CurrentPlayground is null;
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
        mxError("The data file seems to yield invalid data. If it persists, consider deleting the file " + PlayLaterJSON, true);
        return m_maps;
    } else {
        for (uint i = 0; i < FileData.get_Length(); i++) {
            if (IsDevMode()) {
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
    for (uint i = 0; i < maps.get_Length(); i++) {
        FileData.Add(maps[i].ToJson());
    }
    Json::ToFile(PlayLaterJSON, FileData);
}