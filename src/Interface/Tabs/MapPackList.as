class MapPackListTab : Tab
{
    Net::HttpRequest@ m_request;
    Net::HttpRequest@ m_randomRequest;
    array<MX::MapPackInfo@> mapPacks;
    bool moreItems = false;
    int lastId = 0;

    MappackFilters@ filters;
    uint64 u_typingStart;
    string t_selectedMode = "Mappack name";
    int t_sortingKey = 0;
    string t_sortingName = "None";
    string t_sortSearchCombo;

    MapPackListTab() {
        @filters = MappackFilters(this);
    }

    bool IsVisible() override {return Setting_Tab_MapPacks_Visible;}
    string GetLabel() override {return Icons::Inbox + " Map Packs";}
    vec4 GetColor() override { return vec4(0.92f, 0.56f, 0.38f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        params.Set("fields", MX::mapPackFields);

        if (t_sortingKey > 0) params.Set("order1", tostring(t_sortingKey));

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

        string url = "https://"+MXURL+"/api/mappacks" + urlParams;

        Logging::Debug("MapPackListTab::StartRequest: " + url);
        @m_request = API::Get(url);
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (!MX::APIDown && mapPacks.Length == 0 && m_request is null && UI::IsWindowAppearing()) {
            StartRequest();
        }

        if (m_request !is null) {
            return;
        }

        if (u_typingStart == 0) {
            return;
        }

        if (Time::Now > u_typingStart + 1000) {
            u_typingStart = 0;
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

            Logging::Debug("MapPackListTab::CheckRequest: " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
                Logging::Error("MapPackListTab::CheckRequest: Error while loading mappack list");
                return;
            } else {
                HandleResponse(json);
            }
        }
    }

    void HandleResponse(const Json::Value &in json)
    {
        moreItems = json["More"];

        auto items = json["Results"];
        for (uint i = 0; i < items.Length; i++) {
            mapPacks.InsertLast(MX::MapPackInfo(items[i]));

            if (moreItems && i == items.Length - 1) {
                lastId = items[i]["MappackId"];
            }
        }
    }

    void StartRandomRequest()
    {
        dictionary params;
        params.Set("random", "1");
        params.Set("count", "1");
        GetRequestParams(params);

        string urlParams = MX::DictToApiParams(params);

        string url = "https://"+MXURL+"/api/mappacks" + urlParams;
        Logging::Debug("MapPackListTab::StartRandomRequest: " + url);
        @m_randomRequest = API::Get(url);
    }

    void CheckRandomRequest()
    {
        if (m_randomRequest !is null && m_randomRequest.Finished()) {
            string res = m_randomRequest.String();
            int resCode = m_randomRequest.ResponseCode();
            auto json = m_randomRequest.Json();
            @m_randomRequest = null;

            Logging::Debug("MapPackListTab::CheckRandomRequest: " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
                Logging::Error("MapPackListTab::CheckRandomRequest: Error while getting random mappack");
                return;
            } else if (json["Results"].Length == 0) {
                Logging::Warn("MapPackListTab::CheckRandomRequest: Failed to get a random mappack", true);
                return;
            }

            MX::MapPackInfo@ mappack = MX::MapPackInfo(json["Results"][0]);

            mxMenu.AddTab(MapPackTab(mappack), true);
        }
    }

    void RenderSearchBar()
    {
        UI::AlignTextToFramePadding();
        UI::Text("Search:");
        UI::SameLine();
        UI::SetNextItemWidth(140);

        UI::BeginDisabled(m_request !is null);

        if (UI::BeginCombo("##NamesFilter", t_selectedMode)) {
            if (UI::Selectable("Mappack name", t_selectedMode == "Mappack name")) {
                t_selectedMode = "Mappack name";
                if (filters.t_name == filters.t_manager) filters.t_manager = "";
                Reload();
            }

            if (UI::Selectable("Manager name", t_selectedMode == "Manager name")) {
                t_selectedMode = "Manager name";
                if (filters.t_name == filters.t_manager) filters.t_name = "";
                Reload();
            }
            UI::EndCombo();
        }

        UI::EndDisabled();

        UI::SameLine();

        bool changed = false;

        if (t_selectedMode == "Mappack name") {
            filters.t_name = UI::InputText("##NameSearch", filters.t_name, changed);
        } else {
            filters.t_manager = UI::InputText("##ManagerSearch", filters.t_manager, changed);
        }

        if (changed) {
            u_typingStart = Time::Now;
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

        UI::BeginDisabled(m_request !is null);

        if (UI::BeginCombo("##MappackSortOrders", t_sortingName)) {
            UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
            t_sortSearchCombo = UI::InputText("###MappackSortOrderSearch", t_sortSearchCombo);

            UI::Separator();

            for (uint i = 0; i < MX::m_mappackSortingOrders.Length; i++) {
                MX::SortingOrder@ order = MX::m_mappackSortingOrders[i];

                if (!order.Name.ToLower().Contains(t_sortSearchCombo.ToLower())) continue;

                if (UI::Selectable(order.Name, t_sortingName == order.Name)) {
                    t_sortingName = order.Name;
                    t_sortingKey = order.Key;
                    Reload();
                }
            }

            UI::EndCombo();
        } else {
            t_sortSearchCombo = "";
        }

        UI::SameLine();

        UI::BeginDisabled(m_randomRequest !is null);

        if (UI::GreenButton(Icons::Random + " Random result")){
            StartRandomRequest();
        }

        UI::EndDisabled();

        UI::SameLine();

        if (UI::OrangeButton(Icons::Filter + " Filters")) {
            Renderables::Add(filters);
        }

        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 40, UI::GetCursorPos().y));

        if (UI::Button(Icons::Refresh)) Reload();

        UI::EndDisabled();
    }

    void Clear()
    {
        mapPacks.RemoveRange(0, mapPacks.Length);
        moreItems = false;
        lastId = 0;
    }

    void Reload() override
    {
        Clear();
        StartRequest();
    }

    void Render() override
    {
        CheckRequest();
        CheckRandomRequest();

        RenderSearchBar();
        RenderHeader();

        if (m_request !is null && mapPacks.Length == 0) {
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
            if (mapPacks.Length == 0) {
                if (u_typingStart == 0) UI::Text("No map packs found.");
                return;
            }
            UI::BeginChild("mapList");
            if (UI::BeginTable("List", 5, UI::TableFlags::RowBg)) {
                UI::TableSetupScrollFreeze(0, 1);
                PushTabStyle();
                UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Tags", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Tracks", UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);
                UI::TableHeadersRow();
                PopTabStyle();

                UI::ListClipper clipper(mapPacks.Length);
                while(clipper.Step()) {
                    for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                    {
                        UI::PushID("ResMap"+i);
                        MX::MapPackInfo@ mapPack = mapPacks[i];
                        IfaceRender::MapPackResult(mapPack);
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