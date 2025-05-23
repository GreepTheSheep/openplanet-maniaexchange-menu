class MapTab : Tab
{
    Net::HttpRequest@ m_MXrequest;
    Net::HttpRequest@ m_TMIOrequest;
    Net::HttpRequest@ m_MXEmbedObjRequest;
    Net::HttpRequest@ m_MXReplaysRequest;
    Net::HttpRequest@ m_MXCommentsRequest;
    MX::MapInfo@ m_map;
    array<TMIO::Leaderboard@> m_leaderboard;
    array<MX::MapReplay@> m_replays;
    array<MX::MapComment@> m_comments;
    int m_mapId;
    string m_mapUid = "";
    bool m_isMapOnNadeoServices = false;
    bool m_isLoading = false;
    bool m_mapDownloaded = false;
    bool m_isMapOnPlayLater = false;
    bool m_isMapOnFavorite = false;
    bool m_error = false;
    bool m_TMIOrequestStart = false;
    bool m_TMIOrequestStarted = false;
    bool m_TMIOstopleaderboard = false;
    bool m_TMIOerror = false;
    string m_TMIOerrorMsg = "";
    bool m_TMIONoRes = false;
    array<MX::MapEmbeddedObject@> m_mapEmbeddedObjects;
    bool m_mapEmbeddedObjectsError = false;
    bool m_replaysError = false;
    bool m_replaysstopleaderboard = false;
    bool m_commentsStopRequest = false;
    bool m_commentsError = false;

    MapTab(int trackId) {
        m_mapId = trackId;
        StartMXRequest();
    }

    MapTab(const string &in trackUid) {
        m_mapUid = trackUid;
        StartMXRequest();
    }

    MapTab(MX::MapInfo@ map) {
        @m_map = map;

#if DEPENDENCY_NADEOSERVICES
        startnew(CoroutineFunc(CheckIfMapExistsNadeoServices));
#endif
    }

    bool CanClose() override { return !m_isLoading; }

    string GetLabel() override {
        if (m_error) {
            m_isLoading = false;
            return "\\$f00"+Icons::Times+" \\$zError";
        }
        if (m_map is null) {
            m_isLoading = true;
            return Icons::Map+" Loading...";
        } else {
            m_isLoading = false;
            string res = Icons::Map+" ";
            if (Setting_ColoredMapName) res += Text::OpenplanetFormatCodes(m_map.GbxMapName);
            else res += m_map.Name;
            return res;
        }
    }

#if DEPENDENCY_NADEOSERVICES
    void CheckIfMapExistsNadeoServices()
    {
        m_isMapOnNadeoServices = MXNadeoServicesGlobal::CheckIfMapExistsAsync(m_map.MapUid);
    }
#endif

    void StartMXRequest()
    {
        dictionary params;
        params.Set("fields", MX::mapFields);

        if (m_mapUid != "") {
            params.Set("uid", m_mapUid);
        } else {
            params.Set("id", tostring(m_mapId));
        }

        string urlParams = MX::DictToApiParams(params);

        string url = "https://"+MXURL+"/api/maps" + urlParams;
        Logging::Debug("MapTab::StartRequest (MX): "+url);
        @m_MXrequest = API::Get(url);
    }

    void CheckMXRequest()
    {
        // If there's a request, check if it has finished
        if (m_MXrequest !is null && m_MXrequest.Finished()) {
            // Parse the response
            string res = m_MXrequest.String();
            int resCode = m_MXrequest.ResponseCode();
            auto json = m_MXrequest.Json();
            @m_MXrequest = null;

            Logging::Debug("MapTab::CheckRequest (MX): " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
                Logging::Error("MapTab::CheckRequest (MX): Error parsing response");
                m_error = true;
                return;
            } else if (json["Results"].Length == 0) {
                // This should be impossible
                string reqId = m_mapUid != "" ? m_mapUid : tostring(m_mapId);
                Logging::Error("MapTab::CheckRequest (MX): Failed to find a map with UID/ID " + reqId);
                m_error = true;
                return;
            }
            // Handle the response
            @m_map = MX::MapInfo(json["Results"][0]);
#if DEPENDENCY_NADEOSERVICES
            startnew(CoroutineFunc(CheckIfMapExistsNadeoServices));
#endif
        }
    }

    void StartMXReplaysRequest()
    {
        string url = "https://"+MXURL+"/api/replays?best=1&mapId=" + m_map.MapId;
        Logging::Debug("MapTab::StartRequest (Replays): "+url);
        @m_MXReplaysRequest = API::Get(url);
    }

    void CheckMXReplaysRequest()
    {
        if (!MX::APIDown && !m_replaysstopleaderboard && !m_replaysError && m_MXReplaysRequest is null && UI::IsWindowAppearing()) {
            StartMXReplaysRequest();
        }
        // If there's a request, check if it has finished
        if (m_MXReplaysRequest !is null && m_MXReplaysRequest.Finished()) {
            // Parse the response
            string res = m_MXReplaysRequest.String();
            int resCode = m_MXReplaysRequest.ResponseCode();
            auto json = m_MXReplaysRequest.Json();
            @m_MXReplaysRequest = null;

            Logging::Debug("MapTab::CheckRequest (Replays): " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
                Logging::Error("MapTab::CheckRequest (Replays): Error parsing response");
                m_replaysError = true;
                return;
            } else if (json["Results"].Length == 0) {
                Logging::Error("MapTab::CheckRequest (Replays): API returned 0 replays! Expected " + m_map.ReplayCount);
                m_replaysError = true;
                return;
            }

            if (m_replays.Length > 0) {
                // Remove any remaining replays if there's any
                m_replays.RemoveRange(0, m_replays.Length);
            }

            // Handle the response
            Json::Value@ mapReplays = json["Results"];

            for (uint i = 0; i < mapReplays.Length; i++) {
                MX::MapReplay@ replay = MX::MapReplay(mapReplays[i]);
                m_replays.InsertLast(replay);
            }
            m_replaysstopleaderboard = true;
        }
    }

    void StartTMIORequest(int offset = 0)
    {
        if (m_map is null) return;
        string url = "https://trackmania.io/api/leaderboard/map/"+m_map.MapUid;
        if (offset != -1) url += "?length=100&offset=" + offset;
        Logging::Debug("MapTab::StartRequest (TM.IO): "+url);
        m_TMIOrequestStarted = true;
        @m_TMIOrequest = API::Get(url);
    }

    void CheckTMIORequest()
    {
        // If there's a request, check if it has finished
        if (m_TMIOrequest !is null && m_TMIOrequest.Finished()) {
            // Parse the response
            string res = m_TMIOrequest.String();
            auto json = m_TMIOrequest.Json();
            @m_TMIOrequest = null;

            Logging::Debug("MapTab::CheckRequest (TM.IO): " + res);

            // if error, handle it (particular case for "not found on API")
            if (json.HasKey("error")){
                HandleTMIOResponseError(json["error"]);
            } else {
                // if tops is null return no results, else handle the response
                if (json["tops"].GetType() == Json::Type::Null) {
                    Logging::Info("MapTab::CheckRequest (TM.IO): No results");
                    m_TMIONoRes = true;
                }
                else HandleTMIOResponse(json["tops"]);
            }
            m_TMIOrequestStarted = false;
        }
    }

    void HandleTMIOResponse(const Json::Value &in json)
    {
        if (json.Length < 100) m_TMIOstopleaderboard = true;

        for (uint i = 0; i < json.Length; i++) {
            auto leaderboard = TMIO::Leaderboard(json[i]);
            m_leaderboard.InsertLast(leaderboard);
        }
    }

    void HandleTMIOResponseError(const string &in error)
    {
        m_TMIOerror = true;
        if (error.Contains("does not exist")) {
            m_TMIOerrorMsg = "This map is not available on Nadeo Services";
        } else {
            m_TMIOerrorMsg = error;
        }
    }

    void StartMXEmbeddedRequest()
    {
        string url = "https://"+MXURL+"/api/maps/objects?trackId=" + m_map.MapId + "&count=" + m_map.EmbeddedObjectsCount;
        Logging::Debug("MapTab::StartRequest (Embedded): "+url);
        @m_MXEmbedObjRequest = API::Get(url);
    }

    void CheckMXEmbeddedRequest()
    {
        if (!MX::APIDown && m_mapEmbeddedObjects.Length != m_map.EmbeddedObjectsCount && !m_mapEmbeddedObjectsError && m_MXEmbedObjRequest is null && UI::IsWindowAppearing()) {
            StartMXEmbeddedRequest();
        }
        // If there's a request, check if it has finished
        if (m_MXEmbedObjRequest !is null && m_MXEmbedObjRequest.Finished()) {
            // Parse the response
            string res = m_MXEmbedObjRequest.String();
            int resCode = m_MXEmbedObjRequest.ResponseCode();
            auto json = m_MXEmbedObjRequest.Json();
            @m_MXEmbedObjRequest = null;

            Logging::Debug("MapTab::CheckRequest (Embedded): " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
                Logging::Info("MapTab::CheckRequest (Embedded): Error parsing response");
                m_mapEmbeddedObjectsError = true;
                return;
            } else if (json["Results"].Length == 0) {
                Logging::Error("MapTab::CheckRequest (Embedded): API returned 0 embedded objects! Expected " + m_map.EmbeddedObjectsCount);
                m_mapEmbeddedObjectsError = true;
                return;
            }

            // Handle the response
            Json::Value@ mapObjects = json["Results"];

            for (uint i = 0; i < mapObjects.Length; i++) {
                MX::MapEmbeddedObject@ object = MX::MapEmbeddedObject(mapObjects[i], int(i) < Setting_EmbeddedObjectsLimit);
                m_mapEmbeddedObjects.InsertLast(object);
            }
        }
    }

    void StartMXCommentsRequest()
    {
        string url = "https://"+MXURL+"/api/maps/comments?trackId=" + m_map.MapId + "&count=50&fields=" + MX::commentFields;
        Logging::Debug("MapTab::StartRequest (Comments): " + url);
        @m_MXCommentsRequest = API::Get(url);
    }

    void CheckMXCommentsRequest()
    {
        if (!MX::APIDown && !m_commentsStopRequest && !m_commentsError && m_MXCommentsRequest is null && UI::IsWindowAppearing()) {
            StartMXCommentsRequest();
        }

        if (m_MXCommentsRequest !is null && m_MXCommentsRequest.Finished()) {
            string res = m_MXCommentsRequest.String();
            int resCode = m_MXCommentsRequest.ResponseCode();
            auto json = m_MXCommentsRequest.Json();
            @m_MXCommentsRequest = null;

            Logging::Debug("MapTab::CheckRequest (Comments): " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
                Logging::Info("MapTab::CheckRequest (Comments): Error parsing response");
                m_commentsError = true;
                return;
            }

            // Handle the response
            Json::Value@ mapComments = json["Results"];

            for (uint i = 0; i < mapComments.Length; i++) {
                MX::MapComment@ comment = MX::MapComment(mapComments[i]);
                m_comments.InsertLast(comment);
            }

            m_commentsStopRequest = true;
        }
    }
    void Render() override
    {
        CheckMXRequest();

        if (m_error) {
            UI::Text("\\$f00" + Icons::Times + " \\$zMap not found");
            return;
        }

        if (m_map is null) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
            return;
        }

        // Check if the map is already on the play later list
        for (uint i = 0; i < g_PlayLaterMaps.Length; i++) {
            MX::MapInfo@ playLaterMap = g_PlayLaterMaps[i];
            if (playLaterMap.MapId != m_map.MapId) {
                m_isMapOnPlayLater = false;
            } else {
                m_isMapOnPlayLater = true;
                break;
            }
        }

#if DEPENDENCY_NADEOSERVICES
        // Check if the map is already on the favorites list
        for (uint i = 0; i < MXNadeoServicesGlobal::g_favoriteMaps.Length; i++) {
            NadeoServices::MapInfo@ favoriteMap = MXNadeoServicesGlobal::g_favoriteMaps[i];
            if (favoriteMap.uid != m_map.MapUid) {
                m_isMapOnFavorite = false;
            } else {
                m_isMapOnFavorite = true;
                break;
            }
        }
#endif

        float width = UI::GetWindowSize().x*0.3;
        vec2 posTop = UI::GetCursorPos();

        UI::BeginChild("Summary", vec2(width,0));

        UI::BeginTabBar("MapImages");

        for (uint i = 0; i < m_map.Images.Length; i++) {
            MX::MapImage@ currImage = m_map.Images[i];

            if (UI::BeginTabItem(tostring(currImage.Position))) {
                auto img = Images::CachedFromURL("https://"+MXURL+"/mapimage/"+m_map.MapId+"/"+currImage.Position+"?hq=true");

                if (img.m_texture !is null){
                    vec2 thumbSize = img.m_texture.GetSize();
                    UI::Image(img.m_texture, vec2(
                        width,
                        thumbSize.y / (thumbSize.x / width)
                    ));

                    UI::MXThumbnailTooltip(img, 0.3);
                } else if (!img.m_error) {
                    int HourGlassValue = Time::Stamp % 3;
                    string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                    UI::Text(Hourglass + " Loading");
                } else if (img.m_unsupportedFormat) {
                    UI::Text(Icons::FileImageO + " \\$zUnsupported file format WEBP");
                } else if (img.m_notFound) {
                    UI::Text("\\$fc0"+Icons::ExclamationTriangle+" \\$Image not found");
                } else {
                    UI::Text(Icons::Times+" \\$zError while loading image");
                }
                UI::EndTabItem();
            }
        }

        if(UI::BeginTabItem("Thumbnail")){
            auto thumb = Images::CachedFromURL("https://"+MXURL+"/mapthumb/"+m_map.MapId);
            if (thumb.m_texture !is null){
                vec2 thumbSize = thumb.m_texture.GetSize();
                UI::Image(thumb.m_texture, vec2(
                    width,
                    thumbSize.y / (thumbSize.x / width)
                ));

                UI::MXThumbnailTooltip(thumb, 0.3);
            } else if (!thumb.m_error) {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Loading");
            } else if (thumb.m_unsupportedFormat) {
                UI::Text(Icons::FileImageO + " \\$zUnsupported file format WEBP");
            } else if (thumb.m_notFound) {
                UI::Text("\\$fc0"+Icons::ExclamationTriangle+" \\$zThumbnail not found");
            } else {
                UI::Text(Icons::Times+" \\$zError while loading thumbnail");
            }
            UI::EndTabItem();
        }

        UI::EndTabBar();
        UI::Separator();

        for (uint i = 0; i < m_map.Tags.Length; i++) {
            IfaceRender::MapTag(m_map.Tags[i]);
            UI::SameLine();
        }
        UI::NewLine();

        UI::Text(Icons::Trophy + " \\$f77" + m_map.AwardCount);
        UI::SetItemTooltip("Awards");
#if MP4
        if (repo == MP4mxRepos::Trackmania) {
#endif
        UI::Text(Icons::Hourglass + " \\$f77" + Time::Format(m_map.Length));
        UI::SetItemTooltip("Length");
        if (m_map.Laps >= 1) {
            UI::Text(Icons::Refresh+ " \\$f77" + m_map.Laps);
            UI::SetItemTooltip("Laps");
        }
#if MP4
        }
#endif
        UI::Text(Icons::LevelUp+ " \\$f77" + m_map.DifficultyName);
        UI::SetItemTooltip("Difficulty");

        UI::Text(Icons::Hashtag+ " \\$f77" + m_map.MapId);
        UI::SetItemTooltip("Track ID");
        UI::SameLine();
        UI::TextDisabled(Icons::Clipboard);
        UI::SetItemTooltip("Click to copy to clipboard");
        if (UI::IsItemClicked()) {
            IO::SetClipboard(tostring(m_map.MapId));
            UI::ShowNotification(Icons::Clipboard + " Track ID copied to clipboard");
        }

        UI::Text(Icons::FileCodeO+ " \\$f77" + m_map.MapType);
        UI::SetItemTooltip("Map Type");
        UI::Text(Icons::Calendar + " \\$f77" + m_map.UploadedAt);
        UI::SetItemTooltip("Uploaded date");
        if (m_map.UploadedAt != m_map.UpdatedAt) {
            UI::Text(Icons::Refresh + " \\$f77" + m_map.UpdatedAt);
            UI::SetItemTooltip("Updated date");
        }
#if MP4
        UI::Text(Icons::Inbox + " \\$f77" + m_map.TitlePack);
        UI::SetItemTooltip("Title Pack");
        if (repo == MP4mxRepos::Trackmania) {
            UI::Text(Icons::Tree + " \\$f77" + m_map.EnvironmentName);
            UI::SetItemTooltip("Environment");
#endif
            UI::Text(Icons::Car + " \\$f77" + m_map.VehicleName);
            UI::SetItemTooltip("Vehicle");
#if MP4
        }
#endif
        UI::Text(Icons::Sun + " \\$f77" + m_map.Mood);
        UI::SetItemTooltip("Mood");
        UI::Text(Icons::Money + " \\$f77" + m_map.DisplayCost);
        UI::SetItemTooltip("Coppers cost");

        // TODO doesn't work with v2 anymore
        // if (UI::GoldButton(Icons::Trophy + " Award this map on "+shortMXName)) OpenBrowserURL("https://"+MXURL+"/mapshow/"+m_map.MapId+"#award");

        if (UI::CyanButton(Icons::ExternalLink + " View on "+pluginName)) OpenBrowserURL("https://"+MXURL+"/mapshow/"+m_map.MapId);
#if TMNEXT
        if (UI::Button(Icons::ExternalLink + " View on Trackmania.io")) OpenBrowserURL("https://trackmania.io/#/leaderboard/"+m_map.MapUid);
#endif

#if TMNEXT
        if (Permissions::PlayLocalMap()) {
#endif

            bool isMapTypeSupported = MX::ModesFromMapType.Exists(m_map.MapType);
            if (!isMapTypeSupported) {
                UI::Text("\\$f70" + Icons::ExclamationTriangle + " \\$zThe map type is not supported for direct play\nit can crash your game or returns you to the menu");
                if (!Setting_ShowPlayOnAllMaps) {
                    UI::SetItemTooltip("If you still want to play this map, check the box \"Show Play Button on all map types\" in the plugin settings");
                }
                if (Setting_ShowPlayOnAllMaps && UI::OrangeButton(Icons::Play + " Play Map Anyway")) {
                    if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                    UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(m_map.GbxMapName) + "\\$z\\$s by " + m_map.Username);
                    UI::ShowNotification(Icons::ExclamationTriangle + " Warning", "The map type is not supported for direct play, it can crash your game or returns you to the menu", UI::HSV(0.11, 1.0, 1.0), 15000);
                    MX::mapToLoad = m_map.MapId;
                }
            } else {
                if (UI::GreenButton(Icons::Play + " Play Map")) {
                    if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                    UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(m_map.GbxMapName) + "\\$z\\$s by " + m_map.Username);
                    MX::mapToLoad = m_map.MapId;
                }
#if TMNEXT && DEPENDENCY_NADEOSERVICES
                if (isMapTypeSupported && Permissions::CreateAndUploadMap() && IsInServer()) {
                    CTrackMania@ app = cast<CTrackMania>(GetApp());
                    bool sameMapType = CleanMapType(app.RootMap.MapType) == m_map.MapType;

                    UI::BeginDisabled(!sameMapType || m_map.ServerSizeExceeded);
                    if (UI::GreenButton(Icons::Server + " Play Map on Nadeo-hosted Room")) {
                        TMNext::AddMapToServer_MapUid = m_map.MapUid;
                        TMNext::AddMapToServer_MapMXId = m_map.MapId;
                        TMNext::AddMapToServer_MapType = m_map.MapType;
                        Renderables::Add(PlayMapOnNadeoRoomInfos());
                    }
                    UI::EndDisabled();
                    if (!sameMapType) UI::SetItemTooltip(Icons::Times + " Map type doesn't match the current room's game mode");
                    else if (m_map.ServerSizeExceeded) UI::SetItemTooltip(Icons::Times + " Map size exceeds the server limit of 7MB");
                }
#endif
            }
#if TMNEXT
        } else {
            UI::Text("\\$f00"+Icons::Times + " \\$zYou do not have permissions to play");
            UI::Text("Consider buying club access of the game.");
        }
#endif

#if TMNEXT
        if (Permissions::OpenAdvancedMapEditor()) {
#endif
            if (UI::YellowButton(Icons::Wrench + " Edit Map")) {
                if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(m_map.GbxMapName) + "\\$z\\$s by " + m_map.Username);
                MX::mapToEdit = m_map.MapId;
            }
#if TMNEXT
        } else {
            UI::Text("\\$f00"+Icons::Times + " \\$zYou do not have permissions to edit maps");
            UI::Text("Consider buying at least club access of the game.");
        }
#endif

        if (MX::mapDownloadInProgress){
            UI::Text("\\$f70" + Icons::Download + " \\$zDownloading map...");
            m_isLoading = true;
        } else {
            m_isLoading = false;
            if (!m_mapDownloaded) {
                if (UI::PurpleButton(Icons::Download + " Download Map")) {
                    UI::ShowNotification("Downloading map...", Text::OpenplanetFormatCodes(m_map.GbxMapName) + "\\$z\\$s by " + m_map.Username);
                    MX::mapToDL = m_map.MapId;
                    m_mapDownloaded = true;
                }
            } else {
                UI::Text("\\$0f0" + Icons::Download + " \\$zMap downloaded");
                UI::PushStyleColor(UI::Col::Text, UI::GetStyleColor(UI::Col::TextDisabled));
                UI::TextWrapped("to " + "Maps\\Downloaded\\"+pluginName+"\\" + m_map.MapId + " - " + Path::SanitizeFileName(m_map.Name) + ".Map.Gbx");
                UI::PopStyleColor();
                if (UI::RoseButton(Icons::FolderOpen + " Open Containing Folder")) OpenExplorerPath(IO::FromUserGameFolder("Maps/Downloaded/"+pluginName));
            }
        }

        if (!m_isMapOnPlayLater){
#if TMNEXT
            if (Permissions::PlayLocalMap() && UI::GreenButton(Icons::Check + " Add to Play later")) {
#else
            if (UI::GreenButton(Icons::Check + " Add to Play later")) {
#endif
                g_PlayLaterMaps.InsertAt(0, m_map);
                m_isMapOnPlayLater = true;
                SavePlayLater(g_PlayLaterMaps);
            }
        } else {
#if TMNEXT
            if (Permissions::PlayLocalMap() && UI::RedButton(Icons::Times + " Remove from Play later")) {
#else
            if (UI::RedButton(Icons::Times + " Remove from Play later")) {
#endif
                for (uint i = 0; i < g_PlayLaterMaps.Length; i++) {
                    MX::MapInfo@ playLaterMap = g_PlayLaterMaps[i];
                    if (playLaterMap.MapId == m_map.MapId) {
                        g_PlayLaterMaps.RemoveAt(i);
                        m_isMapOnPlayLater = false;
                        SavePlayLater(g_PlayLaterMaps);
                    }
                }
            }
        }

#if DEPENDENCY_NADEOSERVICES
        if (!m_isMapOnFavorite){
            UI::BeginDisabled(!m_isMapOnNadeoServices);
#if TMNEXT
            if (Permissions::PlayLocalMap() && UI::GreenButton(Icons::Heart + " Add to Favorites")) {
#else
            if (UI::GreenButton(Icons::Heart + " Add to Favorites")) {
#endif
                startnew(MXNadeoServicesGlobal::AddMapToFavoritesAsync, m_map);
            }
            UI::EndDisabled();
            if (!m_isMapOnNadeoServices) UI::SetItemTooltip(Icons::ExclamationTriangle + " This map is not on Nadeo Services, can't add it to your favorites");
        } else {
#if TMNEXT
            if (Permissions::PlayLocalMap() && UI::RedButton(Icons::Heart + " Remove from Favorites")) {
#else
            if (UI::RedButton(Icons::Heart + " Remove from Favorites")) {
#endif
                for (uint i = 0; i < MXNadeoServicesGlobal::g_favoriteMaps.Length; i++) {
                    NadeoServices::MapInfo@ favoriteMap = MXNadeoServicesGlobal::g_favoriteMaps[i];
                    if (favoriteMap.uid == m_map.MapUid) {
                        startnew(MXNadeoServicesGlobal::RemoveMapFromFavoritesAsync, favoriteMap);
                        break;
                    }
                }
            }
        }
#endif

        UI::EndChild();

        UI::SetCursorPos(posTop + vec2(width + 8, 0));
        UI::BeginChild("Description");

        UI::PushFont(Fonts::BigBold);
        UI::TextWrapped(Text::OpenplanetFormatCodes(m_map.GbxMapName));
        UI::PopFont();

        if (m_map.Authors.Length > 0) {
            UI::TextDisabled("By: ");
            UI::SameLine();
            for (uint i = 0; i < m_map.Authors.Length; i++) {
                MX::MapAuthorInfo@ author = m_map.Authors[i];
                UI::TextDisabled(author.Name + (i == m_map.Authors.Length - 1 ? "" : ", "));
                if (UI::BeginItemTooltip()) {
                    if (author.Uploader) {
                        UI::Text(Icons::CloudUpload + " Uploader");
                        UI::Separator();
                    }
                    if (author.Role != "") {
                        UI::Text(author.Role);
                        UI::Separator();
                    }
                    UI::TextDisabled("Click to see " + author.Name + "'s profile");
                    UI::EndTooltip();
                }
                if (UI::IsItemClicked()) mxMenu.AddTab(UserTab(author.UserId), true);
                if (i < m_map.Authors.Length - 1) UI::SameLine();
            }
        } else {
            UI::TextDisabled("By " + m_map.Username);
        }

        if (m_map.ServerSizeExceeded)
#if MP4
            UI::Text("\\$f70" + Icons::ExclamationTriangle + " \\$zThis map is larger than 4MB and therefore can not be played on servers.");
#else
            UI::Text("\\$f70" + Icons::ExclamationTriangle + " \\$zThis map is larger than 7MB and therefore can not be played on servers.");
#endif

        UI::Separator();

        UI::BeginTabBar("MapTabs");

        if(UI::BeginTabItem("Description")){
            UI::BeginChild("MapDescriptionChild");
            UI::Markdown(m_map.AuthorComments);
            UI::EndChild();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem(shortMXName + " Leaderboard")) {
            UI::BeginChild("MapMXLeaderboardChild");

            if (UI::GreenButton(Icons::ExternalLink + " Submit")) OpenBrowserURL("https://"+MXURL+"/replayupload/"+m_map.MapId);

            if (m_map.ReplayCount == 0) {
                UI::Text("No records found for this map. Be the first!");
            } else {
                CheckMXReplaysRequest();

                if (m_MXReplaysRequest !is null && !m_MXReplaysRequest.Finished()) {
                    int HourGlassValue = Time::Stamp % 3;
                    string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                    UI::Text(Hourglass + " Loading...");
                } else if (m_replaysError) {
                    UI::Text("\\$f00" + Icons::Times + "\\$z Error while loading leaderboard");
                } else {
                    UI::SameLine();
                    if (UI::Button(Icons::Refresh)) {
                        m_replays.RemoveRange(0, m_replays.Length);
                        m_replaysstopleaderboard = false;
                        StartMXReplaysRequest();
                    }
                    if (UI::BeginTable("MXLeaderboardList", 4, UI::TableFlags::RowBg)) {
                        UI::TableSetupScrollFreeze(0, 1);
                        PushTabStyle();
                        UI::TableSetupColumn("Position", UI::TableColumnFlags::WidthFixed, 40);
                        UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
                        UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthStretch);
                        UI::TableSetupColumn("Score", UI::TableColumnFlags::WidthStretch);
                        UI::TableHeadersRow();
                        PopTabStyle();
                        UI::ListClipper clipper(m_replays.Length);
                        while(clipper.Step()) {
                            for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                                UI::TableNextRow();
                                MX::MapReplay@ entry = m_replays[i];

                                UI::TableNextColumn();
                                UI::AlignTextToFramePadding();
                                if (entry.IsValid) {
                                    if (m_replays[0].Position == 0) { // TODO remove once Position is fixed
                                        UI::Text(tostring(entry.Position + 1));
                                    } else {
                                        UI::Text(tostring(entry.Position));
                                    }
                                } else {
                                    UI::Text("\\$f00" + Icons::Exclamation);
                                    UI::SetItemTooltip("Replay was driven on a different version of the map");
                                }

                                UI::TableNextColumn();
                                bool isUser = Setting_Tab_YourProfile_UserID == entry.UserId;
                                UI::Text(entry.Username + (isUser ? " " + Icons::User : ""));
                                UI::SetItemTooltip("Click to see "+entry.Username+"'s profile");
                                if (UI::IsItemClicked()) mxMenu.AddTab(UserTab(entry.UserId), true);

                                UI::TableNextColumn();
                                if (m_map.GameMode == MX::GameModes::Stunt) {
                                    UI::Text(entry.ReplayPoints + " pts");
                                } else {
                                    UI::Text(Time::Format(entry.ReplayTime));
                                }

                                if (i != 0){
                                    UI::SameLine();
                                    if (m_map.GameMode == MX::GameModes::Stunt) {
                                        UI::Text("\\$f00(− " + (m_replays[0].ReplayPoints - entry.ReplayPoints) + ")");
                                    } else {
                                        UI::Text("\\$f00(+ " + Time::Format(entry.ReplayTime - m_replays[0].ReplayTime) + ")");
                                    }
                                }

                                UI::TableNextColumn();

                                if (m_replays[0].Score == 0) {
                                    UI::Text("−");
                                } else {
                                    UI::Text(tostring(entry.Score) + " \\$666("+tostring(entry.Percentage)+"%)"); // TODO missing percentage
                                    if (i != 0) {
                                        UI::SameLine();
                                        UI::Text("\\$a66(" + (entry.Score - m_replays[0].Score) + ")");
                                    }
                                }
                            }
                        }
                        UI::EndTable();
                    }
                }
            }
            UI::EndChild();
            UI::EndTabItem();
        }

        // CommentCount is usually innacurate
        if (UI::BeginTabItem("Comments")) {
            UI::BeginChild("MapMXCommentsChild");

            CheckMXCommentsRequest();

            if (m_MXCommentsRequest !is null && !m_MXCommentsRequest.Finished()) {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Loading...");
            } else if (m_commentsError) {
                UI::AlignTextToFramePadding();
                UI::Text("\\$f00" + Icons::Times + "\\$z Error while loading comments");
            } else {
                if (UI::GreenButton(Icons::Plus + " Post comment")) OpenBrowserURL("https://"+MXURL+"/commentupdate/"+m_map.MapId);

                UI::SameLine();

                if (UI::Button(Icons::Refresh)) {
                    m_comments.RemoveRange(0, m_comments.Length);
                    m_commentsStopRequest = false;
                    StartMXCommentsRequest();
                }

                if (m_comments.Length == 0) {
                    UI::AlignTextToFramePadding();
                    UI::Text("No comments found for this map. Be the first!");
                } else {
                    UI::DrawList@ dl = UI::GetWindowDrawList();

                    for (uint i = 0; i < m_comments.Length; i++) {
                        MX::MapComment@ comment = m_comments[i];

                        IfaceRender::MapComment(comment);

                        vec2 pos = UI::GetCursorScreenPos();

                        UI::Indent();

                        for (uint r = 0; r < comment.Replies.Length; r++) {
                            IfaceRender::MapComment(comment.Replies[r]);

                            vec4 rect = UI::GetItemRect();
                            float middle = rect.y + Draw::MeasureString(comment.Username).y;

                            dl.AddLine(vec2(pos.x, middle), vec2(pos.x + 15, middle), vec4(0.5, 0.5, 0.5, 1), 5.0f);

                            if (r == comment.Replies.Length - 1) {
                                dl.AddLine(pos, vec2(pos.x, middle), vec4(0.5, 0.5, 0.5, 1), 7.0f);
                            }
                        }

                        UI::Unindent();
                    }
                }
            }
            UI::EndChild();
            UI::EndTabItem();
        }
#if TMNEXT
        UI::BeginDisabled(!m_map.SupportsLeaderboard);

        if(UI::BeginTabItem("Online Leaderboard")){
            UI::BeginChild("MapLeaderboardChild");

            CheckTMIORequest();
            if (m_TMIOrequestStart) {
                m_TMIOrequestStart = false;
                if (!m_TMIONoRes && m_leaderboard.Length == 0) StartTMIORequest();
                else {
                    if (!m_TMIONoRes) {
                        StartTMIORequest(m_leaderboard.Length);
                    }
                }
            }

            if (m_TMIOerror){
                UI::AlignTextToFramePadding();
                UI::Text("\\$f00" + Icons::Times + "\\$z "+ m_TMIOerrorMsg);
            } else {
                UI::AlignTextToFramePadding();
                UI::Text(Icons::Heartbeat + " The leaderboard is fetched directly from Trackmania.io (Nadeo Services)");
                UI::SameLine();
                if (UI::Button(Icons::Refresh)){
                    m_leaderboard.RemoveRange(0, m_leaderboard.Length);
                    if (!m_TMIOrequestStarted) m_TMIOrequestStart = true;
                    m_TMIOstopleaderboard = false;
                }

                if (!m_TMIOstopleaderboard && m_leaderboard.Length == 0) {
                    if (m_TMIONoRes) {
                        UI::Text("No online records found for this map. Be the first!");
                    } else {
                        if (!m_TMIOrequestStarted) m_TMIOrequestStart = true;
                        int HourGlassValue = Time::Stamp % 3;
                        string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                        UI::Text(Hourglass + " Loading...");
                    }
                } else {
                    if (UI::BeginTable("LeaderboardList", 3, UI::TableFlags::RowBg)) {
                        UI::TableSetupScrollFreeze(0, 1);
                        PushTabStyle();
                        UI::TableSetupColumn("Position", UI::TableColumnFlags::WidthFixed, 40);
                        UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
                        UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthStretch);
                        UI::TableHeadersRow();
                        PopTabStyle();
                        UI::ListClipper clipper(m_leaderboard.Length);
                        while(clipper.Step()) {
                            for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                                UI::TableNextRow();
                                TMIO::Leaderboard@ entry = m_leaderboard[i];

                                UI::TableNextColumn();
                                UI::AlignTextToFramePadding();
                                UI::Text(tostring(entry.position));

                                UI::TableNextColumn();
                                bool isLocalUser = entry.playerID == GetApp().LocalPlayerInfo.WebServicesUserId;
                                UI::Text(entry.playerName + (isLocalUser ? " " + Icons::User : ""));

                                UI::TableNextColumn();
                                UI::Text(Time::Format(entry.time));
                                if (i != 0){
                                    UI::SameLine();
                                    UI::Text("\\$f00(+ " + Time::Format(entry.time - m_leaderboard[0].time) + ")");
                                }
                            }
                        }
                        UI::EndTable();
                        if (!m_TMIOrequestStarted && !m_TMIOstopleaderboard && UI::GreenButton("Load more")){
                            m_TMIOrequestStart = true;
                        }
                        if (m_TMIOrequestStarted && !m_TMIOstopleaderboard){
                            UI::Text(Icons::HourglassEnd + " Loading...");
                        }
                    }
                }
            }
            UI::EndChild();
            UI::EndTabItem();
        }
        UI::EndDisabled();
        if (!m_map.SupportsLeaderboard) UI::SetItemTooltip("\\$f00" + Icons::Times + " \\$zThis map doesn't support online records");
#endif

        if(m_map.EmbeddedObjectsCount > 0 && UI::BeginTabItem("Embedded objects (" + m_map.EmbeddedObjectsCount + ")")){
            UI::BeginChild("MapEmbeddedObjectsChild");

            CheckMXEmbeddedRequest();
            if (m_MXEmbedObjRequest !is null && m_mapEmbeddedObjects.Length == 0) {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Loading...");
            } else if (m_mapEmbeddedObjectsError) {
                UI::AlignTextToFramePadding();
                UI::Text("\\$f00" + Icons::Times + "\\$z Error while loading embedded objects");
            } else {
                UI::Text(m_mapEmbeddedObjects.Length + " objects found, with a total size of " + (m_map.EmbeddedItemsSize / 1024) + " KB");
                if (UI::BeginTable("EmbeddedObjectsList", 3, UI::TableFlags::RowBg)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    PushTabStyle();
                    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Author", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Action", UI::TableColumnFlags::WidthFixed);
                    UI::TableHeadersRow();
                    PopTabStyle();
                    UI::ListClipper clipper(m_mapEmbeddedObjects.Length);
                    while(clipper.Step()) {
                        for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                            UI::TableNextRow();
                            MX::MapEmbeddedObject@ object = m_mapEmbeddedObjects[i];
                            UI::PushID("EmbeddedObject" + i);

                            UI::TableNextColumn();
                            UI::AlignTextToFramePadding();
                            UI::Text(object.Name);

                            UI::TableNextColumn();
                            if (object.Username.Length == 0) UI::TextDisabled(object.ObjectAuthor);
                            else UI::Text(object.Username);
                            if (object.UserId > 0) {
                                UI::SetItemTooltip("Click to see "+(object.Username.Length > 0 ? (object.Username+"'s") : "user")+" profile");
                                if (UI::IsItemClicked()) mxMenu.AddTab(UserTab(object.UserId), true);
                            }

                            UI::TableNextColumn();
                            if (object.ID != 0){
                                if (object.ID == -1) {
                                    UI::BeginDisabled();
                                    UI::YellowButton(Icons::Times);
                                    UI::EndDisabled();
                                    UI::SetItemTooltip("Error while fetching this object on item.exchange");
                                } else if (object.ID == -2) {
                                    UI::BeginDisabled();
                                    UI::YellowButton(Icons::ExclamationTriangle);
                                    UI::EndDisabled();
                                    UI::SetItemTooltip("The list of embedded objects is too long for this map.");
                                } else {
#if DEPENDENCY_ITEMEXCHANGE
                                    if (UI::YellowButton(Icons::ItemExchange)) ItemExchange::ShowItemInfo(object.ID);
#else
                                    if (UI::YellowButton(Icons::ExternalLink)) OpenBrowserURL("https://item.exchange/item/view/"+object.ID);
#endif
                                }
                            } else {
                                UI::BeginDisabled();
                                UI::YellowButton(Icons::Times);
                                UI::EndDisabled();
                                UI::SetItemTooltip("This object is not published on item.exchange");
                            }
                            UI::PopID();
                        }
                    }
                    UI::EndTable();
                }
            }
            UI::EndChild();
            UI::EndTabItem();
        }

        UI::EndTabBar();

        UI::EndChild();
    }
}