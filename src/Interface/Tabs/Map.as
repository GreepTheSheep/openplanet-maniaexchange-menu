class MapTab : Tab
{
    Net::HttpRequest@ m_MXrequest;
    Net::HttpRequest@ m_MXEmbedObjRequest;
    Net::HttpRequest@ m_MXReplaysRequest;
    Net::HttpRequest@ m_MXCommentsRequest;
    MX::MapInfo@ m_map;
    array<MX::MapReplay@> m_replays;
    array<MX::MapComment@> m_comments;
    int m_mapId;
    string m_mapUid = "";
    bool m_error = false;
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
        startnew(CoroutineFunc(m_map.CheckIfUploaded));
#endif
    }

    bool CanClose() override { return m_map !is null || m_error; }

    string GetLabel() override {
        if (m_error) {
            return "\\$f00" + Icons::Times + "\\$z Error";
        }

        if (m_map is null) {
            return Icons::Map + " Loading...";
        }

        if (Setting_ColoredMapName) {
            return Icons::Map + " " + Text::OpenplanetFormatCodes(m_map.GbxMapName);
        }

        return Icons::Map + " " + m_map.Name;
    }

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

        string url = MXURL + "/api/maps" + urlParams;
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
            startnew(CoroutineFunc(m_map.CheckIfUploaded));
#endif
        }
    }

    void StartMXReplaysRequest()
    {
        string url = MXURL + "/api/replays?best=1&mapId=" + m_map.MapId;
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

    void StartMXEmbeddedRequest()
    {
        string url = MXURL + "/api/maps/objects?trackId=" + m_map.MapId + "&count=" + m_map.EmbeddedObjectsCount;
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
        string url = MXURL + "/api/maps/comments?trackId=" + m_map.MapId + "&count=50&fields=" + MX::commentFields;
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
            UI::Text(Icons::AnimatedHourglass + " Loading...");
            return;
        }

        float width = UI::GetWindowSize().x*0.3;
        vec2 posTop = UI::GetCursorPos();

        UI::BeginChild("Summary", vec2(width,0));

        UI::BeginTabBar("MapImages");

        foreach (MX::MapImage@ currImage : m_map.Images) {
            if (UI::BeginTabItem(tostring(currImage.Position))) {
                auto img = Images::CachedFromURL(MXURL + "/mapimage/" + m_map.MapId + "/" + currImage.Position + "?hq=true");

                if (img.m_texture !is null) {
                    vec2 thumbSize = img.m_texture.GetSize();
                    UI::Image(img.m_texture, vec2(
                        width,
                        thumbSize.y / (thumbSize.x / width)
                    ));

                    UI::MXThumbnailTooltip(img, 0.3);
                } else if (!img.m_error) {
                    UI::Text(Icons::AnimatedHourglass + " Loading");
                } else if (img.m_notFound) {
                    UI::Text("\\$fc0" + Icons::ExclamationTriangle + "\\$ Image not found");
                } else {
                    UI::Text(Icons::Times + "\\$z Error while loading image");
                }
                UI::EndTabItem();
            }
        }

        if (UI::BeginTabItem("Thumbnail")) {
            auto thumb = Images::CachedFromURL(MXURL + "/mapthumb/" + m_map.MapId);
            if (thumb.m_texture !is null) {
                vec2 thumbSize = thumb.m_texture.GetSize();
                UI::Image(thumb.m_texture, vec2(
                    width,
                    thumbSize.y / (thumbSize.x / width)
                ));

                UI::MXThumbnailTooltip(thumb, 0.3);
            } else if (!thumb.m_error) {
                UI::Text(Icons::AnimatedHourglass + " Loading");
            } else if (thumb.m_notFound) {
                UI::Text("\\$fc0" + Icons::ExclamationTriangle + "\\$z Thumbnail not found");
            } else {
                UI::Text(Icons::Times + "\\$z Error while loading thumbnail");
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
#else
            UI::Text(Icons::Tree + " \\$f77" + m_map.EnvironmentName);
            UI::SetItemTooltip("Vista");
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
        // if (UI::GoldButton(Icons::Trophy + " Award this map on "+shortMXName)) OpenBrowserURL(MXURL + "/mapshow/"+m_map.MapId+"#award");

        if (UI::CyanButton(Icons::ExternalLink + " View on "+pluginName)) OpenBrowserURL(MXURL + "/mapshow/"+m_map.MapId);
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
                } else if (UI::OrangeButton(Icons::Play + " Play Map Anyway")) {
                    UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(m_map.GbxMapName) + "\\$z\\$s by " + m_map.Username);
                    UI::ShowNotification(Icons::ExclamationTriangle + " Warning", "The map type is not supported for direct play, it can crash your game or returns you to the menu", UI::HSV(0.11, 1.0, 1.0), 15000);
                    startnew(CoroutineFunc(m_map.PlayMap));
                }
            } else {
                if (UI::GreenButton(Icons::Play + " Play Map")) {
                    UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(m_map.GbxMapName) + "\\$z\\$s by " + m_map.Username);
                    startnew(CoroutineFunc(m_map.PlayMap));
                }
#if TMNEXT && DEPENDENCY_NADEOSERVICES
                if (isMapTypeSupported && IsInServer()) {
                    CTrackMania@ app = cast<CTrackMania>(GetApp());

                    if (app.RootMap !is null) {
                        bool sameMapType = CleanMapType(app.RootMap.MapType) == m_map.MapType;

                        UI::BeginDisabled(!sameMapType || m_map.ServerSizeExceeded);
                        if (UI::GreenButton(Icons::Server + " Play Map on Nadeo-hosted Room")) {
                            Renderables::Add(PlayMapInRoom(m_map));
                        }
                        UI::EndDisabled();
                        if (!sameMapType) UI::SetItemTooltip(Icons::Times + " Map type doesn't match the current room's game mode");
                        else if (m_map.ServerSizeExceeded) UI::SetItemTooltip(Icons::Times + " Map size exceeds the server limit of 7MB");
                    }
                }
#endif
            }
#if TMNEXT
        } else {
            UI::Text("\\$f00" + Icons::Times + "\\$z You do not have permissions to play");
            UI::Text("Consider buying club access of the game.");
        }
#endif

#if TMNEXT
        if (Permissions::OpenAdvancedMapEditor()) {
#endif
            if (UI::YellowButton(Icons::Wrench + " Edit Map")) {
                UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(m_map.GbxMapName) + "\\$z\\$s by " + m_map.Username);
                startnew(CoroutineFunc(m_map.EditMap));
            }
#if TMNEXT
        } else {
            UI::Text("\\$f00" + Icons::Times + " \\$zYou do not have permissions to edit maps");
            UI::Text("Consider buying at least club access of the game.");
        }
#endif

        if (m_map.Downloaded) {
            UI::Text("\\$0f0" + Icons::CheckCircle + " \\$zMap downloaded");

            if (UI::RoseButton(Icons::FolderOpen + " Open Containing Folder")) {
                OpenExplorerPath(DownloadsFolder);
            }
        } else if (m_map.Downloading) {
            UI::Text(Icons::AnimatedHourglass + " Downloading map...");
        } else if (UI::PurpleButton(Icons::Download + " Download Map")) {
            UI::ShowNotification("Downloading map...", Text::OpenplanetFormatCodes(m_map.GbxMapName) + "\\$z\\$s by " + m_map.Username);
            startnew(CoroutineFunc(m_map.DownloadMap));
        }

        if (!m_map.InPlayLater) {
            if (UI::GreenButton(Icons::Check + " Add to Play later")) {
                g_PlayLaterMaps.InsertLast(m_map);
                SavePlayLater(g_PlayLaterMaps);
            }
        } else if (UI::RedButton(Icons::Times + " Remove from Play later")) {
            int mapIndex = g_PlayLaterMaps.Find(m_map);
            
            if (mapIndex > -1) {
                g_PlayLaterMaps.RemoveAt(mapIndex);
                SavePlayLater(g_PlayLaterMaps);
            }
        }

#if TMNEXT && DEPENDENCY_NADEOSERVICES
        if (m_map.InFavorites) {
            if (UI::RedButton(Icons::Heart + " Remove from Favorites")) {
                foreach (NadeoServices::MapInfo@ favoriteMap : MXNadeoServicesGlobal::g_favoriteMaps) {
                    if (favoriteMap.uid == m_map.MapUid) {
                        startnew(MXNadeoServicesGlobal::RemoveMapFromFavoritesAsync, favoriteMap);
                        break;
                    }
                }
            }
        } else {
            UI::BeginDisabled(!m_map.IsUploadedToServers);

            if (UI::GreenButton(Icons::Heart + " Add to Favorites")) {
                startnew(MXNadeoServicesGlobal::AddMapToFavoritesAsync, m_map);
            }

            UI::EndDisabled();

            if (!m_map.IsUploadedToServers) UI::SetItemTooltip(Icons::ExclamationTriangle + " This map is not on Nadeo Services, can't add it to your favorites");
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

        if (UI::BeginTabItem("Description")) {
            UI::BeginChild("MapDescriptionChild");
            UI::Markdown(m_map.AuthorComments);
            UI::EndChild();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem(shortMXName + " Leaderboard")) {
            UI::BeginChild("MapMXLeaderboardChild");

            if (UI::GreenButton(Icons::ExternalLink + " Submit")) OpenBrowserURL(MXURL + "/replayupload/"+m_map.MapId);

            if (m_map.ReplayCount == 0) {
                UI::Text("No records found for this map. Be the first!");
            } else {
                CheckMXReplaysRequest();

                if (m_MXReplaysRequest !is null && !m_MXReplaysRequest.Finished()) {
                    UI::Text(Icons::AnimatedHourglass + " Loading...");
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
                        while (clipper.Step()) {
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

                                if (i != 0) {
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

        // CommentCount is usually inaccurate
        if (UI::BeginTabItem("Comments")) {
            UI::BeginChild("MapMXCommentsChild");

            CheckMXCommentsRequest();

            if (m_MXCommentsRequest !is null && !m_MXCommentsRequest.Finished()) {
                UI::Text(Icons::AnimatedHourglass + " Loading...");
            } else if (m_commentsError) {
                UI::AlignTextToFramePadding();
                UI::Text("\\$f00" + Icons::Times + "\\$z Error while loading comments");
            } else {
                if (UI::GreenButton(Icons::Plus + " Post comment")) OpenBrowserURL(MXURL + "/commentupdate/"+m_map.MapId);

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

                    foreach (MX::MapComment@ comment : m_comments) {
                        IfaceRender::MapComment(comment);

                        vec2 pos = UI::GetCursorScreenPos();

                        UI::Indent();

                        for (uint r = 0; r < comment.Replies.Length; r++) {
                            IfaceRender::MapComment(comment.Replies[r]);

                            vec4 rect = UI::GetItemRect();
                            float middle = rect.y + UI::MeasureString(comment.Username).y;

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

        if (UI::BeginTabItem("Online Leaderboard")) {
            UI::BeginChild("MapLeaderboardChild");

            if (UI::Button(Icons::Refresh)) {
                m_map.Records.RemoveRange(0, m_map.Records.Length);
                m_map.FetchedRecords = false;
            }

            UI::SameLine();

            if (UI::CyanButton(Icons::ExternalLink)) {
                OpenBrowserURL("https://trackmania.io/#/leaderboard/" + m_map.MapUid);
            }

            UI::SetItemTooltip("View leaderboard on Trackmania.io");

            if (m_map.Records.IsEmpty()) {
                if (!m_map.FetchedRecords) {
                    startnew(CoroutineFunc(m_map.FetchRecords));
                } else if (m_map.LoadingRecords) {
                    UI::Text(Icons::AnimatedHourglass + " Loading...");
                } else {
                    UI::Text("No online records found for this map. Be the first!");
                }
            } else if (UI::BeginTable("LeaderboardList", 3, UI::TableFlags::RowBg)) {
                UI::TableSetupScrollFreeze(0, 1);
                PushTabStyle();

                UI::TableSetupColumn("Position", UI::TableColumnFlags::WidthFixed, 40);
                UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthStretch);
                UI::TableHeadersRow();

                PopTabStyle();

                UI::ListClipper clipper(m_map.Records.Length);

                while (clipper.Step()) {
                    for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                        UI::TableNextRow();
                        NadeoServices::LeaderboardRecord@ record = m_map.Records[i];

                        UI::TableNextColumn();
                        UI::AlignTextToFramePadding();
                        UI::Text(tostring(record.Position));

                        UI::TableNextColumn();
                        if (record.IsLocalPlayer) {
                            UI::Text(record.DisplayName + " " + Icons::User);
                        } else {
                            UI::Text(record.DisplayName);
                        }

                        UI::TableNextColumn();
                        UI::Text(Time::Format(record.Score));

                        if (i != 0) {
                            UI::SameLine();
                            UI::Text("\\$f00(+ " + Time::Format(record.Score - m_map.Records[0].Score) + ")");
                        }
                    }
                }

                UI::EndTable();

                if (m_map.HasMoreRecords && !m_map.LoadingRecords && UI::GreenButton("Load more")) {
                    startnew(CoroutineFunc(m_map.LoadMoreRecords));
                } else if (m_map.LoadingRecords) {
                    UI::Text(Icons::AnimatedHourglass + " Loading...");
                }
            }

            UI::EndChild();
            UI::EndTabItem();
        }

        UI::EndDisabled();

        if (!m_map.SupportsLeaderboard) UI::SetItemTooltip("\\$f00" + Icons::Times + " \\$zThis map doesn't support online records");
#endif

        if (m_map.EmbeddedObjectsCount > 0 && UI::BeginTabItem("Embedded objects (" + m_map.EmbeddedObjectsCount + ")")) {
            UI::BeginChild("MapEmbeddedObjectsChild");

            CheckMXEmbeddedRequest();
            if (m_MXEmbedObjRequest !is null && m_mapEmbeddedObjects.Length == 0) {
                UI::Text(Icons::AnimatedHourglass + " Loading...");
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
                    while (clipper.Step()) {
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
                                UI::SetItemTooltip("Click to see " + (object.Username.Length > 0 ? (object.Username+"'s") : "user") + " profile");
                                if (UI::IsItemClicked()) mxMenu.AddTab(UserTab(object.UserId), true);
                            }

                            UI::TableNextColumn();
                            if (object.ID != 0) {
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