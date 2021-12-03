class MapPackListTab : Tab
{
    Net::HttpRequest@ m_request;
    array<MX::MapPackInfo@> mapPacks;
    uint totalItems = 0;
    bool m_useRandom = false;
    int m_page = 1;

    void GetRequestParams(dictionary@ params)
    {
        params.Set("api", "on");
        params.Set("format", "json");
        params.Set("limit", "100");
        params.Set("page", tostring(m_page));
        if (m_useRandom) {
            params.Set("random", "1");
            m_useRandom = false;
        }
    }

    void StartRequest()
    {
        dictionary params;
        GetRequestParams(params);

        string urlParams = "";
        if (!params.IsEmpty()) {
            auto keys = params.GetKeys();
            for (uint i = 0; i < keys.Length; i++) {
                string key = keys[i];
                string value;
                params.Get(key, value);

                urlParams += (i == 0 ? "?" : "&");
                urlParams += key + "=" + Net::UrlEncode(value);
            }
        }

        string url = "https://"+MXURL+"/mappacksearch/search"+urlParams;

        if (IsDevMode()) log("MapPackListTab::StartRequest: " + url);
        @m_request = API::Get(url);
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (mapPacks.get_Length() == 0 && m_request is null && UI::IsWindowAppearing()) {
            StartRequest();
        }
    }

    void CheckRequest()
    {
        CheckStartRequest();

        // If there's a request, check if it has finished
        if (m_request !is null && m_request.Finished()) {
            // Parse the response
            string res = m_request.String();
            if (IsDevMode()) log("MapPackListTab::CheckRequest: " + res);
            @m_request = null;
            auto json = Json::Parse(res);

            // Handle the response
            if (json.HasKey("error")) {
                //HandleErrorResponse(json["error"]);
            } else {
                HandleResponse(json);
            }
        }
    }

    void HandleResponse(const Json::Value &in json)
    {
        MX::MapPackInfo@ mapPack;
        totalItems = json["totalItemCount"];

        auto items = json["results"];
        for (uint i = 0; i < items.Length; i++) {
            mapPacks.InsertLast(MX::MapPackInfo(items[i]));
        }
    }

    void RenderHeader(){}

    void Clear()
    {
        mapPacks.RemoveRange(0, mapPacks.get_Length());
        totalItems = 0;
    }

    void Reload()
    {
        Clear();
        StartRequest();
    }

    void Render() override
    {
        CheckRequest();

        RenderHeader();

        if (m_request !is null && mapPacks.Length == 0) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
        } else {
            if (mapPacks.get_Length() == 0) {
                UI::Text("No map packs found.");
                return;
            }
            UI::BeginChild("mapList");
            if (UI::BeginTable("List", 4)) {
                UI::TableSetupScrollFreeze(0, 1);
                PushTabStyle();
                UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Tags", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 40);
                UI::TableHeadersRow();
                PopTabStyle();
                for(uint i = 0; i < mapPacks.get_Length(); i++)
                {
                    UI::PushID("ResMap"+i);
                    MX::MapPackInfo@ mapPack = mapPacks[i];
                    IfaceRender::MapPackResult(mapPack);
                    UI::PopID();
                }
                if (m_request !is null && totalItems > mapPacks.get_Length()) {
                    UI::TableNextRow();
                    UI::TableSetColumnIndex(0);
                    UI::Text(Icons::HourglassEnd + " Loading...");
                }
                UI::EndTable();
                if (m_request is null && totalItems > mapPacks.Length && UI::GreenButton("Load more")){
                    m_page++;
                    StartRequest();
                }
            }
            UI::EndChild();
        }
    }
}