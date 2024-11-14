class UserTab : Tab
{
    Net::HttpRequest@ m_MXUserInfoRequest;
    Net::HttpRequest@ m_MXUserLeaderboardRequest;
    Net::HttpRequest@ m_MXUserMapsCreatedRequest;
    Net::HttpRequest@ m_MXUserMapsAwardedRequest;
    Net::HttpRequest@ m_MXUserMapPacksRequest;
    Net::HttpRequest@ m_MXUserFeaturedMapRequest;
    int m_userId;
    bool m_isYourProfileTab;
    MX::UserInfo@ m_user;
    array<MX::MapInfo@> m_mapsCreated;
    uint m_mapsCreatedTotal = 0;
    array<MX::MapInfo@> m_mapsAwardsGiven;
    uint m_mapsAwardsGivenTotal = 0;
    array<MX::MapPackInfo@> m_mapPacks;
    uint m_mapPacksTotal = 0;
    MX::MapInfo@ m_featuredMap;
    bool m_hasFeaturedMap = false;
    bool m_error = false;
    bool m_featuredMapError = false;
    bool m_createdMapsError = false;
    bool m_awardedMapsError = false;
    bool m_mapPacksError = false;

    MX::UserLeaderboard@ m_leaderboard;
    string m_selectedLeaderboard = "Cumulative";
    int m_selectedLeaderboardId = -1;
    bool m_leaderboardError = false;
    string m_leaderboardErrorMessage = "";

    int m_pageCreatedMaps = 1;
    int m_pageAwardedMaps = 1;
    int m_pageMapPacks = 1;

    UI::Font@ g_fontHeader;

    UserTab(const int &in userId, bool yourProfile = false) {
        @g_fontHeader = UI::LoadFont("DroidSans-Bold.ttf", 24);
        m_userId = userId;
        m_isYourProfileTab = yourProfile;
    }

    bool CanClose() override { return !m_isYourProfileTab; }

    string GetLabel() override {
        if (m_isYourProfileTab) {
            return Icons::User;
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

    string GetTooltip() override {
        if (m_isYourProfileTab)
            return "Your profile";
        else
            return "";
    }

    vec4 GetColor() override {
        if (m_isYourProfileTab) return vec4(0.75,0,0.27,1);
        return vec4(0,0.5,1,1);
    }

    void StartMXRequest()
    {
        string url = "https://"+MXURL+"/api/users/get_user_info/"+m_userId;
        if (isDevMode) trace("UserTab::StartRequest (MX): "+url);
        @m_MXUserInfoRequest = API::Get(url);
    }

    void CheckMXRequest()
    {
        if (!MX::APIDown && m_user is null && m_MXUserInfoRequest is null && UI::IsWindowAppearing()) {
            StartMXRequest();
        }
        // If there's a request, check if it has finished
        if (m_MXUserInfoRequest !is null && m_MXUserInfoRequest.Finished()) {
            // Parse the response
            string res = m_MXUserInfoRequest.String();
            if (isDevMode) trace("UserTab::CheckRequest (MX): " + res);
            @m_MXUserInfoRequest = null;
            auto json = Json::Parse(res);

            if (json.GetType() != Json::Type::Object) {
                mxWarn("UserTab::CheckRequest (MX): Error parsing response");
                m_error = true;
                return;
            }
            // Handle the response
            @m_user = MX::UserInfo(json);

            if (m_user.FeaturedTrackID != 0) {
                m_hasFeaturedMap = true;
                StartMXFeaturedMapRequest();
            }
        }
    }

    void StartMXFeaturedMapRequest()
    {
        string url = "https://"+MXURL+"/api/maps/get_map_info/multi/"+m_user.FeaturedTrackID;
        if (isDevMode) trace("UserTab::FeaturedMap::StartRequest (MX): "+url);
        @m_MXUserFeaturedMapRequest = API::Get(url);
    }

    void CheckMXFeaturedMapRequest()
    {
        // If there's a request, check if it has finished
        if (m_MXUserFeaturedMapRequest !is null && m_MXUserFeaturedMapRequest.Finished()) {
            // Parse the response
            string res = m_MXUserFeaturedMapRequest.String();
            if (isDevMode) trace("UserTab::FeaturedMap::CheckRequest (MX): " + res);
            @m_MXUserFeaturedMapRequest = null;
            auto json = Json::Parse(res);

            if (json.Length == 0) {
                mxWarn("UserTab::FeaturedMap::CheckRequest (MX): Error parsing response");
                m_featuredMapError = true;
                return;
            }
            // Handle the response
            @m_featuredMap = MX::MapInfo(json[0]);
        }
    }

    void StartMXLeaderboardRequest()
    {
        string url = "https://"+MXURL+"/api/leaderboard/season/"+m_selectedLeaderboardId+"/user/"+m_userId;

        if (isDevMode) trace("UserTab::Leaderboard::StartRequest: " + url);
        @m_MXUserLeaderboardRequest = API::Get(url);
    }

    void CheckMXLeaderboardRequest()
    {
        if (!MX::APIDown && m_leaderboard is null && m_MXUserLeaderboardRequest is null && UI::IsWindowAppearing()) {
            StartMXLeaderboardRequest();
        }
        // If there's a request, check if it has finished
        if (m_MXUserLeaderboardRequest !is null && m_MXUserLeaderboardRequest.Finished()) {
            // Parse the response
            string res = m_MXUserLeaderboardRequest.String();
            if (isDevMode) trace("UserTab::Leaderboard::CheckRequest (MX): " + res);
            @m_MXUserLeaderboardRequest = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                m_leaderboardError = true;
                m_leaderboardErrorMessage = "Error while loading user leaderboard";
                mxError(m_leaderboardErrorMessage);
                return;
            }
            if (json.GetType() == Json::Type::Array) {
                json = json[0];
            }
            if (json.GetType() == Json::Type::Null) {
                m_leaderboardError = true;
                m_leaderboardErrorMessage = "No leaderboard data found for this season";
                mxError(m_leaderboardErrorMessage);
                return;
            }
            m_leaderboardError = false;
            m_leaderboardErrorMessage = "";

            // Handle the response
            @m_leaderboard = MX::UserLeaderboard(json);
        }
    }

    void StartMXCreatedMapsRequest()
    {
        dictionary params;
        params.Set("api", "on");
        params.Set("format", "json");
        params.Set("limit", "100");
        params.Set("page", tostring(m_pageCreatedMaps));
        params.Set("mode", "1");
        params.Set("authorid", tostring(m_userId));

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

        if (isDevMode) trace("UserTab::CreatedMaps::StartRequest: " + url);
        @m_MXUserMapsCreatedRequest = API::Get(url);
    }

    void CheckMXCreatedMapsRequest()
    {
        if (!MX::APIDown && m_mapsCreated.Length == 0 && m_MXUserMapsCreatedRequest is null && UI::IsWindowAppearing()) {
            StartMXCreatedMapsRequest();
        }
        // If there's a request, check if it has finished
        if (m_MXUserMapsCreatedRequest !is null && m_MXUserMapsCreatedRequest.Finished()) {
            // Parse the response
            string res = m_MXUserMapsCreatedRequest.String();
            if (isDevMode) trace("UserTab::CreatedMaps::CheckRequest (MX): " + res);
            @m_MXUserMapsCreatedRequest = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                mxError("Error while loading maps list");
                return;
            }

            // Handle the response
            if (json.HasKey("error")) {
                m_createdMapsError = true;
            } else {
                m_mapsCreatedTotal = json["totalItemCount"];
                auto items = json["results"];
                for (uint i = 0; i < items.Length; i++) {
                    m_mapsCreated.InsertLast(MX::MapInfo(items[i]));
                }
            }
        }
    }

    void StartMXAwardedMapsRequest()
    {
        dictionary params;
        params.Set("api", "on");
        params.Set("format", "json");
        params.Set("limit", "100");
        params.Set("page", tostring(m_pageAwardedMaps));
        params.Set("mode", "8");
        params.Set("authorid", tostring(m_userId));
        params.Set("priord", "20");

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

        if (isDevMode) trace("UserTab::AwardedMaps::StartRequest: " + url);
        @m_MXUserMapsAwardedRequest = API::Get(url);
    }

    void CheckMXAwardedMapsRequest()
    {
        if (!MX::APIDown && m_mapsAwardsGiven.Length == 0 && m_MXUserMapsAwardedRequest is null && UI::IsWindowAppearing()) {
            StartMXAwardedMapsRequest();
        }
        // If there's a request, check if it has finished
        if (m_MXUserMapsAwardedRequest !is null && m_MXUserMapsAwardedRequest.Finished()) {
            // Parse the response
            string res = m_MXUserMapsAwardedRequest.String();
            if (isDevMode) trace("UserTab::AwardedMaps::CheckRequest (MX): " + res);
            @m_MXUserMapsAwardedRequest = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                mxError("Error while loading maps list");
                return;
            }

            // Handle the response
            if (json.HasKey("error")) {
                m_awardedMapsError = true;
            } else {
                m_mapsAwardsGivenTotal = json["totalItemCount"];
                auto items = json["results"];
                for (uint i = 0; i < items.Length; i++) {
                    m_mapsAwardsGiven.InsertLast(MX::MapInfo(items[i]));
                }
            }
        }
    }

    void StartMXMapPacksRequest()
    {
        dictionary params;
        params.Set("api", "on");
        params.Set("format", "json");
        params.Set("limit", "100");
        params.Set("page", tostring(m_pageMapPacks));
        params.Set("mode", "1");
        params.Set("userid", tostring(m_userId));
        params.Set("priord", "1");

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

        if (isDevMode) trace("UserTab::MapPacks::StartRequest: " + url);
        @m_MXUserMapPacksRequest = API::Get(url);
    }

    void CheckMXMapPacksRequest()
    {
        if (!MX::APIDown && m_mapPacks.Length == 0 && m_MXUserMapPacksRequest is null && UI::IsWindowAppearing()) {
            StartMXMapPacksRequest();
        }
        // If there's a request, check if it has finished
        if (m_MXUserMapPacksRequest !is null && m_MXUserMapPacksRequest.Finished()) {
            // Parse the response
            string res = m_MXUserMapPacksRequest.String();
            if (isDevMode) trace("UserTab::MapPacks::CheckRequest (MX): " + res);
            @m_MXUserMapPacksRequest = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                mxError("Error while loading mappack list");
                return;
            }

            // Handle the response
            if (json.HasKey("error")) {
                m_mapPacksError = true;
            } else {
                m_mapPacksTotal = json["totalItemCount"];
                auto items = json["results"];
                for (uint i = 0; i < items.Length; i++) {
                    m_mapPacks.InsertLast(MX::MapPackInfo(items[i]));
                }
            }
        }
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

        UI::SameLine();
        if (m_MXUserInfoRequest is null) {
            if (UI::Button(Icons::Refresh)) StartMXRequest();
            UI::SetPreviousTooltip("Refresh User info");
        } else {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass);
            UI::SetPreviousTooltip("Loading...");
        }

        auto img = Images::CachedFromURL("https://account.mania.exchange/account/avatar/"+m_userId);

        if (img.m_texture !is null){
            vec2 thumbSize = img.m_texture.GetSize();
            UI::Image(img.m_texture, vec2(
                width,
                thumbSize.y / (thumbSize.x / width)
            ));
            if (UI::IsItemHovered()) {
                UI::BeginTooltip();
                UI::Image(img.m_texture, vec2(
                    Draw::GetWidth() * 0.3,
                    thumbSize.y / (thumbSize.x / (Draw::GetWidth() * 0.3))
                ));
                UI::EndTooltip();
            }
        } else {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading Avatar...");
        }

        UI::Text(Icons::Calendar+ " \\$f77" + m_user.Registered);
        UI::SetPreviousTooltip("Registered");

        UI::Text(Icons::Map+ " \\$f77" + m_user.TrackCount);
        UI::SetPreviousTooltip("Tracks created");

        UI::Text(Icons::Inbox+ " \\$f77" + m_user.MappackCount);
        UI::SetPreviousTooltip("Mappacks created");

        UI::Text(Icons::Trophy+ " \\$f77" + m_user.AwardsReceived);
        UI::SetPreviousTooltip("Awards");

        UI::Text(Icons::Hashtag+ " \\$f77" + m_user.UserID);
        UI::SetPreviousTooltip("User ID");
        UI::SameLine();
        UI::TextDisabled(Icons::Clipboard);
        UI::SetPreviousTooltip("Click to copy to clipboard");
        if (UI::IsItemClicked()) {
            IO::SetClipboard(tostring(m_user.UserID));
            UI::ShowNotification(Icons::Clipboard + " User ID copied to clipboard");
        }

        if (UI::CyanButton(Icons::ExternalLink + " View on "+shortMXName)) OpenBrowserURL("https://"+MXURL+"/user/profile/"+m_userId);
        if (m_isYourProfileTab && UI::PurpleButton(Icons::ExternalLink + " Manage your account")) OpenBrowserURL("https://account.mania.exchange/account");

        if (!m_isYourProfileTab && Setting_Tab_YourProfile_UserID == 0) {
            UI::Separator();
            UI::Text(Icons::InfoCircle + " Is this your profile?\nAdd your profile to easily get it from the tabs.");
            if (UI::GreenButton(Icons::Plus + " Add to your profile")) {
                Setting_Tab_YourProfile_UserID = m_userId;
            }
        }

        UI::EndChild();

        UI::SetCursorPos(posTop + vec2(width + 8, 0));
        UI::BeginChild("Description");

        UI::BeginTabBar("UserTabs");

        if (UI::BeginTabItem("Description")) {
            UI::BeginChild("UserDescriptionChild", vec2(0, UI::GetWindowSize().y * 0.6));
            IfaceRender::MXComment(m_user.Comments);
            UI::EndChild();
            if (m_hasFeaturedMap) {
                UI::Separator();
                CheckMXFeaturedMapRequest();
                UI::BeginChild("UserFeaturdMapChild");
                UI::Text(pluginColor + Icons::Map + " \\$zFeatured Map:");
                if (m_featuredMapError) {
                    UI::Text("\\$f00" + Icons::Times + " \\$zError while loading featured map");
                } else {
                    if (m_featuredMap is null) {
                        int HourGlassValue = Time::Stamp % 3;
                        string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                        UI::Text(Hourglass + " Loading...");
                    } else {
                        float featuredMapwidth = Draw::GetWidth() * 0.10;
                        UI::BeginChild("UserFeaturedMapImageChild", vec2(featuredMapwidth + 20, 0));
                        auto featuredMapImg = Images::CachedFromURL("https://"+MXURL+"/maps/"+m_featuredMap.TrackID+"/image/1");

                        if (featuredMapImg.m_texture !is null){
                            vec2 thumbSize = featuredMapImg.m_texture.GetSize();
                            UI::Image(featuredMapImg.m_texture, vec2(
                                featuredMapwidth,
                                thumbSize.y / (thumbSize.x / featuredMapwidth)
                            ));
                            if (UI::IsItemHovered()) {
                                UI::BeginTooltip();
                                UI::Image(featuredMapImg.m_texture, vec2(
                                    Draw::GetWidth() * 0.45,
                                    thumbSize.y / (thumbSize.x / (Draw::GetWidth() * 0.45))
                                ));
                                UI::EndTooltip();
                            }
                        } else {
                            auto featuredMapthumb = Images::CachedFromURL("https://"+MXURL+"/maps/thumbnail/"+m_featuredMap.TrackID);
                            if (featuredMapthumb.m_texture !is null){
                                vec2 thumbSize = featuredMapthumb.m_texture.GetSize();
                                UI::Image(featuredMapthumb.m_texture, vec2(
                                    featuredMapwidth,
                                    thumbSize.y / (thumbSize.x / featuredMapwidth)
                                ));
                                if (UI::IsItemHovered()) {
                                    UI::BeginTooltip();
                                    UI::Image(featuredMapthumb.m_texture, vec2(
                                        Draw::GetWidth() * 0.3,
                                        thumbSize.y / (thumbSize.x / (Draw::GetWidth() * 0.3))
                                    ));
                                    UI::EndTooltip();
                                }
                            } else {
                                int HourGlassValue = Time::Stamp % 3;
                                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                                UI::Text(Hourglass + " Loading thumbnail...");
                            }
                        }
                        UI::EndChild();
                        UI::SetCursorPos(posTop + vec2(featuredMapwidth + 28, 20));
                        UI::BeginChild("UserFeaturedMapDescriptionChild");
                        UI::PushFont(g_fontHeader);
                        UI::Text(Text::OpenplanetFormatCodes(m_featuredMap.GbxMapName));
                        UI::PopFont();
                        if (m_featuredMap.Comments.Length > 100) {
                            IfaceRender::MXComment(m_featuredMap.Comments.SubStr(0, 100) + "...");
                        } else {
                            IfaceRender::MXComment(m_featuredMap.Comments);
                        }
                        if (UI::Button(Icons::InfoCircle)) mxMenu.AddTab(MapTab(m_featuredMap.TrackID), true);
                        UI::SameLine();
                        if (UI::GreenButton(Icons::Play)) {
                            if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                            UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(m_featuredMap.GbxMapName) + "\\$z\\$s by " + m_featuredMap.Username);
                            MX::mapToLoad = m_featuredMap.TrackID;
                        }
                        UI::EndChild();
                    }
                }
                UI::EndChild();
            }
            UI::EndTabItem();
        }

        if (UI::BeginTabItem(Icons::ListOl + " " + shortMXName + " Leaderboard")) {
            UI::BeginChild("UserLeaderboardChild");
            if (UI::BeginCombo("##Leaderboard", m_selectedLeaderboard)) {
                if (UI::Selectable("Cumulative", m_selectedLeaderboard == "Cumulative")) {
                    @m_leaderboard = null;
                    m_leaderboardError = false;
                    m_leaderboardErrorMessage = "";
                    m_selectedLeaderboard = "Cumulative";
                    m_selectedLeaderboardId = -1;
                    StartMXLeaderboardRequest();
                }
                for (uint i = 0; i < MX::m_leaderboardSeasons.Length; i++) {
                    if (UI::Selectable(MX::m_leaderboardSeasons[i].Name, m_selectedLeaderboard == MX::m_leaderboardSeasons[i].Name)) {
                        @m_leaderboard = null;
                        m_leaderboardError = false;
                        m_leaderboardErrorMessage = "";
                        m_selectedLeaderboard = MX::m_leaderboardSeasons[i].Name;
                        m_selectedLeaderboardId = MX::m_leaderboardSeasons[i].SeasonID;
                        StartMXLeaderboardRequest();
                    }
                }
                UI::EndCombo();
            }
            CheckMXLeaderboardRequest();

            if (m_leaderboard is null) {
                if (m_leaderboardError) {
                    UI::Text("\\$f00" + Icons::Times + " \\$z"+m_leaderboardErrorMessage);
                } else {
                    int HourGlassValue = Time::Stamp % 3;
                    string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                    UI::Text(Hourglass + " Loading...");
                }
            } else {
                UI::Text(Icons::Kenney::ButtonCircle + " Position: \\$f77"+tostring(m_leaderboard.Position));
                UI::Text(Icons::Bolt + " Score: \\$f77"+Text::Format("%.2f", m_leaderboard.Score));
                UI::Text("WRs: \\$f77"+tostring(m_leaderboard.WorldRecords));
                UI::Text("Top 2s: \\$f77"+tostring(m_leaderboard.TOP2s));
                UI::Text("Top 3s: \\$f77"+tostring(m_leaderboard.TOP3s));
                UI::Text("Replay count: \\$f77"+tostring(m_leaderboard.ReplayCount));
            }
            UI::Separator();
            UI::TextWrapped("This leaderboard is based on the replays you submit to "+ pluginName+".\n"
                "To appear on this leaderboard, you must have at least one replay submitted.\n"
                "You can submit replays on the map page by clicking on the \"View on "+pluginName+"\" button in a map page.");
            UI::EndChild();
            UI::EndTabItem();
        }

        if (m_user.TrackCount > 0 && UI::BeginTabItem(Icons::Map + " Created")) {
            UI::BeginChild("UserMapsCreatedChild");
            CheckMXCreatedMapsRequest();
            if (m_MXUserMapsCreatedRequest !is null && m_mapsCreated.Length == 0) {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Loading...");
            } else {
                if (UI::BeginTable("CreatedMapsList", 5)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    PushTabStyle();
                    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Style", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn(Icons::Trophy, UI::TableColumnFlags::WidthFixed, 40);
                    UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 80);
                    UI::TableHeadersRow();
                    PopTabStyle();

                    UI::ListClipper clipper(m_mapsCreated.Length);
                    while(clipper.Step()) {
                        for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                        {
                            UI::PushID("ResMap"+i);
                            MX::MapInfo@ map = m_mapsCreated[i];
                            IfaceRender::MapResult(map);
                            UI::PopID();
                        }
                    }
                    if (m_MXUserMapsCreatedRequest !is null && m_mapsCreatedTotal > m_mapsCreated.Length) {
                        UI::TableNextRow();
                        UI::TableSetColumnIndex(0);
                        UI::AlignTextToFramePadding();
                        UI::Text(Icons::HourglassEnd + " Loading...");
                    }
                    UI::EndTable();
                    if (m_MXUserMapsCreatedRequest is null && m_mapsCreatedTotal > m_mapsCreated.Length && UI::GreenButton("Load more")){
                        m_pageCreatedMaps++;
                        StartMXCreatedMapsRequest();
                    }
                }
            }
            UI::EndChild();
            UI::EndTabItem();
        }

        if (m_user.AwardsGiven > 0 && UI::BeginTabItem(Icons::Trophy + " Awarded")) {
            UI::BeginChild("UserMapsAwardedChild");
            CheckMXAwardedMapsRequest();
            if (m_MXUserMapsAwardedRequest !is null && m_mapsAwardsGiven.Length == 0) {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Loading...");
            } else {
                if (UI::BeginTable("CreatedMapsList", 5)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    PushTabStyle();
                    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Style", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn(Icons::Trophy, UI::TableColumnFlags::WidthFixed, 40);
                    UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 80);
                    UI::TableHeadersRow();
                    PopTabStyle();

                    UI::ListClipper clipper(m_mapsAwardsGiven.Length);
                    while(clipper.Step()) {
                        for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                        {
                            UI::PushID("ResMap"+i);
                            MX::MapInfo@ map = m_mapsAwardsGiven[i];
                            IfaceRender::MapResult(map);
                            UI::PopID();
                        }
                    }
                    if (m_MXUserMapsCreatedRequest !is null && m_mapsAwardsGivenTotal > m_mapsCreated.Length) {
                        UI::TableNextRow();
                        UI::TableSetColumnIndex(0);
                        UI::AlignTextToFramePadding();
                        UI::Text(Icons::HourglassEnd + " Loading...");
                    }
                    UI::EndTable();
                    if (m_MXUserMapsCreatedRequest is null && m_mapsAwardsGivenTotal > m_mapsCreated.Length && UI::GreenButton("Load more")){
                        m_pageAwardedMaps++;
                        StartMXAwardedMapsRequest();
                    }
                }
            }
            UI::EndChild();
            UI::EndTabItem();
        }

        if (m_user.MappackCount > 0 && UI::BeginTabItem(Icons::Inbox + " Map Packs")) {
            UI::BeginChild("UserMapPacksChild");
            CheckMXMapPacksRequest();
            if (m_MXUserMapPacksRequest !is null && m_mapsAwardsGiven.Length == 0) {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Loading...");
            } else {
                if (UI::BeginTable("UserMapPacksList", 5)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    PushTabStyle();
                    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Tags", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Tracks", UI::TableColumnFlags::WidthFixed, 40);
                    UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 40);
                    UI::TableHeadersRow();
                    PopTabStyle();

                    UI::ListClipper clipper(m_mapPacks.Length);
                    while(clipper.Step()) {
                        for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                        {
                            UI::PushID("ResMap"+i);
                            MX::MapPackInfo@ mapPack = m_mapPacks[i];
                            IfaceRender::MapPackResult(mapPack);
                            UI::PopID();
                        }
                    }
                    if (m_MXUserMapPacksRequest !is null && m_mapPacksTotal > m_mapPacks.Length) {
                        UI::TableNextRow();
                        UI::TableSetColumnIndex(0);
                        UI::AlignTextToFramePadding();
                        UI::Text(Icons::HourglassEnd + " Loading...");
                    }
                    UI::EndTable();
                    if (m_MXUserMapPacksRequest is null && m_mapPacksTotal > m_mapPacks.Length && UI::GreenButton("Load more")){
                        m_pageMapPacks++;
                        StartMXMapPacksRequest();
                    }
                }
            }
            UI::EndChild();
            UI::EndTabItem();
        }

        UI::EndTabBar();

        UI::EndChild();
    }
}