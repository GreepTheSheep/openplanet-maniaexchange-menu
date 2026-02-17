namespace TM {
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
