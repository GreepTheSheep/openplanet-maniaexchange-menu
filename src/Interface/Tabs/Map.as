class MapTab : Tab
{
    Net::HttpRequest@ m_request;
    MX::MapInfo@ m_map;
    int m_mapId;
    bool m_isLoading = false;
    bool m_isMapOnPlayLater = false;
    bool m_isRoyalMap = false;

    Resources::Font@ g_fontHeader = Resources::GetFont("DroidSans-Bold.ttf", 24);

    MapTab(int trackId) {
        m_mapId = trackId;
        StartRequest(m_mapId);
    }

    bool CanClose() override { return !m_isLoading; }

    string GetLabel() override {
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

    void StartRequest(int trackId)
    {
        string url = "https://"+MXURL+"/api/maps/get_map_info/multi/"+trackId;
        if (IsDevMode()) log("MapTab::StartRequest: "+url);
        @m_request = API::Get(url);
    }

    void CheckRequest()
    {
        // If there's a request, check if it has finished
        if (m_request !is null && m_request.Finished()) {
            // Parse the response
            string res = m_request.String();
            if (IsDevMode()) log("MapTab::CheckRequest: " + res);
            @m_request = null;
            auto json = Json::Parse(res);

            if (json.get_Length() == 0) {
                log("MapTab::CheckRequest: Error parsing response");
                return;
            }
            // Handle the response
            HandleResponse(json[0]);
        }
    }

    void HandleResponse(const Json::Value &in json)
    {
        @m_map = MX::MapInfo(json);
    }

    void Render() override
    {
        CheckRequest();

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

        auto img = Images::CachedFromURL("https://"+MXURL+"/maps/"+m_map.TrackID+"/image/1");

        if (img.m_texture !is null){
            vec2 thumbSize = img.m_texture.GetSize();
            UI::Image(img.m_texture, vec2(
                width,
                thumbSize.y / (thumbSize.x / width)
            ));
        } else {
            auto thumb = Images::CachedFromURL("https://"+MXURL+"/maps/thumbnail/"+m_map.TrackID);
            if (thumb.m_texture !is null){
                vec2 thumbSize = thumb.m_texture.GetSize();
                UI::Image(thumb.m_texture, vec2(
                    width,
                    thumbSize.y / (thumbSize.x / width)
                ));
            }
        }

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
            } else {
#endif
                if (UI::GreenButton(Icons::Play + " Play Map")) {
                    if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                    UI::ShowNotification("Loading map...", ColoredString(m_map.GbxMapName) + "\\$z\\$s by " + m_map.Username);
                    MX::mapToLoad = m_map.TrackID;
                }
#if TMNEXT
            }
        } else {
            UI::Text("\\$f00"+Icons::Times + " \\$z\\$sYou do not have permissions to play");
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
        if(UI::BeginTabItem("Leaderboard")){
            UI::BeginChild("MapLeaderboardChild");
            UI::Text("Leaderboard coming soon!");
#if TMNEXT
            if (UI::Button(Icons::ExternalLink + " View on Trackmania.io")) OpenBrowserURL("https://trackmania.io/#/leaderboard/"+m_map.TrackUID);
#endif
            UI::EndChild();
            UI::EndTabItem();
        }

        UI::EndTabBar();

        UI::EndChild();
    }
}