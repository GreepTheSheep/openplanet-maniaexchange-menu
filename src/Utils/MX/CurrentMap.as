namespace MX {
    enum MapStatus {
        InEditor = -5,
        Not_In_Map,
        LoadingInfo,
        Error,
        Not_Found,
        Found
    }

    MapStatus CurrentStatus = MapStatus::Not_In_Map;
    MX::MapInfo@ CurrentMapInfo;
    dictionary foundMaps;

    bool IsCurrentMapCorrect() {
        return CurrentMapInfo !is null && TM::IsMapCorrect(CurrentMapInfo.MapUid);
    }

    void FetchCurrentMapInfo() {
        while (CurrentStatus == MapStatus::LoadingInfo) {
            yield();
        }

        if (TM::IsInEditor()) {
            CurrentStatus = MapStatus::InEditor;
            @CurrentMapInfo = null;
            return;
        }

        auto loadedMap = TM::GetCurrentMap();

        if (loadedMap is null) {
            CurrentStatus = MapStatus::Not_In_Map;
            @CurrentMapInfo = null;
            return;
        }

        if (IsCurrentMapCorrect()) {
            return;
        }

        if (foundMaps.Exists(loadedMap.IdName)) {
            CurrentStatus = MapStatus::Found;
            @CurrentMapInfo = cast<MX::MapInfo>(foundMaps[loadedMap.IdName]);
            return;
        }

        CurrentStatus = MapStatus::LoadingInfo;

        try {
            MX::MapInfo@ map = MX::GetMapByUid(loadedMap.IdName);

            if (map is null) {
                CurrentStatus = MapStatus::Not_Found;
                @CurrentMapInfo = null;
                return;
            }

            CurrentStatus = MapStatus::Found;
            @CurrentMapInfo = map;
            foundMaps.Set(map.MapUid, @map);
        } catch {
            Logging::Debug("[MapLoop] An error happened while getting the current map on MX: " + getExceptionInfo());
            CurrentStatus = MapStatus::Error;
            @CurrentMapInfo = null;
        }
    }

    const uint LOOP_COOLDOWN = 60000;

    void MapLoop() {
        while (true) {
            yield();

            if (!mainMenuOpen || MX::APIDown) {
                continue;
            }

            auto loadedMap = TM::GetCurrentMap();

            if (CurrentStatus != MapStatus::LoadingInfo) {
                MX::FetchCurrentMapInfo();
            }

            if (loadedMap !is null && (CurrentStatus == MapStatus::Error || CurrentStatus == MapStatus::Not_Found)) {
                uint now = Time::Now;

                // Yield for 1 minute, unless the map has changed
                while (Time::Now < now + LOOP_COOLDOWN && TM::IsMapCorrect(loadedMap.IdName)) {
                    yield();
                }
            }
        }
    }
}
