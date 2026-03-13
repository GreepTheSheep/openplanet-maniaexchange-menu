class MapListTab : Tab
{
    Net::HttpRequest@ m_request;
    array<MX::MapInfo@> maps;
    bool moreItems;
    bool m_loadingRandom;
    int lastId = 0;
    MapFilters@ filters;
    int m_sortingKey = 0;
    string m_sortingName = "None";
    uint64 m_typingStart;
    string m_selectedMode = "Track name";
    string m_sortSearchCombo;
    MapColumns@ columnWidths = MapColumns();

    MapListTab() {
        @filters = MapFilters(this);
    }

    bool IsVisible() override {return Setting_Tab_Maps_Visible;}

    string GetLabel() override { return Icons::Map + " Maps"; }

    vec4 GetColor() override { return vec4(0.22f, 0.61f, 0.43f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        params.Set("fields", MX::mapFields);

        if (m_sortingKey > 0) params.Set("order1", tostring(m_sortingKey));

        filters.GetRequestParams(params);
    }

    void StartRequest()
    {
        dictionary params;
        params.Set("count", "100");

        if (moreItems && lastId != 0) {
            params.Set("after", tostring(lastId));
        }

        GetRequestParams(params);

        string urlParams = MX::DictToApiParams(params);

        string url = MXURL + "/api/maps" + urlParams;

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

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
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

        columnWidths.Update(maps);
    }

    void GetRandomMap()
    {
        dictionary params = {
            { "random", "1" },
            { "count", "1" }
        };
        GetRequestParams(params);

        m_loadingRandom = true;
        array<MX::MapInfo@> results = MX::GetMaps(params);

        if (results.IsEmpty()) {
            Logging::Warn("MapListTab::GetRandomMap: Failed to get a random map", true);
        } else {
            mxMenu.AddTab(MapTab(results[0]), true);
        }

        m_loadingRandom = false;
    }

    void RenderSearchBar()
    {
        UI::AlignTextToFramePadding();
        UI::Text("Search:");
        UI::SameLine();
        UI::SetNextItemWidth(120);

        UI::BeginDisabled(m_request !is null);

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

        UI::EndDisabled();

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

    void RenderSortingOrders()
    {
        float itemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x;

        UI::AlignTextToFramePadding();

        UI::Text("Sort:");
        UI::SameLine();
        UI::SetNextItemWidth(225);

        UI::BeginDisabled(m_request !is null);

        if (UI::BeginCombo("##MapSortOrders", m_sortingName)) {
            UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
            m_sortSearchCombo = UI::InputText("##MapSortOrderSearch", m_sortSearchCombo);

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

        UI::EndDisabled();
    }

    void RenderHeader()
    {
        RenderSortingOrders();

        UI::SameLine();

        UI::BeginDisabled(m_request !is null);

        UI::BeginDisabled(m_loadingRandom);

        if (UI::GreenButton(Icons::Random + " Random result")) {
            startnew(CoroutineFunc(GetRandomMap));
        }

        UI::EndDisabled();

        UI::SameLine();

        if (UI::OrangeButton(Icons::Filter + " Filters")) {
            Renderables::Add(filters);
        }

        UI::SameLine();

        float buttonWidth = UI::MeasureButton(Icons::Refresh).x;
        UI::RightAlignButton(buttonWidth);

        if (UI::Button(Icons::Refresh)) Reload();

        UI::EndDisabled();
    }

    void Clear()
    {
        maps.RemoveRange(0, maps.Length);
        lastId = 0;
        moreItems = false;
        columnWidths.Reset();
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
            UI::Text(Icons::AnimatedHourglass + " Loading...");
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

            float scale = UI::GetScale();

            if (UI::BeginTable("List", 13, UI::TableFlags::RowBg | UI::TableFlags::Hideable)) {
                UI::TableSetupScrollFreeze(0, 1);
                PushTabStyle();
                UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Author", UI::TableColumnFlags::WidthFixed, columnWidths.author);
#if TMNEXT
                UI::TableSetupColumn("Vista", UI::TableColumnFlags::WidthFixed, Setting_VistaIcons ? 30 * scale : columnWidths.environment);
#else
                UI::TableSetupColumn("Env.", UI::TableColumnFlags::WidthFixed, columnWidths.environment);
#endif
                UI::TableSetupColumn("Vehicle", UI::TableColumnFlags::WidthFixed, columnWidths.vehicle);
                UI::TableSetupColumn("Type", UI::TableColumnFlags::WidthFixed, 60 * scale);
                UI::TableSetupColumn("Title pack", UI::TableColumnFlags::WidthFixed, columnWidths.titlepack);
                UI::TableSetupColumn("Tags", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Length", UI::TableColumnFlags::WidthFixed, columnWidths.length);
                UI::TableSetupColumn("Difficulty", UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("Awards", UI::TableColumnFlags::WidthFixed, 50 * scale);
#if TMNEXT
                UI::TableSetupColumn("Records", UI::TableColumnFlags::WidthFixed, 40 * scale);
#else
                UI::TableSetupColumn("Replays", UI::TableColumnFlags::WidthFixed, 40 * scale);
#endif
                UI::TableSetupColumn("", UI::TableColumnFlags::WidthFixed, 15 * scale);
                UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);
                UI::TableHeadersRow();
                PopTabStyle();

                UI::TableSetColumnEnabled(0, Setting_MapName);
                UI::TableSetColumnEnabled(1, Setting_MapAuthor);
                UI::TableSetColumnEnabled(2, Setting_MapEnvironment && repo == MP4mxRepos::Trackmania);
                UI::TableSetColumnEnabled(3, Setting_MapVehicle && repo == MP4mxRepos::Trackmania);
                UI::TableSetColumnEnabled(4, Setting_MapType);
                UI::TableSetColumnEnabled(5, Setting_MapTitlepack);
                UI::TableSetColumnEnabled(6, Setting_MapTags);
                UI::TableSetColumnEnabled(7, Setting_MapLength && repo == MP4mxRepos::Trackmania);
                UI::TableSetColumnEnabled(8, Setting_MapDifficulty);
                UI::TableSetColumnEnabled(9, Setting_MapAwards);
                UI::TableSetColumnEnabled(10, Setting_MapRecordCount && repo == MP4mxRepos::Trackmania);
                UI::TableSetColumnEnabled(11, Setting_MapAtStatus && repo == MP4mxRepos::Trackmania);

                UI::ListClipper clipper(maps.Length);
                while (clipper.Step()) {
                    for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
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
                if (m_request is null && moreItems && UI::GreenButton("Load more")) {
                    StartRequest();
                }
            }
            UI::EndChild();
        }
    }
}