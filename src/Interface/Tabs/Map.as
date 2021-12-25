class MapTab : Tab
{
    Net::HttpRequest@ m_MXrequest;
    Net::HttpRequest@ m_TMIOrequest;
    MX::MapInfo@ m_map;
    array<TMIO::Leaderboard@> m_leaderboard;
    int m_mapId;
    bool m_isLoading = false;
    bool m_mapDownloaded = false;
    bool m_isMapOnPlayLater = false;
    bool m_isRoyalMap = false;
    bool m_error = false;
    bool m_TMIOrequestStart = false;
    bool m_TMIOrequestStarted = false;
    bool m_TMIOnextPage = false;
    bool m_TMIOstopleaderboard = false;
    bool m_TMIOerror = false;
    string m_TMIOerrorMsg = "";
    bool m_TMIONoRes = false;

    Resources::Font@ g_fontHeader = Resources::GetFont("DroidSans-Bold.ttf", 24);

    MapTab(int trackId) {
        m_mapId = trackId;
        StartMXRequest(m_mapId);
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
            if (Setting_ColoredMapName) res += ColoredString(m_map.GbxMapName);
            else res += m_map.Name;
            return res;
        }
    }

    void StartMXRequest(int trackId)
    {
        string url = "https://"+MXURL+"/api/maps/get_map_info/multi/"+trackId;
        if (IsDevMode()) log("MapTab::StartRequest (MX): "+url);
        @m_MXrequest = API::Get(url);
    }

    void CheckMXRequest()
    {
        // If there's a request, check if it has finished
        if (m_MXrequest !is null && m_MXrequest.Finished()) {
            // Parse the response
            string res = m_MXrequest.String();
            if (IsDevMode()) log("MapTab::CheckRequest (MX): " + res);
            @m_MXrequest = null;
            auto json = Json::Parse(res);

            if (json.get_Length() == 0) {
                log("MapTab::CheckRequest (MX): Error parsing response");
                HandleMXResponseError();
                return;
            }
            // Handle the response
            HandleMXResponse(json[0]);
        }
    }

    void HandleMXResponse(const Json::Value &in json)
    {
        @m_map = MX::MapInfo(json);
    }

    void HandleMXResponseError()
    {
        m_error = true;
    }

    void StartTMIORequest(int offset = 0)
    {
        if (m_map is null) return;
        string url = "https://trackmania.io/api/leaderboard/map/"+m_map.TrackUID;
        if (offset != -1) url += "?length=100&offset=" + offset;
        if (IsDevMode()) log("MapTab::StartRequest (TM.IO): "+url);
        m_TMIOrequestStarted = true;
        @m_TMIOrequest = API::Get(url);
    }

    void CheckTMIORequest()
    {
        // If there's a request, check if it has finished
        if (m_TMIOrequest !is null && m_TMIOrequest.Finished()) {
            // Parse the response
            string res = m_TMIOrequest.String();
            if (IsDevMode()) log("MapTab::CheckRequest (TM.IO): " + res);
            @m_TMIOrequest = null;
            auto json = Json::Parse(res);

            // if error, handle it (particular case for "not found on API")
            if (json.HasKey("error")){
                HandleTMIOResponseError(json["error"]);
            } else {
                // if tops is null return no results, else handle the response
                if (json["tops"].GetType() == Json::Type::Null) {
                    if (IsDevMode()) log("MapTab::CheckRequest (TM.IO): No results");
                    m_TMIONoRes = true;
                }
                else HandleTMIOResponse(json["tops"]);
            }
            m_TMIOrequestStarted = false;
        }
    }

    void HandleTMIOResponse(const Json::Value &in json)
    {
        if (!m_TMIOnextPage && json.get_Length() < 15) m_TMIOstopleaderboard = true;
        if (m_TMIOnextPage && json.get_Length() < 50) m_TMIOstopleaderboard = true;

        for (uint i = 0; i < json.get_Length(); i++) {
            auto leaderboard = TMIO::Leaderboard(json[i]);
            m_leaderboard.InsertLast(leaderboard);
        }
    }

    void HandleTMIOResponseError(string error)
    {
        m_TMIOerror = true;
        if (error.Contains("does not exist")) {
            m_TMIOerrorMsg = "This map is not available on Nadeo Services";
        } else {
            m_TMIOerrorMsg = error;
        }
    }

    string FormatTime(int time) {
        int hundreths = time % 1000;
        time /= 1000;
        int hours = time / 3600;
        int minutes = (time / 60) % 60;
        int seconds = time % 60;

        return (hours != 0 ? Text::Format("%02d", hours) + ":" : "" ) + (minutes != 0 ? Text::Format("%02d", minutes) + ":" : "") + Text::Format("%02d", seconds) + "." + Text::Format("%03d", hundreths);
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
        for (uint i = 0; i < g_PlayLaterMaps.get_Length(); i++) {
            MX::MapInfo@ playLaterMap = g_PlayLaterMaps[i];
            if (playLaterMap.TrackID != m_map.TrackID) {
                m_isMapOnPlayLater = false;
            } else {
                m_isMapOnPlayLater = true;
                break;
            }
        }

        float width = UI::GetWindowSize().x*0.35;
        vec2 posTop = UI::GetCursorPos();

        UI::BeginChild("Summary", vec2(width,0));

        UI::BeginTabBar("MapImages");

        if (m_map.ImageCount != 0) {
            for (uint i = 1; i < m_map.ImageCount+1; i++) {
                if(UI::BeginTabItem(tostring(i))){
                    auto img = Images::CachedFromURL("https://"+MXURL+"/maps/"+m_map.TrackID+"/image/"+i);

                    if (img.m_texture !is null){
                        vec2 thumbSize = img.m_texture.GetSize();
                        UI::Image(img.m_texture, vec2(
                            width,
                            thumbSize.y / (thumbSize.x / width)
                        ));
                        if (UI::IsItemHovered()) {
                            UI::BeginTooltip();
                            UI::Image(img.m_texture, vec2(
                                width*3,
                                thumbSize.y / (thumbSize.x / (width*3))
                            ));
                            UI::EndTooltip();
                        }
                    } else {
                        int HourGlassValue = Time::Stamp % 3;
                        string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                        UI::Text(Hourglass + " Loading");
                    }
                    UI::EndTabItem();
                }
            }
        }

        if(UI::BeginTabItem("Thumbnail")){
            auto thumb = Images::CachedFromURL("https://"+MXURL+"/maps/thumbnail/"+m_map.TrackID);
            if (thumb.m_texture !is null){
                vec2 thumbSize = thumb.m_texture.GetSize();
                UI::Image(thumb.m_texture, vec2(
                    width,
                    thumbSize.y / (thumbSize.x / width)
                ));
                if (UI::IsItemHovered()) {
                    UI::BeginTooltip();
                    UI::Image(thumb.m_texture, vec2(
                        width*2,
                        thumbSize.y / (thumbSize.x / (width*2))
                    ));
                    UI::EndTooltip();
                }
            } else {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Loading");
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
        UI::Text(Icons::Hourglass + " \\$f77" + m_map.LengthName);
        if (m_map.Laps != 1) UI::Text(Icons::Refresh+ " \\$f77" + m_map.Laps);
        UI::Text(Icons::LevelUp+ " \\$f77" + m_map.DifficultyName);
        UI::Text(Icons::Calendar + " \\$f77" + m_map.UploadedAt);
        if (m_map.UploadedAt != m_map.UpdatedAt) UI::Text(Icons::Refresh + " \\$f77" + m_map.UpdatedAt);
#if MP4
        UI::Text(Icons::Inbox + " \\$f77" + m_map.TitlePack);
#endif
        UI::Text(Icons::Sun + " \\$f77" + m_map.Mood);
        UI::Text(Icons::Money + " \\$f77" + m_map.DisplayCost);
        if (UI::CyanButton(Icons::ExternalLink + " View on "+pluginName)) OpenBrowserURL("https://"+MXURL+"/maps/"+m_map.TrackID);
#if TMNEXT
        if (UI::Button(Icons::ExternalLink + " View on Trackmania.io")) OpenBrowserURL("https://trackmania.io/#/leaderboard/"+m_map.TrackUID);
#endif

#if TMNEXT
        if (Permissions::PlayLocalMap()) {
            for (uint i = 0; i < m_map.Tags.get_Length(); i++) {
                MX::MapTag@ tag = m_map.Tags[i];
                if (tag.ID == 37) { // Royal map
                    m_isRoyalMap = true;
                    break;
                }
            }

            if (m_isRoyalMap) {
                UI::Text("\\$f70" + Icons::ExclamationTriangle + " \\$zRoyal maps can not be played in solo");
                if (Setting_ShowPlayOnRoyalMap && UI::OrangeButton(Icons::Play + " Play Map Anyway")) {
                    if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                    UI::ShowNotification("Loading map...", ColoredString(m_map.GbxMapName) + "\\$z\\$s by " + m_map.Username);
                    MX::mapToLoad = m_map.TrackID;
                }
            } else {
#endif
                if (UI::GreenButton(Icons::Play + " Play Map")) {
                    if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                    UI::ShowNotification("Loading map...", ColoredString(m_map.GbxMapName) + "\\$z\\$s by " + m_map.Username);
                    MX::mapToLoad = m_map.TrackID;
                }
                if (UserMapsFolder() != "<Invalid>") {
                    if (MX::mapDownloadInProgress){
                        UI::Text("\\$f70" + Icons::Download + " \\$zDownloading map...");
                        m_isLoading = true;
                    } else {
                        m_isLoading = false;
                        if (!m_mapDownloaded) {
                            if (UI::PurpleButton(Icons::Download + " Download Map")) {
                                UI::ShowNotification("Downloading map...", ColoredString(m_map.GbxMapName) + "\\$z\\$s by " + m_map.Username);
                                MX::mapToDL = m_map.TrackID;
                                m_mapDownloaded = true;
                            }
                        } else {
                            UI::Text("\\$0f0" + Icons::Download + " \\$zMap downloaded");
                            UI::TextDisabled("to " + UserMapsFolder() + "Downloaded\\"+pluginName+"\\" + m_map.TrackID + ".Map.Gbx");
                        }
                    }
                } else {
                    UI::Text('\\$f70' + Icons::ExclamationTriangle + " \\$zUser maps folder is invalid, impossible to save map");
                }
#if TMNEXT
            }
        } else {
            UI::Text("\\$f00"+Icons::Times + " \\$zYou do not have permissions to play");
            UI::Text("Consider buying at least standard access of the game.");
        }
#endif

        if (!m_isMapOnPlayLater){
#if TMNEXT
            if (Permissions::PlayLocalMap() && !m_isRoyalMap && UI::GreenButton(Icons::Check + " Add to Play later")) {
#else
            if (UI::GreenButton(Icons::Check + " Add to Play later")) {
#endif
                g_PlayLaterMaps.InsertAt(0, m_map);
                m_isMapOnPlayLater = true;
                SavePlayLater(g_PlayLaterMaps);
            }
        } else {
#if TMNEXT
            if (Permissions::PlayLocalMap() && UI::RedButton(Icons::Check + " Remove from Play later")) {
#else
            if (UI::RedButton(Icons::Times + " Remove from Play later")) {
#endif
            
                for (uint i = 0; i < g_PlayLaterMaps.get_Length(); i++) {
                    MX::MapInfo@ playLaterMap = g_PlayLaterMaps[i];
                    if (playLaterMap.TrackID == m_map.TrackID) {
                        g_PlayLaterMaps.RemoveAt(i);
                        m_isMapOnPlayLater = false;
                        SavePlayLater(g_PlayLaterMaps);
                    }
                }
            }
        }

        UI::EndChild();

        UI::SetCursorPos(posTop + vec2(width + 8, 0));
        UI::BeginChild("Description");

        UI::PushFont(g_fontHeader);
        UI::Text(ColoredString(m_map.GbxMapName));
        UI::PopFont();

        UI::TextDisabled("By " + m_map.Username);

        UI::Separator();

        UI::BeginTabBar("MapTabs");

        if(UI::BeginTabItem("Description")){
            UI::BeginChild("MapDescriptionChild");
            IfaceRender::MXComment(m_map.Comments);
            UI::EndChild();
            UI::EndTabItem();
        }
#if TMNEXT
        if(UI::BeginTabItem("Leaderboard")){
            UI::BeginChild("MapLeaderboardChild");

            CheckTMIORequest();
            if (m_TMIOrequestStart) {
                m_TMIOrequestStart = false;
                if (!m_TMIONoRes && m_leaderboard.get_Length() == 0) StartTMIORequest();
                else {
                    if (!m_TMIONoRes) {
                        StartTMIORequest(m_leaderboard.get_Length());
                    }
                }
            }

            if (m_TMIOerror){
                UI::Text("\\$f00" + Icons::Times + "\\$z "+ m_TMIOerrorMsg);
            } else {
                UI::Text(Icons::Heartbeat + " The leaderboard is fetched directly from Trackmania.io (Nadeo Services)");
                UI::SameLine();
                if (UI::OrangeButton(Icons::Refresh)){
                    m_leaderboard.RemoveRange(0, m_leaderboard.get_Length());
                    if (!m_TMIOrequestStarted) m_TMIOrequestStart = true;
                    m_TMIOstopleaderboard = false;
                }

                if (!m_TMIOstopleaderboard && m_leaderboard.get_Length() == 0) {
                    if (m_TMIONoRes) {
                        UI::Text("No records found for this map. Be the first!");
                    } else {
                        if (!m_TMIOrequestStarted) m_TMIOrequestStart = true;
                        int HourGlassValue = Time::Stamp % 3;
                        string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                        UI::Text(Hourglass + " Loading...");
                    }
                } else {
                    if (UI::BeginTable("LeaderboardList", 3)) {
                        UI::TableSetupScrollFreeze(0, 1);
                        PushTabStyle();
                        UI::TableSetupColumn("Position", UI::TableColumnFlags::WidthFixed, 40);
                        UI::TableSetupColumn("Player", UI::TableColumnFlags::WidthStretch);
                        UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthStretch);
                        UI::TableHeadersRow();
                        PopTabStyle();
                        for (uint i = 0; i < m_leaderboard.get_Length(); i++) {
                            UI::TableNextRow();
                            TMIO::Leaderboard@ entry = m_leaderboard[i];

                            UI::TableSetColumnIndex(0);
                            UI::Text(tostring(entry.position));

                            UI::TableSetColumnIndex(1);
                            UI::Text(entry.playerName);

                            UI::TableSetColumnIndex(2);
                            UI::Text(FormatTime(entry.time));
                            if (i != 0){
                                UI::SameLine();
                                UI::Text("\\$f00(+ " + FormatTime(entry.time - m_leaderboard[0].time) + ")");
                            }
                        }
                        if (!m_TMIOstopleaderboard && UI::GetScrollY() >= UI::GetScrollMaxY()){
                            // new request
                            UI::TableNextRow();
                            UI::TableSetColumnIndex(1);
                            UI::Text(Icons::HourglassEnd + " Loading...");
                            if (!m_TMIOrequestStarted) m_TMIOrequestStart = true;
                            m_TMIOnextPage = true;
                        }
                        UI::EndTable();
                    }
                    
                }
            }
            UI::EndChild();
            UI::EndTabItem();
        }
#endif

        UI::EndTabBar();

        UI::EndChild();
    }
}