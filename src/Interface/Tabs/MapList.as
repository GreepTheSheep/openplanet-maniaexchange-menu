class MapListTab : Tab
{
    Net::HttpRequest@ m_request;
    array<MX::MapInfo@> maps;
    bool moreItems = false;
    bool m_useRandom = false;
    bool m_firstLoad = true;
    int m_selectedEnviroId = -1;
    string m_selectedEnviroName = "Any";
    string m_selectedVehicle = "Any";
    int lastId = 0;

    void GetRequestParams(dictionary@ params)
    {
        params.Set("fields", MX::mapFields);

        if (moreItems && lastId != 0) {
            params.Set("after", tostring(lastId));
        }

        if (m_selectedEnviroName != "Any") params.Set("environment", tostring(m_selectedEnviroId));
        if (m_selectedVehicle != "Any") params.Set("vehicle", m_selectedVehicle);

        if (m_useRandom) {
            params.Set("random", "1");
            params.Set("count", "1");
            m_useRandom = false;
        } else {
            params.Set("count", "100");
        }
    }

    void StartRequest()
    {
        dictionary params;
        GetRequestParams(params);
        string urlParams = MX::DictToApiParams(params);

        string url = "https://"+MXURL+"/api/maps" + urlParams;

        if (isDevMode) trace("MapListTab::StartRequest: " + url);
        @m_request = API::Get(url);
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (!MX::APIDown && maps.Length == 0 && m_request is null && UI::IsWindowAppearing()) {
            StartRequest();
        }
    }

    void CheckRequest()
    {
        if (m_firstLoad) {
            m_firstLoad = false;
#if TMNEXT
            m_selectedEnviroName = "Stadium";
            m_selectedEnviroId = 1;
#else
            if (repo == MP4mxRepos::Shootmania) {
                m_selectedEnviroName = "Storm";
                m_selectedEnviroId = 1;
                m_selectedVehicle = "StormMan";
            }
#endif
        }
        CheckStartRequest();

        // If there's a request, check if it has finished
        if (m_request !is null && m_request.Finished()) {
            // Parse the response
            string res = m_request.String();
            int resCode = m_request.ResponseCode();
            auto json = m_request.Json();
            @m_request = null;

            if (isDevMode) trace("MapListTab::CheckRequest: " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results") || json["Results"].Length == 0) {
                mxError("Error while loading maps list");
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

    void RenderHeader()
    {
        UI::AlignTextToFramePadding();

        if (MX::m_environments.Length > 1) {
            UI::Text("Environment:");
            UI::SameLine();
            UI::SetNextItemWidth(150);
            if (UI::BeginCombo("##EnviroFilter", m_selectedEnviroName)){
                for (uint i = 0; i < MX::m_environments.Length; i++) {
                    MX::MapEnvironment@ envi = MX::m_environments[i];
                    if (UI::Selectable(envi.Name, m_selectedEnviroName == envi.Name)){
                        m_selectedEnviroName = envi.Name;
                        m_selectedEnviroId = envi.ID;
                        Reload();
                    }
                }
                UI::EndCombo();
            }
            UI::SameLine();
        }

        if (MX::m_vehicles.Length > 1) {
            UI::Text("Vehicle:");
            UI::SameLine();
            UI::SetNextItemWidth(150);
            if (UI::BeginCombo("##VehicleFilter", m_selectedVehicle)){
                for (uint i = 0; i < MX::m_vehicles.Length; i++) {
                    string vehicleName = MX::m_vehicles[i];
                    if (UI::Selectable(vehicleName, m_selectedVehicle == vehicleName)){
                        m_selectedVehicle = vehicleName;
                        Reload();
                    }
                }
                UI::EndCombo();
            }
            UI::SameLine();
        }
        if (UI::GreenButton(Icons::Random + " Random result")){
            m_useRandom = true;
            Reload();
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