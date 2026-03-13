class UserListTab : Tab
{
    Net::HttpRequest@ m_request;
    array<MX::UserInfo@> users;
    bool moreItems;
    int lastId = 0;
    bool m_loadingRandom;

    UserFilters@ filters;
    uint64 u_typingStart;
    string t_search;
    int t_sortingKey = 0;
    string t_sortingName = "None";
    string t_sortSearchCombo;

    UserListTab() {
        @filters = UserFilters(this);
    }

    bool IsVisible() override { return Setting_Tab_Users_Visible; }
    string GetLabel() override { return Icons::Users + " Users"; }
    vec4 GetColor() override { return vec4(0.25f, 0.6f, 0.6f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        params.Set("fields", MX::userFields);

        if (t_sortingKey > 0) params.Set("order1", tostring(t_sortingKey));

        filters.GetRequestParams(params);
        if (t_search != "") params.Set("name", t_search);
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

        string url = MXURL + "/api/users" + urlParams;

        Logging::Debug("UserListTab::StartRequest: " + url);
        @m_request = API::Get(url);
    }

    void CheckStartRequest()
    {
        // If there's not already a request and the window is appearing, we start a new request
        if (!MX::APIDown && users.Length == 0 && m_request is null && UI::IsWindowAppearing()) {
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

            Logging::Debug("UserListTab::CheckRequest: " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
                Logging::Error("UserListTab::CheckRequest: Error while loading user list");
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
            users.InsertLast(MX::UserInfo(items[i]));

            if (moreItems && i == items.Length - 1) {
                lastId = items[i]["UserId"];
            }
        }
    }

    void GetRandomUser()
    {
        dictionary params = {
            { "random", "1" },
            { "count", "1" }
        };
        GetRequestParams(params);

        m_loadingRandom = true;
        array<MX::UserInfo@> users = MX::GetUsers(params);

        if (users.IsEmpty()) {
            Logging::Warn("UserListTab::GetRandomUser: Failed to get a random user", true);
        } else {
            mxMenu.AddTab(UserTab(users[0]), true);
        }

        m_loadingRandom = false;
    }

    void RenderSearchBar()
    {
        UI::AlignTextToFramePadding();
        UI::Text("Search:");
        UI::SameLine();

        bool changed = false;

        filters.m_name = UI::InputText("##NameSearch", filters.m_name, changed);

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

        if (UI::BeginCombo("##UserSearchOrders", t_sortingName)) {
            UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
            t_sortSearchCombo = UI::InputText("###UserSortOrderSearch", t_sortSearchCombo);

            UI::Separator();

            for (uint i = 0; i < MX::m_userSortingOrders.Length; i++) {
                MX::SortingOrder@ order = MX::m_userSortingOrders[i];

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

        UI::BeginDisabled(m_loadingRandom);

        if (UI::GreenButton(Icons::Random + " Random result")) {
            startnew(CoroutineFunc(GetRandomUser));
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
        users.RemoveRange(0, users.Length);
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

        RenderSearchBar();
        RenderHeader();

        if (m_request !is null && users.Length == 0) {
            UI::Text(Icons::AnimatedHourglass + " Loading...");
        } else {
            if (MX::APIDown) {
                UI::Text("API is down, please try again later.");
                if (UI::Button("Retry")) {
                    Reload();
                }
                return;
            }

            if (users.Length == 0) {
                if (u_typingStart == 0) UI::Text("No users found.");
                return;
            }

            UI::BeginChild("usersList");
            if (UI::BeginTable("Users", 12, UI::TableFlags::RowBg | UI::TableFlags::Hideable)) {
                UI::TableSetupScrollFreeze(0, 1);
                PushTabStyle();
                UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Registered", UI::TableColumnFlags::WidthFixed, 200 * UI::GetScale());
                UI::TableSetupColumn("Maps", UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("Mappacks", UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("Replays", UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("\\$FB1" + Icons::Trophy, UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("\\$FB1" + Icons::Trophy + "\\$z " + Icons::ArrowRight, UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn(Icons::Comment, UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn(Icons::Comment + Icons::ArrowRight, UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("\\$D34" + Icons::Heart, UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn(Icons::Kenney::BadgeAlt, UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);
                UI::TableHeadersRow();
                PopTabStyle();

                UI::TableSetColumnEnabled(0, Setting_UserName);
                UI::TableSetColumnEnabled(1, Setting_UserRegisterDate);
                UI::TableSetColumnEnabled(2, Setting_UserMapCount);
                UI::TableSetColumnEnabled(3, Setting_UserMappackCount);
                UI::TableSetColumnEnabled(4, Setting_UserReplayCount);
                UI::TableSetColumnEnabled(5, Setting_UserAwards);
                UI::TableSetColumnEnabled(6, Setting_UserAwards);
                UI::TableSetColumnEnabled(7, Setting_UserComments);
                UI::TableSetColumnEnabled(8, Setting_UserComments);
                UI::TableSetColumnEnabled(9, Setting_UserFavorites);
                UI::TableSetColumnEnabled(10, Setting_UserAchievements);

                UI::ListClipper clipper(users.Length);
                while (clipper.Step()) {
                    for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                        UI::PushID("ResUser" + i);
                        MX::UserInfo@ user = users[i];
                        IfaceRender::UserResult(user);
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
