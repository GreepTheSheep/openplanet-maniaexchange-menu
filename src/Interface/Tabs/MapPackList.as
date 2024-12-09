class MapPackListTab : Tab
{
    Net::HttpRequest@ m_request;
    array<MX::MapPackInfo@> mapPacks;
    uint totalItems = 0;
    bool m_useRandom = false;
    int m_page = 1;

    string u_search;
    uint64 u_typingStart;
    string t_selectedMode = "Mappack name";
    string t_paramMode = "name";
    string t_selectedFilter = "Latest";
    string t_selectedPriord = "1";

    bool IsVisible() override {return Setting_Tab_MapPacks_Visible;}
    string GetLabel() override {return Icons::Inbox + " Map Packs";}
    vec4 GetColor() override { return vec4(0.92f, 0.56f, 0.38f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        params.Set("api", "on");
        params.Set("format", "json");
        params.Set("limit", "100");
        params.Set("page", tostring(m_page));
        params.Set("priord", t_selectedPriord);

        if (u_search != "") {
            params.Set(t_paramMode, u_search);
        }

        if (m_useRandom) {
            params.Set("random", "1");
            m_useRandom = false;
        }
    }

    void StartRequest()
    {
        if (u_search.Length > 0 && u_search.Length < 2) {
            return;
        }

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

        if (isDevMode) trace("MapPackListTab::StartRequest: " + url);
        @m_request = API::Get(url);
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (!MX::APIDown && mapPacks.Length == 0 && m_request is null && UI::IsWindowAppearing()) {
            StartRequest();
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
            if (isDevMode) trace("MapPackListTab::CheckRequest: " + res);
            @m_request = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                mxError("Error while loading mappack list");
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
        MX::MapPackInfo@ mapPack;
        totalItems = json["totalItemCount"];

        auto items = json["results"];
        for (uint i = 0; i < items.Length; i++) {
            mapPacks.InsertLast(MX::MapPackInfo(items[i]));
        }
    }

    void RenderHeader()
    {
        UI::AlignTextToFramePadding();
        UI::Text("Search:");
        UI::SameLine();
        UI::SetNextItemWidth(140);
        if (UI::BeginCombo("##NamesFilter", t_selectedMode)){
            if (UI::Selectable("Mappack name", t_selectedMode == "Mappack name")){
                t_selectedMode = "Mappack name";
                t_paramMode = "name";
                Reload();
            }
            if (UI::Selectable("Creator name", t_selectedMode == "Creator name")){
                t_selectedMode = "Creator name";
                t_paramMode = "creator";
                Reload();
            }
            UI::EndCombo();
        }
        UI::SameLine();
        bool changed = false;
        u_search = UI::InputText("##MapPackSearch", u_search, changed);
        if (changed) {
            u_typingStart = Time::Now;
            Clear();
        }
        UI::SetNextItemWidth(150);
        if (UI::BeginCombo("##MapPackFilter", t_selectedFilter)){
            if (UI::Selectable("Latest", t_selectedFilter == "Latest")){
                t_selectedFilter = "Latest";
                t_selectedPriord = "1";
                Reload();
            }
            if (UI::Selectable("Most downloaded", t_selectedFilter == "Most downloaded")){
                t_selectedFilter = "Most downloaded";
                t_selectedPriord = "13";
                Reload();
            }
            if (UI::Selectable("Most tracks", t_selectedFilter == "Most tracks")){
                t_selectedFilter = "Most tracks";
                t_selectedPriord = "6";
                Reload();
            }
            UI::EndCombo();
        }
        UI::SameLine();
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
        mapPacks.RemoveRange(0, mapPacks.Length);
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
                UI::TableSetupColumn("Tracks", UI::TableColumnFlags::WidthFixed, 40);
                UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 40);
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
                if (m_request !is null && totalItems > mapPacks.Length) {
                    UI::TableNextRow();
                    UI::TableSetColumnIndex(0);
                    UI::AlignTextToFramePadding();
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