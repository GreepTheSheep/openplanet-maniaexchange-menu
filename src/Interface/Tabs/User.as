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
    bool m_moreItemsCreatedMaps = false;
    array<MX::MapInfo@> m_mapsAwardsGiven;
    bool m_moreItemsAwardsGiven = false;
    array<MX::MapPackInfo@> m_mapPacks;
    bool m_moreItemsMapPacks = false;
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

    int m_lastIdCreatedMaps = 0;
    int m_lastIdAwardedMaps = 0;
    int m_lastIdMapPacks = 0;

    MapColumns@ createdWidths = MapColumns();
    MapColumns@ awardedWidths = MapColumns();

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
                res += m_user.Name;
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
        dictionary params;
        params.Set("fields", MX::userFields);
        params.Set("id", tostring(m_userId));
        string userUrlParams = MX::DictToApiParams(params);

        string url = "https://"+MXURL+"/api/users" + userUrlParams;
        Logging::Debug("UserTab::StartRequest (MX): "+url);
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
            int resCode = m_MXUserInfoRequest.ResponseCode();
            auto json = m_MXUserInfoRequest.Json();
            @m_MXUserInfoRequest = null;

            Logging::Debug("UserTab::CheckRequest (MX): " + res);

            if (resCode >400 || json.GetType() != Json::Type::Object || !json.HasKey("Results") || json["Results"].Length == 0) {
                Logging::Warn("UserTab::CheckRequest (MX): Error parsing response");
                m_error = true;
                return;
            }
            // Handle the response
            @m_user = MX::UserInfo(json["Results"][0]);

            if (m_user.FeaturedTrackID != 0) {
                m_hasFeaturedMap = true;
                StartMXFeaturedMapRequest();
            }
        }
    }

    void StartMXFeaturedMapRequest()
    {
        dictionary params;
        params.Set("fields", MX::mapFields);
        params.Set("id", tostring(m_user.FeaturedTrackID));
        string mapUrlParams = MX::DictToApiParams(params);

        string url = "https://"+MXURL+"/api/maps" + mapUrlParams;
        Logging::Debug("UserTab::FeaturedMap::StartRequest (MX): "+url);
        @m_MXUserFeaturedMapRequest = API::Get(url);
    }

    void CheckMXFeaturedMapRequest()
    {
        // If there's a request, check if it has finished
        if (m_MXUserFeaturedMapRequest !is null && m_MXUserFeaturedMapRequest.Finished()) {
            // Parse the response
            string res = m_MXUserFeaturedMapRequest.String();
            int resCode = m_MXUserFeaturedMapRequest.ResponseCode();
            auto json = m_MXUserFeaturedMapRequest.Json();
            @m_MXUserFeaturedMapRequest = null;

            Logging::Debug("UserTab::FeaturedMap::CheckRequest (MX): " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results") || json["Results"].Length == 0) {
                Logging::Warn("UserTab::FeaturedMap::CheckRequest (MX): Error parsing response");
                m_featuredMapError = true;
                return;
            }
            // Handle the response
            @m_featuredMap = MX::MapInfo(json["Results"][0]);
        }
    }

    void StartMXLeaderboardRequest() // TODO doesn't exist yet
    {
        string url = "https://"+MXURL+"/api/leaderboard/season/"+m_selectedLeaderboardId+"/user/"+m_userId;

        Logging::Debug("UserTab::Leaderboard::StartRequest: " + url);
        @m_MXUserLeaderboardRequest = API::Get(url);
    }

    void CheckMXLeaderboardRequest() // TODO change once leaderboards are released on 2.0
    {
        if (!MX::APIDown && m_leaderboard is null && m_MXUserLeaderboardRequest is null && UI::IsWindowAppearing()) {
            StartMXLeaderboardRequest();
        }
        // If there's a request, check if it has finished
        if (m_MXUserLeaderboardRequest !is null && m_MXUserLeaderboardRequest.Finished()) {
            // Parse the response
            string res = m_MXUserLeaderboardRequest.String();
            int resCode = m_MXUserLeaderboardRequest.ResponseCode();
            auto json = m_MXUserLeaderboardRequest.Json();
            @m_MXUserLeaderboardRequest = null;

            Logging::Debug("UserTab::Leaderboard::CheckRequest (MX): " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null) {
                m_leaderboardError = true;
                m_leaderboardErrorMessage = "Error while loading user leaderboard";
                Logging::Error(m_leaderboardErrorMessage);
                return;
            }
            if (json.GetType() == Json::Type::Array) {
                json = json[0];
            }
            if (json.GetType() == Json::Type::Null) {
                m_leaderboardError = true;
                m_leaderboardErrorMessage = "No leaderboard data found for this season";
                Logging::Error(m_leaderboardErrorMessage);
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
        params.Set("fields", MX::mapFields);
        params.Set("count", "100");
        params.Set("authoruserid", tostring(m_userId));

        if (m_moreItemsCreatedMaps && m_lastIdCreatedMaps != 0) {
            params.Set("after", tostring(m_lastIdCreatedMaps));
        }

        string urlParams = MX::DictToApiParams(params);

        string url = "https://"+MXURL+"/api/maps" + urlParams;

        Logging::Debug("UserTab::CreatedMaps::StartRequest: " + url);
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
            int resCode = m_MXUserMapsCreatedRequest.ResponseCode();
            auto json = m_MXUserMapsCreatedRequest.Json();
            @m_MXUserMapsCreatedRequest = null;

            Logging::Debug("UserTab::CreatedMaps::CheckRequest (MX): " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results") || json["Results"].Length == 0) {
                Logging::Error("Error while loading maps list");
                return;
            }

            // Handle the response
            if (json.HasKey("title")) {
                m_createdMapsError = true;
            } else {
                m_moreItemsCreatedMaps = json["More"];
                auto items = json["Results"];
                for (uint i = 0; i < items.Length; i++) {
                    m_mapsCreated.InsertLast(MX::MapInfo(items[i]));

                    if (m_moreItemsCreatedMaps && i == items.Length - 1) {
                        m_lastIdCreatedMaps = items[i]["MapId"];
                    }
                }
            }

            createdWidths.Update(m_mapsCreated);
        }
    }

    void StartMXAwardedMapsRequest()
    {
        dictionary params;
        params.Set("fields", MX::mapFields);
        params.Set("count", "100");

        if (m_moreItemsAwardsGiven && m_lastIdAwardedMaps != 0) {
            params.Set("after", tostring(m_lastIdAwardedMaps));
        }

        params.Set("awardedby", m_user.Name);
        params.Set("order1", "24");

        string urlParams = MX::DictToApiParams(params);

        string url = "https://"+MXURL+"/api/maps" + urlParams;

        Logging::Debug("UserTab::AwardedMaps::StartRequest: " + url);
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
            int resCode = m_MXUserMapsAwardedRequest.ResponseCode();
            auto json = m_MXUserMapsAwardedRequest.Json();
            @m_MXUserMapsAwardedRequest = null;

            Logging::Debug("UserTab::AwardedMaps::CheckRequest (MX): " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results") || json["Results"].Length == 0) {
                Logging::Error("Error while loading maps list");
                return;
            }

            // Handle the response
            if (json.HasKey("title")) {
                m_awardedMapsError = true;
            } else {
                m_moreItemsAwardsGiven = json["More"];
                auto items = json["Results"];
                for (uint i = 0; i < items.Length; i++) {
                    m_mapsAwardsGiven.InsertLast(MX::MapInfo(items[i]));

                    if (m_moreItemsAwardsGiven && i == items.Length - 1) {
                        m_lastIdAwardedMaps = items[i]["MapId"];
                    }
                }
            }

            awardedWidths.Update(m_mapsAwardsGiven);
        }
    }

    void StartMXMapPacksRequest()
    {
        dictionary params;
        params.Set("fields", MX::mapPackFields);
        params.Set("count", "100");

        if (m_moreItemsMapPacks && m_lastIdMapPacks != 0) {
            params.Set("after", tostring(m_lastIdMapPacks));
        }

        params.Set("owneruserid", tostring(m_userId));
        params.Set("order1", "3");

        string urlParams = MX::DictToApiParams(params);

        string url = "https://"+MXURL+"/api/mappacks" + urlParams;

        Logging::Debug("UserTab::MapPacks::StartRequest: " + url);
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
            int resCode = m_MXUserMapPacksRequest.ResponseCode();
            auto json = m_MXUserMapPacksRequest.Json();
            @m_MXUserMapPacksRequest = null;

            Logging::Debug("UserTab::MapPacks::CheckRequest (MX): " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results") || json["Results"].Length == 0) {
                Logging::Error("Error while loading mappack list");
                return;
            }

            // Handle the response
            if (json.HasKey("title")) {
                m_mapPacksError = true;
            } else {
                m_moreItemsMapPacks = json["More"];
                auto items = json["Results"];
                for (uint i = 0; i < items.Length; i++) {
                    m_mapPacks.InsertLast(MX::MapPackInfo(items[i]));

                    if (m_moreItemsMapPacks && i == items.Length - 1) {
                        m_lastIdMapPacks = items[i]["MappackId"];
                    }
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
        UI::Text(m_user.Name);
        UI::PopFont();

        UI::SameLine();
        if (m_MXUserInfoRequest is null) {
            if (UI::Button(Icons::Refresh)) StartMXRequest();
            UI::SetItemTooltip("Refresh User info");
        } else {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass);
            UI::SetItemTooltip("Loading...");
        }

        auto img = Images::CachedFromURL("https://account.mania.exchange/account/avatar/"+m_userId);

        if (img.m_texture !is null){
            vec2 thumbSize = img.m_texture.GetSize();
            UI::Image(img.m_texture, vec2(
                width,
                thumbSize.y / (thumbSize.x / width)
            ));

            UI::MXThumbnailTooltip(img, 0.3);
        } else if (!img.m_error) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading Avatar...");
        } else if (img.m_unsupportedFormat) {
            UI::Text(Icons::FileImageO + " \\$zUnsupported file format WEBP");
        } else if (img.m_notFound) {
            UI::Text("\\$fc0"+Icons::ExclamationTriangle+" \\$Avatar not found");
        } else {
            UI::Text(Icons::Times+" \\$zError while loading avatar");
        }

        UI::Text(Icons::Calendar+ " \\$f77" + m_user.RegisteredAt);
        UI::SetItemTooltip("Registered");

        UI::Text(Icons::Map+ " \\$f77" + m_user.MapCount);
        UI::SetItemTooltip("Tracks created");

        UI::Text(Icons::Inbox+ " \\$f77" + m_user.MappackCount);
        UI::SetItemTooltip("Mappacks created");

        UI::Text(Icons::Trophy+ " \\$f77" + m_user.AwardsReceivedCount);
        UI::SetItemTooltip("Awards");

        UI::Text(Icons::Hashtag+ " \\$f77" + m_user.UserId);
        UI::SetItemTooltip("User ID");
        UI::SameLine();
        UI::TextDisabled(Icons::Clipboard);
        UI::SetItemTooltip("Click to copy to clipboard");
        if (UI::IsItemClicked()) {
            IO::SetClipboard(tostring(m_user.UserId));
            UI::ShowNotification(Icons::Clipboard + " User ID copied to clipboard");
        }

        if (UI::CyanButton(Icons::ExternalLink + " View on "+shortMXName)) OpenBrowserURL("https://"+MXURL+"/usershow/"+m_userId);
        if (m_isYourProfileTab && UI::PurpleButton(Icons::ExternalLink + " Manage your account")) OpenBrowserURL("https://account.mania.exchange/account");

        if (!m_isYourProfileTab && Setting_Tab_YourProfile_UserID == 0) {
            UI::Separator();
            UI::TextWrapped(Icons::InfoCircle + " Is this your profile?\nAdd your profile to easily get it from the tabs.");
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
            IfaceRender::MXComment(m_user.Bio);
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
                        auto featuredMapImg = Images::CachedFromURL("https://"+MXURL+"/mapimage/"+m_featuredMap.MapId+"/1?hq=true");

                        if (featuredMapImg.m_texture !is null){
                            vec2 thumbSize = featuredMapImg.m_texture.GetSize();
                            UI::Image(featuredMapImg.m_texture, vec2(
                                featuredMapwidth,
                                thumbSize.y / (thumbSize.x / featuredMapwidth)
                            ));

                            UI::MXThumbnailTooltip(featuredMapImg, 0.3);
                        } else if (!featuredMapImg.m_error) {
                            int HourGlassValue = Time::Stamp % 3;
                            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                            UI::Text(Hourglass + " Loading thumbnail...");
                        } else if (featuredMapImg.m_unsupportedFormat) {
                            UI::Text(Icons::FileImageO + " \\$zUnsupported file format WEBP");
                        } else if (featuredMapImg.m_notFound) {
                            UI::Text("\\$fc0"+Icons::ExclamationTriangle+" \\$Thumbnail not found");
                        } else {
                            UI::Text(Icons::Times+" \\$zError while loading thumbnail");
                        }
                        UI::EndChild();
                        UI::SetCursorPos(posTop + vec2(featuredMapwidth + 28, 20));
                        UI::BeginChild("UserFeaturedMapDescriptionChild");
                        UI::PushFont(g_fontHeader);
                        UI::Text(Text::OpenplanetFormatCodes(m_featuredMap.GbxMapName));
                        UI::PopFont();
                        if (m_featuredMap.AuthorComments.Length > 100) {
                            IfaceRender::MXComment(m_featuredMap.AuthorComments.SubStr(0, 100) + "...");
                        } else {
                            IfaceRender::MXComment(m_featuredMap.AuthorComments);
                        }
                        if (UI::Button(Icons::InfoCircle)) mxMenu.AddTab(MapTab(m_featuredMap.MapId), true);
                        UI::SameLine();
                        if (UI::GreenButton(Icons::Play)) {
                            if (UI::IsOverlayShown() && Setting_CloseOverlayOnLoad) UI::HideOverlay();
                            UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(m_featuredMap.GbxMapName) + "\\$z\\$s by " + m_featuredMap.Username);
                            MX::mapToLoad = m_featuredMap.MapId;
                        }
                        UI::EndChild();
                    }
                }
                UI::EndChild();
            }
            UI::EndTabItem();
        }

        // TODO not ready yet
        UI::BeginDisabled();
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
        UI::EndDisabled();
        UI::SetItemTooltip("\\$f00" + Icons::Times + "\\$z User leaderboards are not available yet");

        if (m_user.MapCount > 0 && UI::BeginTabItem(Icons::Map + " Created")) {
            UI::BeginChild("UserMapsCreatedChild");
            CheckMXCreatedMapsRequest();
            if (m_MXUserMapsCreatedRequest !is null && m_mapsCreated.Length == 0) {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Loading...");
            } else {
#if MP4
                int columns = 7;
#else
                int columns = 5;
#endif
                if (UI::BeginTable("CreatedMapsList", columns, UI::TableFlags::RowBg | UI::TableFlags::Hideable)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    PushTabStyle();
                    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthFixed, createdWidths.author);
#if MP4
                    UI::TableSetupColumn("Envi/Vehicle", UI::TableColumnFlags::WidthFixed, createdWidths.enviVehicle);
                    UI::TableSetColumnEnabled(2, repo == MP4mxRepos::Trackmania);
                    UI::TableSetupColumn("Title pack", UI::TableColumnFlags::WidthFixed, createdWidths.titlepack);
#endif
                    UI::TableSetupColumn("Style", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn(Icons::Trophy, UI::TableColumnFlags::WidthFixed);
                    UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);
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
                    if (m_MXUserMapsCreatedRequest !is null && m_moreItemsCreatedMaps) {
                        UI::TableNextRow();
                        UI::TableNextColumn();
                        UI::AlignTextToFramePadding();
                        UI::Text(Icons::HourglassEnd + " Loading...");
                    }
                    UI::EndTable();
                    if (m_MXUserMapsCreatedRequest is null && m_moreItemsCreatedMaps && UI::GreenButton("Load more")){
                        StartMXCreatedMapsRequest();
                    }
                }
            }
            UI::EndChild();
            UI::EndTabItem();
        }

        if (m_user.AwardsGivenCount > 0 && UI::BeginTabItem(Icons::Trophy + " Awarded")) {
            UI::BeginChild("UserMapsAwardedChild");
            CheckMXAwardedMapsRequest();
            if (m_MXUserMapsAwardedRequest !is null && m_mapsAwardsGiven.Length == 0) {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Loading...");
            } else {
#if MP4
                int columns = 7;
#else
                int columns = 5;
#endif
                if (UI::BeginTable("CreatedMapsList", columns, UI::TableFlags::RowBg | UI::TableFlags::Hideable)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    PushTabStyle();
                    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthFixed, awardedWidths.author);
#if MP4
                    UI::TableSetupColumn("Envi/Vehicle", UI::TableColumnFlags::WidthFixed, awardedWidths.enviVehicle);
                    UI::TableSetColumnEnabled(2, repo == MP4mxRepos::Trackmania);
                    UI::TableSetupColumn("Title pack", UI::TableColumnFlags::WidthFixed, awardedWidths.titlepack);
#endif
                    UI::TableSetupColumn("Style", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn(Icons::Trophy, UI::TableColumnFlags::WidthFixed);
                    UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);
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
                    if (m_MXUserMapsCreatedRequest !is null && m_moreItemsAwardsGiven) {
                        UI::TableNextRow();
                        UI::TableNextColumn();
                        UI::AlignTextToFramePadding();
                        UI::Text(Icons::HourglassEnd + " Loading...");
                    }
                    UI::EndTable();
                    if (m_MXUserMapsCreatedRequest is null && m_moreItemsAwardsGiven && UI::GreenButton("Load more")){
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
                if (UI::BeginTable("UserMapPacksList", 5, UI::TableFlags::RowBg)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    PushTabStyle();
                    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Tags", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Tracks", UI::TableColumnFlags::WidthFixed);
                    UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);
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
                    if (m_MXUserMapPacksRequest !is null && m_moreItemsMapPacks) {
                        UI::TableNextRow();
                        UI::TableNextColumn();
                        UI::AlignTextToFramePadding();
                        UI::Text(Icons::HourglassEnd + " Loading...");
                    }
                    UI::EndTable();
                    if (m_MXUserMapPacksRequest is null && m_moreItemsMapPacks && UI::GreenButton("Load more")){
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