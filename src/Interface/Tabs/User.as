class UserTab : Tab
{
    Net::HttpRequest@ m_MXUserInfoRequest;
    Net::HttpRequest@ m_MXUserMapsRequest;
    int m_userId;
    bool m_isYourProfileTab;
    MX::UserInfo@ m_user;
    array<MX::MapInfo@> m_mapsCreated;
    array<MX::MapInfo@> m_mapsAwardsGiven;
    MX::MapInfo@ m_featuredMap;
    bool m_error = false;

    UI::Font@ g_fontHeader = UI::LoadFont("DroidSans-Bold.ttf", 24);

    UserTab(const int &in userId, bool yourProfile = false) {
        m_userId = userId;
        m_isYourProfileTab = yourProfile;

        StartMXRequest();
    }

    bool CanClose() override { return !m_isYourProfileTab; }

    string GetLabel() override {
        if (m_isYourProfileTab) {
            return Icons::User + " Your Profile";
        } else {
            if (m_error) {
                return "\\$f00"+Icons::Times+" \\$zError";
            }
            if (m_user is null)
                return Icons::User + " Loading...";
            else {
                string res = Icons::User+" ";
                res += m_user.Username;
                return res;
            }
        }
    }

    vec4 GetColor() override {
        if (m_isYourProfileTab) return vec4(1,0.65,0,1);
        return vec4(0,0.5,1,1);
    }

    void StartMXRequest()
    {
        string url = "https://"+MXURL+"/api/users/get_user_info/"+m_userId;
        if (IsDevMode()) trace("UserTab::StartRequest (MX): "+url);
        @m_MXUserInfoRequest = API::Get(url);
    }

    void CheckMXRequest()
    {
        // If there's a request, check if it has finished
        if (m_MXUserInfoRequest !is null && m_MXUserInfoRequest.Finished()) {
            // Parse the response
            string res = m_MXUserInfoRequest.String();
            if (IsDevMode()) trace("UserTab::CheckRequest (MX): " + res);
            @m_MXUserInfoRequest = null;
            auto json = Json::Parse(res);

            if (json.GetType() != Json::Type::Object) {
                mxWarn("UserTab::CheckRequest (MX): Error parsing response");
                HandleMXResponseError();
                return;
            }
            // Handle the response
            HandleMXResponse(json);
        }
    }

    void HandleMXResponse(const Json::Value &in json)
    {
        @m_user = MX::UserInfo(json);
    }

    void HandleMXResponseError()
    {
        m_error = true;
    }

    void Render() override
    {
        CheckMXRequest();

        if (m_error) {
            UI::Text("\\$f00" + Icons::Times + " \\$zUser not found");
            return;
        }

        if (m_user is null) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
            return;
        }

        float width = UI::GetWindowSize().x*0.25;
        vec2 posTop = UI::GetCursorPos();

        UI::BeginChild("Summary", vec2(width,0));

        UI::PushFont(g_fontHeader);
        UI::Text(m_user.Username);
        UI::PopFont();

        UI::Text(Icons::Map+ " \\$f77" + m_user.TrackCount);

        UI::Text(Icons::Hashtag+ " \\$f77" + m_user.UserID);
        UI::SameLine();
        UI::TextDisabled(Icons::Clipboard);
        UI::SetPreviousTooltip("Click to copy to clipboard");
        if (UI::IsItemClicked()) {
            IO::SetClipboard(tostring(m_user.UserID));
            UI::ShowNotification(Icons::Clipboard + " User ID copied to clipboard");
        }

        UI::EndChild();

        UI::SetCursorPos(posTop + vec2(width + 8, 0));
        UI::BeginChild("Description");

        UI::BeginTabBar("UserTabs");

        if (UI::BeginTabItem("Description")) {
            UI::BeginChild("UserDescriptionChild");
            IfaceRender::MXComment(m_user.Comments);
            UI::EndChild();
            UI::EndTabItem();
        }

        UI::EndTabBar();

        UI::EndChild();
    }
}