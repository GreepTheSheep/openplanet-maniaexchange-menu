class MapPackTab : Tab
{
    Net::HttpRequest@ m_MXrequest;
    MX::MapPackInfo@ m_mapPack;
    int m_mapPackId;
    bool m_error = false;
    string m_errorMessage;

    MapPackTab(int packId) {
        m_mapPackId = packId;
        StartMXRequest();
    }

    MapPackTab(MX::MapPackInfo@ mapPack) {
        @m_mapPack = mapPack;
        m_mapPackId = mapPack.MappackId;
        startnew(CoroutineFunc(m_mapPack.FetchMaps));
    }

    bool CanClose() override { return m_mapPack !is null || m_error; }

    string GetLabel() override {
        if (m_error) {
            return "\\$f00" + Icons::Times + " \\$zError";
        }

        if (m_mapPack is null) {
            return Icons::Inbox + " Loading...";
        }

        return Icons::Inbox + " " + m_mapPack.Name;
    }

    void GetRequestParams(dictionary@ params)
    {
        params.Set("fields", MX::mapPackFields);
        params.Set("id", tostring(m_mapPackId));
    }

    void StartMXRequest()
    {
        dictionary params;
        GetRequestParams(params);
        string urlParams = MX::DictToApiParams(params);

        string url = MXURL + "/api/mappacks" + urlParams;
        Logging::Debug("MapPackTab::StartRequest (MX): "+url);
        @m_MXrequest = API::Get(url);
    }

    void CheckMXRequest()
    {
        // If there's a request, check if it has finished
        if (m_MXrequest !is null && m_MXrequest.Finished()) {
            // Parse the response
            string res = m_MXrequest.String();
            int resCode = m_MXrequest.ResponseCode();
            auto json = m_MXrequest.Json();
            @m_MXrequest = null;

            Logging::Debug("MapPackTab::CheckRequest (MX): " + res);

            if (resCode >= 400) {
                string errorMsg = json.Get("title", "Unknown error");
                Logging::Error("MapPackTab::CheckRequest (MX): Error " + resCode + " - " + errorMsg);
                HandleMXResponseError(errorMsg);
                return;
            }

            if (json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
                Logging::Error("MapPackTab::CheckRequest (MX): Error while loading mappack");
                HandleMXResponseError("Empty response");
                return;
            } else if (json["Results"].Length == 0) {
                // This should be impossible
                Logging::Error("MapPackTab::CheckRequest (MX): Failed to find a mappack with ID " + m_mapPackId);
                HandleMXResponseError("Failed to find mappack");
                return;
            }

            @m_mapPack = MX::MapPackInfo(json);

            startnew(CoroutineFunc(m_mapPack.FetchMaps));
        }
    }

    void HandleMXResponseError(const string &in errorMessage = "")
    {
        m_error = true;
        m_errorMessage = errorMessage;
    }

    void Render() override
    {
        CheckMXRequest();

        if (m_error) {
            UI::Text("\\$f00" + Icons::Times + " \\$z"+m_errorMessage);
            return;
        }

        if (m_mapPack is null) {
            UI::Text(Icons::AnimatedHourglass + " Loading...");
            return;
        }

        float width = UI::GetWindowSize().x*0.3;
        vec2 posTop = UI::GetCursorPos();

        UI::BeginChild("Summary", vec2(width,0));

        auto thumb = Images::CachedFromURL(MXURL + "/mappackthumb/"+m_mapPack.MappackId);
        if (thumb.m_texture !is null) {
            vec2 thumbSize = thumb.m_texture.GetSize();
            UI::Image(thumb.m_texture, vec2(
                width,
                thumbSize.y / (thumbSize.x / width)
            ));

            UI::MXThumbnailTooltip(thumb, 0.3);
        }

        for (uint i = 0; i < m_mapPack.Tags.Length; i++) {
            IfaceRender::MapTag(m_mapPack.Tags[i]);
            UI::SameLine();
        }
        UI::NewLine();

        if (!m_mapPack.IsPublic) UI::Text(Icons::Times + " \\$f77Unreleased");
        UI::Text(Icons::ThList + " \\$f77" + m_mapPack.TypeName);
        UI::SetItemTooltip("MapPack Type");
        UI::Text(Icons::ListOl + " \\$f77" + m_mapPack.MapCount);
        UI::SetItemTooltip("Track Count");

        UI::Text(Icons::Hashtag + " \\$f77" + m_mapPack.MappackId);
        UI::SetItemTooltip("MapPack ID");
        UI::SameLine();
        UI::TextDisabled(Icons::Clipboard);
        UI::SetItemTooltip("Click to copy to clipboard");
        if (UI::IsItemClicked()) {
            IO::SetClipboard(tostring(m_mapPack.MappackId));
            UI::ShowNotification(Icons::Clipboard + " Map pack ID copied to clipboard");
        }

        if (m_mapPack.IsRequest) UI::Text(Icons::HandPeaceO+ " \\$f77Open for requests!");
        UI::Text(Icons::Calendar + " \\$f77" + m_mapPack.CreatedAt);
        UI::SetItemTooltip("Created date");
        if (m_mapPack.CreatedAt != m_mapPack.UpdatedAt) {
            UI::Text(Icons::Refresh + " \\$f77" + m_mapPack.UpdatedAt);
            UI::SetItemTooltip("Edited date");
        }

        if (UI::CyanButton(Icons::ExternalLink + " View on " + pluginName)) {
            OpenBrowserURL(MXURL + "/mappackshow/" + m_mapPack.MappackId);
        }

        UI::BeginDisabled(m_mapPack.MapCount == 0);

        if (UI::GreenButton(Icons::Check + " Add to Play later")) {
            Renderables::Add(MapPackActionWarn(MapPackActions::AddPlayLater, m_mapPack));
        }

        if (m_mapPack.Downloaded) {
            UI::Text("\\$0f0" + Icons::CheckCircle + " \\$zMappack downloaded");

            if (UI::RoseButton(Icons::FolderOpen + " Open Containing Folder")) {
                OpenExplorerPath(DownloadsFolder);
            }
        } else if (m_mapPack.Downloading) {
            UI::Text(Icons::AnimatedHourglass + " Downloading maps...");
        } else if (UI::PurpleButton(Icons::Download + " Download Pack")) {
            Renderables::Add(MapPackActionWarn(MapPackActions::Download, m_mapPack));
        }

        UI::EndDisabled();

        UI::EndChild();

        UI::SetCursorPos(posTop + vec2(width + 8, 0));
        UI::BeginChild("Description");

        UI::PushFont(Fonts::BigBold);
        UI::Text(m_mapPack.Name);
        UI::PopFont();

        UI::TextDisabled("By " + m_mapPack.Username);
        UI::SetItemTooltip("Click to view "+m_mapPack.Username+"'s profile");
        if (UI::IsItemClicked()) mxMenu.AddTab(UserTab(m_mapPack.UserId), true);

        UI::Separator();

        UI::BeginTabBar("MapPackTabs");

        if (UI::BeginTabItem("Description")) {
            UI::BeginChild("MapPackDescriptionChild");
            UI::Markdown(m_mapPack.Description);
            UI::EndChild();
            UI::EndTabItem();
        }
        if (UI::BeginTabItem("Maps")) {
            UI::BeginChild("MapListChild");

            if (m_mapPack.ListError) {
                UI::Text("\\$f00" + Icons::Times + " \\$zError while loading mappack map list.");
            } else if (m_mapPack.MapCount == 0) {
                UI::Text("Map list for this pack is empty.");
            } else if (m_mapPack.Loading && m_mapPack.Maps.IsEmpty()) {
                UI::Text(Icons::AnimatedHourglass + " Loading...");
            } else {
#if MP4
                int columns = 7;
#else
                int columns = 5;
#endif
                if (UI::BeginTable("List", columns, UI::TableFlags::RowBg | UI::TableFlags::Hideable)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    PushTabStyle();
                    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthFixed, m_mapPack.columnWidths.author);
#if MP4
                    UI::TableSetupColumn("Envi/Vehicle", UI::TableColumnFlags::WidthFixed, m_mapPack.columnWidths.enviVehicle);
                    UI::TableSetColumnEnabled(2, repo == MP4mxRepos::Trackmania);
                    UI::TableSetupColumn("Title pack", UI::TableColumnFlags::WidthFixed, m_mapPack.columnWidths.titlepack);
#endif
                    UI::TableSetupColumn("Style", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn(Icons::Trophy, UI::TableColumnFlags::WidthFixed);
                    UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);
                    UI::TableHeadersRow();
                    PopTabStyle();

                    UI::ListClipper clipper(m_mapPack.Maps.Length);
                    while (clipper.Step()) {
                        for (int j = clipper.DisplayStart; j < clipper.DisplayEnd; j++) {
                            UI::PushID("ResMap"+j);
                            MX::MapInfo@ map = m_mapPack.Maps[j];
                            IfaceRender::MapResult(map);
                            UI::PopID();
                        }
                    }

                    if (m_mapPack.Loading && m_mapPack.MoreMaps) {
                        UI::TableNextRow();
                        UI::TableNextColumn();
                        UI::AlignTextToFramePadding();
                        UI::Text(Icons::HourglassEnd + " Loading...");
                    }

                    UI::EndTable();

                    if (!m_mapPack.Loading && m_mapPack.MoreMaps && UI::GreenButton("Load more")) {
                        startnew(CoroutineFunc(m_mapPack.LoadMore));
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