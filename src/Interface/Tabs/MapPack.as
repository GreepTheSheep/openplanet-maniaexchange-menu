class MapPackTab : Tab
{
    MX::MapPackInfo@ m_mapPack;
    int m_mapPackId;
    bool m_error;
    string m_errorMessage;

    MapPackTab(int packId) {
        m_mapPackId = packId;
        startnew(CoroutineFunc(FetchMappack));
    }

    MapPackTab(MX::MapPackInfo@ mapPack) {
        @m_mapPack = mapPack;
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

    void FetchMappack() {
        dictionary params;
        GetRequestParams(params);
        string urlParams = MX::DictToApiParams(params);

        string url = MXURL + "/api/mappacks" + urlParams;
        Logging::Debug("MapPackTab::StartRequest (MX): " + url);
        Net::HttpRequest@ req = API::Get(url);

        while (!req.Finished()) {
            yield();
        }

        int resCode = req.ResponseCode();
        auto json = req.Json();

        Logging::Debug("MapPackTab::CheckRequest (MX): " + req.String());

        if (resCode >= 400) {
            string errorMsg = json.Get("title", "Unknown error");
            Logging::Error("MapPackTab::CheckRequest (MX): Error " + resCode + " - " + errorMsg);
            m_error = true;
            m_errorMessage = errorMsg;
            return;
        }

        if (json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
            Logging::Error("MapPackTab::CheckRequest (MX): Error while loading mappack");
            m_error = true;
            m_errorMessage = "Empty response";
            return;
        }
        
        if (json["Results"].Length == 0) {
            // This should be impossible
            Logging::Error("MapPackTab::CheckRequest (MX): Failed to find a mappack with ID " + m_mapPackId);
            m_error = true;
            m_errorMessage = "Failed to find mappack";
            return;
        }

        @m_mapPack = MX::MapPackInfo(json);

        startnew(CoroutineFunc(m_mapPack.FetchMaps));
    }

    void Render() override
    {
        if (m_error) {
            UI::Text("\\$f00" + Icons::Times + " \\$z" + m_errorMessage);
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
            if (m_mapPack.Tags.Length > 1 && i > 0) {
                float tagWidth = UI::MeasureButton(m_mapPack.Tags[i].Name).x;

                if (tagWidth >= UI::GetContentRegionAvail().x) {
                    UI::NewLine();
                }
            }

            IfaceRender::MapTag(m_mapPack.Tags[i]);
            UI::SameLine();
        }
        UI::NewLine();

        if (!m_mapPack.IsPublic) {
            UI::Text(Icons::Times + " \\$f77Unreleased");
        }

        UI::Text(Icons::ThList + " \\$f77" + m_mapPack.TypeName);
        UI::SetItemTooltip("MapPack Type");

#if MP4
        if (repo == MP4mxRepos::Trackmania) {
#endif
            UI::Text(Icons::Tree + " \\$f77" + m_mapPack.EnvironmentName);
            UI::SetItemTooltip("Environment");
#if MP4
        }
#endif

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

        if (UI::BeginTabItem("Maps (" + m_mapPack.MapCount + ")")) {
            UI::BeginChild("MapListChild");

            if (m_mapPack.ListError) {
                UI::Text("\\$f00" + Icons::Times + " \\$zError while loading mappack map list.");
            } else if (m_mapPack.MapCount == 0) {
                UI::Text("Map list for this pack is empty.");
            } else if (m_mapPack.Loading && m_mapPack.Maps.IsEmpty()) {
                UI::Text(Icons::AnimatedHourglass + " Loading...");
            } else {
                float scale = UI::GetScale();

                if (UI::BeginTable("List", 13, UI::TableFlags::RowBg | UI::TableFlags::Hideable)) {
                    UI::TableSetupScrollFreeze(0, 1);
                    PushTabStyle();
                    UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Author", UI::TableColumnFlags::WidthFixed, m_mapPack.columnWidths.author);
#if TMNEXT
                    UI::TableSetupColumn("Vista", UI::TableColumnFlags::WidthFixed, m_mapPack.columnWidths.environment);
#else
                    UI::TableSetupColumn("Env.", UI::TableColumnFlags::WidthFixed, m_mapPack.columnWidths.environment);
#endif
                    UI::TableSetupColumn("Vehicle", UI::TableColumnFlags::WidthFixed, m_mapPack.columnWidths.vehicle);
                    UI::TableSetupColumn("Type", UI::TableColumnFlags::WidthFixed, 60 * scale);
                    UI::TableSetupColumn("Title pack", UI::TableColumnFlags::WidthFixed, m_mapPack.columnWidths.titlepack);
                    UI::TableSetupColumn("Tags", UI::TableColumnFlags::WidthStretch);
                    UI::TableSetupColumn("Length", UI::TableColumnFlags::WidthFixed, m_mapPack.columnWidths.length);
                    UI::TableSetupColumn("Difficulty", UI::TableColumnFlags::WidthFixed);
                    UI::TableSetupColumn(Icons::Trophy, UI::TableColumnFlags::WidthFixed);
#if TMNEXT
                    UI::TableSetupColumn("Records", UI::TableColumnFlags::WidthFixed, 40 * scale);
#else
                    UI::TableSetupColumn("Replays", UI::TableColumnFlags::WidthFixed, 40 * scale);
#endif
                    UI::TableSetupColumn("", UI::TableColumnFlags::WidthFixed, 15 * scale);
                    UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed);
                    UI::TableHeadersRow();
                    PopTabStyle();

                    UI::TableSetColumnEnabled(0, Setting_MapName);
                    UI::TableSetColumnEnabled(1, Setting_MapAuthor);
                    UI::TableSetColumnEnabled(2, Setting_MapEnvironment && repo == MP4mxRepos::Trackmania);
                    UI::TableSetColumnEnabled(3, Setting_MapVehicle && repo == MP4mxRepos::Trackmania);
                    UI::TableSetColumnEnabled(4, Setting_MapType);
                    UI::TableSetColumnEnabled(5, Setting_MapTitlepack);
                    UI::TableSetColumnEnabled(6, Setting_MapTags);
                    UI::TableSetColumnEnabled(7, Setting_MapLength && repo == MP4mxRepos::Trackmania);
                    UI::TableSetColumnEnabled(8, Setting_MapDifficulty);
                    UI::TableSetColumnEnabled(9, Setting_MapAwards);
                    UI::TableSetColumnEnabled(10, Setting_MapRecordCount && repo == MP4mxRepos::Trackmania);
                    UI::TableSetColumnEnabled(11, Setting_MapAtStatus && repo == MP4mxRepos::Trackmania);

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