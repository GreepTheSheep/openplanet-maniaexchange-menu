class UserTab : Tab
{
    Net::HttpRequest@ m_MXUserLeaderboardRequest;
    int m_userId;
    bool m_isYourProfileTab;
    MX::UserInfo@ m_user;
    bool m_error;

    MX::UserLeaderboard@ m_leaderboard;
    MX::LeaderboardSeason@ m_selectedLeaderboard = MX::LeaderboardSeason(-1, "Cumulative");
    bool m_leaderboardError;
    string m_leaderboardErrorMessage;

    UserTab(const int &in userId, bool yourProfile = false) {
        m_userId = userId;
        m_isYourProfileTab = yourProfile;
        startnew(CoroutineFunc(FetchUser));
    }

    UserTab(MX::UserInfo@ user) {
        @m_user = user;
        m_userId = user.UserId;
    }

    bool CanClose() override { return !m_isYourProfileTab; }

    string GetLabel() override {
        if (m_isYourProfileTab) {
            return Icons::User;
        }

        if (m_error) {
            return "\\$f00" + Icons::Times + "\\$z Error";
        }

        if (m_user is null) {
            return Icons::User + " Loading...";
        }

        return Icons::User + " " + m_user.Name;
    }

    string GetTooltip() override {
        if (m_isYourProfileTab) {
            return "Your profile";
        }

        return "";
    }

    vec4 GetColor() override {
        if (m_isYourProfileTab) {
            return vec4(0.75,0,0.27,1);
        }

        return vec4(0,0.5,1,1);
    }

    void FetchUser() {
        dictionary params;
        params.Set("fields", MX::userFields);
        params.Set("id", tostring(m_userId));
        string userUrlParams = MX::DictToApiParams(params);

        string url = MXURL + "/api/users" + userUrlParams;
        Logging::Debug("UserTab::StartRequest (MX): " + url);
        Net::HttpRequest@ req = API::Get(url);

        while (!req.Finished()) {
            yield();
        }

        int resCode = req.ResponseCode();
        auto json = req.Json();

        Logging::Debug("UserTab::CheckRequest (MX): " + req.String());

        if (resCode >400 || json.GetType() != Json::Type::Object || !json.HasKey("Results")) {
            Logging::Error("UserTab::CheckRequest (MX): Error parsing response");
            m_error = true;
            return;
        }
        
        if (json["Results"].Length == 0) {
            // This should be impossible
            Logging::Error("UserTab::CheckRequest (MX): Failed to find an user with ID " + m_userId);
            m_error = true;
            return;
        }

        @m_user = MX::UserInfo(json["Results"][0]);
    }

    void StartMXLeaderboardRequest() // TODO doesn't exist yet
    {
        string url = MXURL + "/api/leaderboard/season/" + m_selectedLeaderboard.SeasonID + "/user/" + m_userId;

        Logging::Debug("UserTab::Leaderboard::StartRequest: " + url);
        @m_MXUserLeaderboardRequest = API::Get(url);
    }

    void CheckMXLeaderboardRequest() // TODO change once leaderboards are released on 2.0
    {
        if (!MX::APIDown && m_leaderboard is null && !m_leaderboardError && m_MXUserLeaderboardRequest is null && UI::IsWindowAppearing()) {
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

    void Render() override
    {
        if (m_error) {
            UI::Text("\\$f00" + Icons::Times + " \\$zUser not found");
            return;
        }

        if (m_user is null) {
            UI::Text(Icons::AnimatedHourglass + " Loading...");
            return;
        }

        float width = UI::GetWindowSize().x*0.25;
        vec2 posTop = UI::GetCursorPos();

        UI::BeginChild("Summary", vec2(width,0));

        UI::PushFont(Fonts::BigBold);
        UI::Text(m_user.Name);
        UI::PopFont();

        auto img = Images::CachedFromURL("https://account.mania.exchange/account/avatar/"+m_userId);

        if (img.m_texture !is null) {
            vec2 thumbSize = img.m_texture.GetSize();
            UI::Image(img.m_texture, vec2(
                width,
                thumbSize.y / (thumbSize.x / width)
            ));

            UI::MXThumbnailTooltip(img, 0.3);
        } else if (!img.m_error) {
            UI::Text(Icons::AnimatedHourglass + " Loading Avatar...");
        } else if (img.m_notFound) {
            UI::Text("\\$fc0" + Icons::ExclamationTriangle + "\\$ Avatar not found");
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

        if (UI::CyanButton(Icons::ExternalLink + " View on "+shortMXName)) OpenBrowserURL(MXURL + "/usershow/"+m_userId);
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
            UI::Markdown(m_user.Bio);
            UI::EndChild();

            if (m_user.HasFeaturedMap) {
                UI::Separator();

                UI::BeginChild("UserFeaturdMapChild");

                UI::Text(pluginColor + Icons::Map + " \\$zFeatured Map:");

                if (m_user.FeaturedMap is null) {
                    if (m_user.FeaturedMapError) {
                        UI::Text("\\$f00" + Icons::Times + " \\$zError while loading featured map");
                    } else if (m_user.LoadingFeaturedMap) {
                        UI::Text(Icons::AnimatedHourglass + " Loading...");
                    } else if (!m_user.FetchedFeaturedMap) {
                        startnew(CoroutineFunc(m_user.FetchFeaturedMap));
                    }
                } else {
                    float featuredMapwidth = Display::GetWidth() * 0.10;

                    UI::BeginChild("UserFeaturedMapImageChild", vec2(featuredMapwidth + 20, 0));

                    auto featuredMapImg = Images::CachedFromURL(MXURL + "/mapimage/" + m_user.FeaturedMap.MapId + "/1?hq=true");

                    if (featuredMapImg.m_texture !is null) {
                        vec2 thumbSize = featuredMapImg.m_texture.GetSize();
                        UI::Image(featuredMapImg.m_texture, vec2(
                            featuredMapwidth,
                            thumbSize.y / (thumbSize.x / featuredMapwidth)
                        ));

                        UI::MXThumbnailTooltip(featuredMapImg, 0.3);
                    } else if (!featuredMapImg.m_error) {
                        UI::Text(Icons::AnimatedHourglass + " Loading thumbnail...");
                    } else if (featuredMapImg.m_notFound) {
                        UI::Text("\\$fc0" + Icons::ExclamationTriangle + "\\$ Thumbnail not found");
                    } else {
                        UI::Text(Icons::Times + "\\$z Error while loading thumbnail");
                    }

                    UI::EndChild();

                    UI::SetCursorPos(posTop + vec2(featuredMapwidth + 28, 20));

                    UI::BeginChild("UserFeaturedMapDescriptionChild");

                    UI::PushFont(Fonts::BigBold);
                    UI::Text(Text::OpenplanetFormatCodes(m_user.FeaturedMap.GbxMapName));
                    UI::PopFont();

                    if (m_user.FeaturedMap.AuthorComments.Length > 100) {
                        UI::Markdown(m_user.FeaturedMap.AuthorComments.SubStr(0, 100) + "...");
                    } else {
                        UI::Markdown(m_user.FeaturedMap.AuthorComments);
                    }

                    if (UI::Button(Icons::InfoCircle)) {
                        mxMenu.AddTab(MapTab(m_user.FeaturedMap), true);
                    }

                    UI::SameLine();

                    if (UI::GreenButton(Icons::Play)) {
                        UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(m_user.FeaturedMap.GbxMapName) + "\\$z\\$s by " + m_user.FeaturedMap.Username);
                        startnew(CoroutineFunc(m_user.FeaturedMap.PlayMap));
                    }

                    UI::EndChild();
                }

                UI::EndChild();
            }

            UI::EndTabItem();
        }

        // TODO not ready yet
        UI::BeginDisabled();

        if (UI::BeginTabItem(Icons::ListOl + " " + shortMXName + " Leaderboard")) {
            UI::BeginChild("UserLeaderboardChild");
            if (UI::BeginCombo("##Leaderboard", m_selectedLeaderboard.Name)) {
                for (uint i = 0; i < MX::m_leaderboardSeasons.Length; i++) {
                    if (UI::Selectable(MX::m_leaderboardSeasons[i].Name, m_selectedLeaderboard.SeasonID == MX::m_leaderboardSeasons[i].SeasonID)) {
                        @m_leaderboard = null;
                        m_leaderboardError = false;
                        m_leaderboardErrorMessage = "";
                        @m_selectedLeaderboard = MX::m_leaderboardSeasons[i];
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
                    UI::Text(Icons::AnimatedHourglass + " Loading...");
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

        UI::BeginDisabled(m_user.MapCount == 0);

        if (UI::BeginTabItem(Icons::Map + " Created (" + m_user.MapCount + ")")) {
            UI::BeginChild("UserMapsCreatedChild");

            if (m_user.CreatedMaps.IsEmpty()) {
                if (m_user.LoadingCreatedMaps) {
                    UI::Text(Icons::AnimatedHourglass + " Loading...");
                } else if (m_user.CreatedMapsError) {
                    UI::Text("\\$f00" + Icons::Times + "\\$z Error while loading created maps");
                } else if (!m_user.FetchedCreatedMaps) {
                    startnew(CoroutineFunc(m_user.FetchCreatedMaps));
                }
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
                    UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthFixed, m_user.createdWidths.author);
#if MP4
                    UI::TableSetupColumn("Envi/Vehicle", UI::TableColumnFlags::WidthFixed, m_user.createdWidths.enviVehicle);
                    UI::TableSetColumnEnabled(2, repo == MP4mxRepos::Trackmania);
                    UI::TableSetupColumn("Title pack", UI::TableColumnFlags::WidthFixed, m_user.createdWidths.titlepack);
#endif
                    UI::TableSetupColumn("Style", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn(Icons::Trophy, UI::TableColumnFlags::WidthFixed);
                    UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);
                    UI::TableHeadersRow();
                    PopTabStyle();

                    UI::ListClipper clipper(m_user.CreatedMaps.Length);

                    while (clipper.Step()) {
                        for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                            UI::PushID("ResMap"+i);
                            MX::MapInfo@ map = m_user.CreatedMaps[i];
                            IfaceRender::MapResult(map);
                            UI::PopID();
                        }
                    }

                    if (m_user.LoadingCreatedMaps && m_user.MoreCreatedItems) {
                        UI::TableNextRow();
                        UI::TableNextColumn();
                        UI::AlignTextToFramePadding();
                        UI::Text(Icons::HourglassEnd + " Loading...");
                    }

                    UI::EndTable();

                    if (!m_user.LoadingCreatedMaps && m_user.MoreCreatedItems && UI::GreenButton("Load more")) {
                        startnew(CoroutineFunc(m_user.LoadMoreCreated));
                    }
                }
            }

            UI::EndChild();
            UI::EndTabItem();
        }

        UI::EndDisabled();

        if (m_user.MapCount == 0) {
            UI::SetItemTooltip("User has not uploaded maps to " + pluginName);
        }

        UI::BeginDisabled(m_user.AwardsGivenCount == 0);

        if (UI::BeginTabItem(Icons::Trophy + " Awarded (" + m_user.AwardsGivenCount + ")")) {
            UI::BeginChild("UserMapsAwardedChild");

            if (m_user.AwardedMaps.IsEmpty()) {
                if (m_user.LoadingAwardedMaps) {
                    UI::Text(Icons::AnimatedHourglass + " Loading...");
                } else if (m_user.AwardedMapsError) {
                    UI::Text("\\$f00" + Icons::Times + "\\$z Error while loading awarded maps");
                } else if (!m_user.FetchedAwardedMaps) {
                    startnew(CoroutineFunc(m_user.FetchAwardedMaps));
                }
            } else {
#if MP4
                int columns = 7;
#else
                int columns = 5;
#endif
                if (UI::BeginTable("AwardedMapsList", columns, UI::TableFlags::RowBg | UI::TableFlags::Hideable)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    PushTabStyle();
                    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthFixed, m_user.awardedWidths.author);
#if MP4
                    UI::TableSetupColumn("Envi/Vehicle", UI::TableColumnFlags::WidthFixed, m_user.awardedWidths.enviVehicle);
                    UI::TableSetColumnEnabled(2, repo == MP4mxRepos::Trackmania);
                    UI::TableSetupColumn("Title pack", UI::TableColumnFlags::WidthFixed, m_user.awardedWidths.titlepack);
#endif
                    UI::TableSetupColumn("Style", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn(Icons::Trophy, UI::TableColumnFlags::WidthFixed);
                    UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);
                    UI::TableHeadersRow();
                    PopTabStyle();

                    UI::ListClipper clipper(m_user.AwardedMaps.Length);

                    while (clipper.Step()) {
                        for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                            UI::PushID("ResMap"+i);
                            MX::MapInfo@ map = m_user.AwardedMaps[i];
                            IfaceRender::MapResult(map);
                            UI::PopID();
                        }
                    }

                    if (m_user.LoadingAwardedMaps && m_user.MoreAwardedItems) {
                        UI::TableNextRow();
                        UI::TableNextColumn();
                        UI::AlignTextToFramePadding();
                        UI::Text(Icons::HourglassEnd + " Loading...");
                    }

                    UI::EndTable();

                    if (!m_user.LoadingAwardedMaps && m_user.MoreAwardedItems && UI::GreenButton("Load more")) {
                        startnew(CoroutineFunc(m_user.LoadMoreAwarded));
                    }
                }
            }

            UI::EndChild();
            UI::EndTabItem();
        }

        UI::EndDisabled();

        if (m_user.AwardsGivenCount == 0) {
            UI::SetItemTooltip("Users has not awarded any maps on " + pluginName);
        }

        UI::BeginDisabled(m_user.MappackCount == 0);

        if (UI::BeginTabItem(Icons::Inbox + " Map Packs (" + m_user.MappackCount + ")")) {
            UI::BeginChild("UserMapPacksChild");

            if (m_user.Mappacks.IsEmpty()) {
                if (m_user.LoadingMappacks) {
                    UI::Text(Icons::AnimatedHourglass + " Loading...");
                } else if (m_user.MappacksError) {
                    UI::Text("\\$f00" + Icons::Times + "\\$z Error while loading mappacks");
                } else if (!m_user.FetchedMappacks) {
                    startnew(CoroutineFunc(m_user.FetchMappacks));
                }
            } else if (UI::BeginTable("UserMapPacksList", 5, UI::TableFlags::RowBg)) {
                UI::TableSetupScrollFreeze(0, 1);
                PushTabStyle();
                UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Tags", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Tracks", UI::TableColumnFlags::WidthFixed);
                UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);
                UI::TableHeadersRow();
                PopTabStyle();

                UI::ListClipper clipper(m_user.Mappacks.Length);

                while (clipper.Step()) {
                    for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                        UI::PushID("ResMap"+i);
                        MX::MapPackInfo@ mapPack = m_user.Mappacks[i];
                        IfaceRender::MapPackResult(mapPack);
                        UI::PopID();
                    }
                }

                if (m_user.LoadingMappacks && m_user.MoreMappacksItems) {
                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::AlignTextToFramePadding();
                    UI::Text(Icons::HourglassEnd + " Loading...");
                }

                UI::EndTable();

                if (!m_user.LoadingMappacks && m_user.MoreMappacksItems && UI::GreenButton("Load more")) {
                    startnew(CoroutineFunc(m_user.LoadMoreMappacks));
                }
            }

            UI::EndChild();
            UI::EndTabItem();
        }

        UI::EndDisabled();

        if (m_user.MappackCount == 0) {
            UI::SetItemTooltip("User hasn't created any mappacks on " + pluginName);
        }

        UI::EndTabBar();

        UI::EndChild();
    }
}