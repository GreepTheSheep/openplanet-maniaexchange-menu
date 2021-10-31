class MapTab : Tab
{
    Net::HttpRequest@ m_request;
    MX::MapInfo@ m_map;
    int m_mapId;
    bool m_isLoading;

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

        int width = UI::GetWindowSize().x*0.35;
        vec2 posTop = UI::GetCursorPos();

        UI::BeginChild("Summary", vec2(width,0));

        auto img = Images::CachedFromURL("https://"+MXURL+"/maps/"+m_map.TrackID+"/image/1");

        if (img.m_texture !is null){
            vec2 thumbSize = img.m_texture.GetSize();
            UI::Image(img.m_texture, vec2(
                width,
                thumbSize.y / (thumbSize.x / width)
            ));
        }

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
        if(UI::Button(Icons::ExternalLink + " View on Trackmania.io")) OpenBrowserURL("https://trackmania.io/#/leaderboard/"+m_map.TrackUID);
#endif

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
            UI::Markdown(m_map.Comments);
            UI::EndChild();
            UI::EndTabItem();
        }
        if(UI::BeginTabItem("Leaderboard")){
            UI::BeginChild("MapLeaderboardChild");
            UI::Text("Leaderboard coming soon!");
            if(UI::Button(Icons::ExternalLink + " View on Trackmania.io")) OpenBrowserURL("https://trackmania.io/#/leaderboard/"+m_map.TrackUID);
            UI::EndChild();
            UI::EndTabItem();
        }

        UI::EndTabBar();

        UI::EndChild();
    }
}