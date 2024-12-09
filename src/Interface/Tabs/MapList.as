class MapListTab : Tab
{
    Net::HttpRequest@ m_request;
    array<MX::MapInfo@> maps;
    uint totalItems = 0;
    bool m_useRandom = false;
    bool m_firstLoad = true;
    int m_selectedEnviroId = -1;
    string m_selectedEnviroName = "Any";
    int m_selectedVehicleId = -1;
    string m_selectedVehicleName = "Any";
    int m_page = 1;

    void GetRequestParams(dictionary@ params)
    {
        params.Set("api", "on");
        params.Set("format", "json");
        params.Set("limit", "100");
        if (m_selectedEnviroName != "Any") params.Set("environments", tostring(m_selectedEnviroId));
        if (m_selectedVehicleName != "Any") params.Set("vehicles", tostring(m_selectedVehicleId));
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

        string url = "https://"+MXURL+"/mapsearch2/search"+urlParams;

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
                m_selectedVehicleName = "StormMan";
                m_selectedVehicleId = 1;
            }
#endif
        }
        CheckStartRequest();

        // If there's a request, check if it has finished
        if (m_request !is null && m_request.Finished()) {
            // Parse the response
            string res = m_request.String();
            if (isDevMode) trace("MapListTab::CheckRequest: " + res);
            @m_request = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                mxError("Error while loading maps list");
                return;
            }

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
        MX::MapInfo@ map;
        totalItems = json["totalItemCount"];

        auto items = json["results"];
        for (uint i = 0; i < items.Length; i++) {
            maps.InsertLast(MX::MapInfo(items[i]));
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
                    MX::Environment@ envi = MX::m_environments[i];
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
            if (UI::BeginCombo("##VehicleFilter", m_selectedVehicleName)){
                for (uint i = 0; i < MX::m_vehicles.Length; i++) {
                    MX::Vehicle@ vehicle = MX::m_vehicles[i];
                    if (UI::Selectable(vehicle.Name, m_selectedVehicleName == vehicle.Name)){
                        m_selectedVehicleName = vehicle.Name;
                        m_selectedVehicleId = vehicle.ID;
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
        totalItems = 0;
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
                UI::TableSetupColumn(Icons::Trophy, UI::TableColumnFlags::WidthFixed, 40);
                UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 80);
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
                if (m_request !is null && totalItems > maps.Length) {
                    UI::TableNextRow();
                    UI::TableSetColumnIndex(0);
                    UI::AlignTextToFramePadding();
                    UI::Text(Icons::HourglassEnd + " Loading...");
                }
                UI::EndTable();
                if (m_request is null && totalItems > maps.Length && UI::GreenButton("Load more")){
                    m_page++;
                    StartRequest();
                }
            }
            UI::EndChild();
        }
    }
}