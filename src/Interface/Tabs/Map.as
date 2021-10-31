class MapTab : Tab
{
    Net::HttpRequest@ m_request;
    MX::MapInfo@ m_map;
    int m_mapId;
    bool m_isLoading;

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

        UI::Text(Icons::Map + " " + m_map.Name);
    }
}