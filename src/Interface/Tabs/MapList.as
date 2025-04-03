class MapListTab : Tab
{
    Net::HttpRequest@ m_request;
    array<MX::MapInfo@> maps;
    bool moreItems = false;
    bool m_useRandom = false;
    int lastId = 0;
    MapFilters@ filters;
    int m_sortingKey = 0;
    string m_sortingName = "None";
    uint64 m_typingStart;
    string m_selectedMode = "Track name";
    string m_sortSearchCombo;

    MapListTab() {
        @filters = MapFilters(this);
    }

    string GetLabel() override { return Icons::Map + " Maps"; }

    vec4 GetColor() override { return vec4(0.22f, 0.61f, 0.43f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        params.Set("fields", MX::mapFields);

        if (moreItems && lastId != 0) {
            params.Set("after", tostring(lastId));
        }

        if (m_sortingKey > 0) params.Set("order1", tostring(m_sortingKey));

        if (m_useRandom) {
            params.Set("random", "1");
            params.Set("count", "1");
            m_useRandom = false;
        } else {
            params.Set("count", "100");
        }

        filters.GetRequestParams(params);
    }

    void StartRequest()
    {
        dictionary params;
        GetRequestParams(params);
        string urlParams = MX::DictToApiParams(params);

        string url = "https://"+MXURL+"/api/maps" + urlParams;

        Logging::Debug("MapListTab::StartRequest: " + url);
        @m_request = API::Get(url);
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (!MX::APIDown && maps.Length == 0 && m_request is null && UI::IsWindowAppearing()) {
            StartRequest();
        }

        if (m_request !is null) {
            return;
        }

        if (m_typingStart == 0) {
            return;
        }

        if (Time::Now > m_typingStart + 1000) {
            m_typingStart = 0;
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
            int resCode = m_request.ResponseCode();
            auto json = m_request.Json();
            @m_request = null;

            Logging::Debug("MapListTab::CheckRequest: " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results") || json["Results"].Length == 0) {
                Logging::Error("Error while loading maps list");
                return;
            } else {
                HandleResponse(json);
            }
        }
    }

    void HandleResponse(const Json::Value &in json)
    {
        MX::MapInfo@ map;
        moreItems = json["More"];

        auto items = json["Results"];
        for (uint i = 0; i < items.Length; i++) {
            maps.InsertLast(MX::MapInfo(items[i]));

            if (moreItems && i == items.Length - 1) {
                lastId = items[i]["MapId"];
            }
        }
    }

    void RenderSearchBar()
    {
        UI::AlignTextToFramePadding();
        UI::Text("Search:");
        UI::SameLine();
        UI::SetNextItemWidth(120);
        if (UI::BeginCombo("##NamesFilter", m_selectedMode)) {
            if (UI::Selectable("Track name", m_selectedMode == "Track name")) {
                m_selectedMode = "Track name";
                if (filters.m_name == filters.m_author) filters.m_author = "";
                Reload();
            }

            if (UI::Selectable("Author name", m_selectedMode == "Author name")) {
                m_selectedMode = "Author name";
                if (filters.m_name == filters.m_author) filters.m_name = "";
                Reload();
            }
            UI::EndCombo();
        }

        UI::SameLine();

        bool changed = false;

        if (m_selectedMode == "Track name") {
            filters.m_name = UI::InputText("##NameSearch", filters.m_name, changed);
        } else {
            filters.m_author = UI::InputText("##AuthorSearch", filters.m_author, changed);
        }

        if (changed) {
            m_typingStart = Time::Now;
            Clear();
        }
    }

    void RenderHeader()
    {
        float itemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x;

        UI::AlignTextToFramePadding();

        UI::Text("Sort:");
        UI::SameLine();
        UI::SetNextItemWidth(225);
        if (UI::BeginCombo("##SortOrders", m_sortingName)) {
            UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
            m_sortSearchCombo = UI::InputText("##SortOrderSearch", m_sortSearchCombo);

            UI::Separator();

            for (uint i = 0; i < MX::m_mapSortingOrders.Length; i++) {
                MX::SortingOrder@ order = MX::m_mapSortingOrders[i];

                if (!order.Name.ToLower().Contains(m_sortSearchCombo.ToLower())) continue;

                if (UI::Selectable(order.Name, m_sortingName == order.Name)) {
                    m_sortingName = order.Name;
                    m_sortingKey = order.Key;
                    Reload();
                }
            }

            UI::EndCombo();
        } else {
            m_sortSearchCombo = "";
        }

        UI::SameLine();

        if (UI::GreenButton(Icons::Random + " Random result")){
            m_useRandom = true;
            Reload();
        }
        UI::SameLine();

        if (UI::OrangeButton(Icons::Filter + " Filters")) {
            Renderables::Add(filters);
        }

        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 40, UI::GetCursorPos().y));
        UI::BeginDisabled(m_request !is null);
        if (UI::Button(Icons::Refresh)) Reload();
        UI::EndDisabled();
    }

    void Clear()
    {
        maps.RemoveRange(0, maps.Length);
        lastId = 0;
        moreItems = false;
    }

    void Reload() override
    {
        Clear();
        StartRequest();
    }

    void Render() override
    {
        CheckRequest();

        RenderSearchBar();

        RenderHeader();

        if (m_request !is null && maps.Length == 0) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
        } else {
            if (MX::APIDown) {
                UI::Text("API is down, please try again later.");
                if (UI::Button("Retry")) {
                    Reload();
                }
                return;
            }
            if (maps.Length == 0) {
                UI::Text("No maps found.");
                return;
            }
            UI::BeginChild("mapList");
            if (UI::BeginTable("List", 5, UI::TableFlags::RowBg)) {
                UI::TableSetupScrollFreeze(0, 1);
                PushTabStyle();
                UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Style", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn(Icons::Trophy, UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);
                UI::TableHeadersRow();
                PopTabStyle();

                UI::ListClipper clipper(maps.Length);
                while(clipper.Step()) {
                    for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                    {
                        UI::PushID("ResMap"+i);
                        MX::MapInfo@ map = maps[i];
                        IfaceRender::MapResult(map);
                        UI::PopID();
                    }
                }
                if (m_request !is null && moreItems) {
                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::AlignTextToFramePadding();
                    UI::Text(Icons::HourglassEnd + " Loading...");
                }
                UI::EndTable();
                if (m_request is null && moreItems && UI::GreenButton("Load more")){
                    StartRequest();
                }
            }
            UI::EndChild();
        }
    }
}