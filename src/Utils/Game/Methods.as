namespace TM {
    void LoadMapAsync(int64 mapId) {
        LoadMap(mapId);
    }

    void LoadMap(int mapId, bool intoEditor = false) {
#if MP4
        if (TM::CurrentTitlePack() == "") {
            Logging::Error("You must select a title pack before opening a map", true);
            return;
        }
#elif TMNEXT
        if (intoEditor && !Permissions::OpenAdvancedMapEditor()) {
            Logging::Error("You don't have permission to open the advanced map editor.", true);
            return;
        }
        
        if (!intoEditor && !Permissions::PlayLocalMap()) {
            Logging::Error("You don't have permission to play custom maps.", true);
            return;
        }
#endif

        auto json = API::GetAsync(MXURL + "/api/maps?fields=" + MX::mapFields + "&id=" + mapId);

        if (json.GetType() == Json::Type::Null || !json.HasKey("Results") || json["Results"].Length == 0) {
            Logging::Error("Track not found.", true);
            return;
        }

        MX::MapInfo@ map = MX::MapInfo(json["Results"][0]);

        LoadMap(map, intoEditor);
    }

    void LoadMap(MX::MapInfo@ map, bool intoEditor = false) {
        try {
#if MP4
            if (TM::CurrentTitlePack() == "") {
                Logging::Error("You must select a title pack before opening a map", true);
                return;
            }
#elif TMNEXT
            if (intoEditor && !Permissions::OpenAdvancedMapEditor()) {
                Logging::Error("You don't have permission to open the advanced map editor.", true);
                return;
            }
            
            if (!intoEditor && !Permissions::PlayLocalMap()) {
                Logging::Error("You don't have permission to play custom maps.", true);
                return;
            }

            TM::ClosePauseMenu();
#endif

            if (Setting_CloseOverlayOnLoad && UI::IsOverlayShown()) {
                UI::HideOverlay();
            }

            CTrackMania@ app = cast<CTrackMania>(GetApp());
            app.BackToMainMenu(); // If we're on a map, go back to the main menu else we'll get stuck on the current map

            while (!app.ManiaTitleControlScriptAPI.IsReady) {
                yield();
            }

            if (intoEditor) {
                app.ManiaTitleControlScriptAPI.EditMap(MXURL + "/mapgbx/" + map.MapId + "?t=" + map.UpdatedAt, "", "");
            } else {
                string Mode = "";
                MX::ModesFromMapType.Get(map.MapType, Mode);

#if MP4
                if (Mode == "" && repo == MP4mxRepos::Trackmania) {
                    const string loadedTP = TM::CurrentTitlePack();
                    MX::ModesFromTitlePack.Get(loadedTP, Mode);
                }
#endif

                app.ManiaTitleControlScriptAPI.PlayMap(MXURL + "/mapgbx/" + map.MapId + "?t=" + map.UpdatedAt, Mode, "");
            }
        } catch {
            Logging::Error("Error while loading map: " + getExceptionInfo(), true);
        }
    }

    bool IsInEditor() {
        auto app = GetApp();
        return app.Editor !is null;
    }

    bool IsInServer() {
        auto network = cast<CTrackManiaNetwork>(GetApp().Network);

        if (network is null) {
            return false;
        }

        auto server = cast<CGameCtnNetServerInfo>(network.ServerInfo);
        return server.JoinLink != "";
    }

    void ClosePauseMenu() {
        if (IsPauseMenuDisplayed()) {
            auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);

            if (playground !is null) {
                playground.Interface.ManialinkScriptHandler.CloseInGameMenu(CGameScriptHandlerPlaygroundInterface::EInGameMenuResult::Resume);
            }
        }
    }

    bool IsPauseMenuDisplayed() {
        auto app = cast<CTrackMania>(GetApp());
        return app.ManiaPlanetScriptAPI.ActiveContext_InGameMenuDisplayed;
    }

    CGameCtnChallenge@ GetCurrentMap() {
        auto app = GetApp();
        return app.RootMap;
    }

    bool IsMapCorrect(const string &in mapUid) {
        CGameCtnChallenge@ map = GetCurrentMap();

        return map !is null && map.IdName == mapUid;
    }

    string CurrentTitlePack() {
        auto app = cast<CTrackMania>(GetApp());

        if (app.LoadedManiaTitle is null) {
            return "";
        }

        string titleId = app.LoadedManiaTitle.TitleId;

#if MP4
        return titleId.SubStr(0, titleId.IndexOf("@"));
#else
        return titleId;
#endif
    }
}
