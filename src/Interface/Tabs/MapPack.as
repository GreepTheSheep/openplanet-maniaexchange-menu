array<MX::MapInfo@> mapPack_maps;

class MapPackTab : Tab
{
    Net::HttpRequest@ m_MXrequest;
    Net::HttpRequest@ m_MXMapsRequest;
    MX::MapPackInfo@ m_mapPack;

    int m_mapPackId;
    int m_lastIdMapList = 0;
    bool m_moreItemsMapList = false;
    bool m_isLoading = false;
    bool m_error = false;
    bool m_mapListError = false;
    string m_errorMessage = "";
    bool m_mapDownloaded = false;

    UI::Font@ g_fontHeader;

    MapPackTab(int packId) {
        @g_fontHeader = UI::LoadFont("DroidSans-Bold.ttf", 24);
        mapPack_maps.RemoveRange(0, mapPack_maps.Length);
        m_mapPackId = packId;
        StartMXRequest();
    }

    bool CanClose() override { return !m_isLoading; }

    string GetLabel() override {
        if (m_error) {
            m_isLoading = false;
            return "\\$f00"+Icons::Times+" \\$zError";
        }
        if (m_mapPack is null) {
            m_isLoading = true;
            return Icons::Inbox+" Loading...";
        } else {
            m_isLoading = false;
            string res = Icons::Inbox+" ";
            res += m_mapPack.Name;
            return res;
        }
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

        string url = "https://"+MXURL+"/api/mappacks" + urlParams;
        if (isDevMode) trace("MapPackTab::StartRequest (MX): "+url);
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

            if (isDevMode) trace("MapPackTab::CheckRequest (MX): " + res);

            if (resCode >= 400) {
                string errorMsg = json.Get("title", "Unknown error");
                HandleMXResponseError(errorMsg);
                return;
            }

            if (json.GetType() == Json::Type::Null || !json.HasKey("Results") || json["Results"].Length == 0) {
                HandleMXResponseError("Empty response");
                return;
            }
            StartMXMapListRequest();
            // Handle the response
            HandleMXResponse(json["Results"][0]);
        }
    }

    void HandleMXResponse(const Json::Value &in json)
    {
        @m_mapPack = MX::MapPackInfo(json);
    }

    void HandleMXResponseError(const string &in errorMessage = "")
    {
        print("MapPackTab::CheckRequest (MX): Error parsing response");
        m_error = true;
        m_errorMessage = errorMessage;
    }

    void StartMXMapListRequest()
    {
        dictionary mapParams;
        mapParams.Set("fields", MX::mapFields);
        mapParams.Set("mappackid", tostring(m_mapPackId));

        if (m_moreItemsMapList && m_lastIdMapList != 0) {
            mapParams.Set("after", tostring(m_lastIdMapList));
        }

        string mapUrlParams = MX::DictToApiParams(mapParams);

        string url = "https://"+MXURL+"/api/maps" + mapUrlParams;
        if (isDevMode) trace("MapPackTab::StartRequest (Map List): "+url);
        @m_MXMapsRequest = API::Get(url);
    }

    void CheckMXMapListRequest()
    {
        // If there's a request, check if it has finished
        if (m_MXMapsRequest !is null && m_MXMapsRequest.Finished()) {
            // Parse the response
            string res = m_MXMapsRequest.String();
            int resCode = m_MXMapsRequest.ResponseCode();
            auto json = m_MXMapsRequest.Json();
            @m_MXMapsRequest = null;

            if (isDevMode) trace("MapPackTab::CheckRequest (Map List): " + res);

            if (resCode >= 400 || json.GetType() == Json::Type::Null || !json.HasKey("Results") || json["Results"].Length == 0) {
                print("MapPackTab::CheckRequest (Map List): Error parsing response");
                HandleMXMapListResponseError();
                return;
            }
            // Handle the response
            m_moreItemsMapList = json["More"];
            HandleMXMapListResponse(json["Results"]);
        }
    }

    void HandleMXMapListResponse(const Json::Value &in json)
    {
        for (uint i = 0; i < json.Length; i++) {
            MX::MapInfo@ map = MX::MapInfo(json[i]);
            map.MapPackName = m_mapPack.Name;
            mapPack_maps.InsertLast(map);

            if (m_moreItemsMapList && i == json.Length - 1) {
                m_lastIdMapList = json[i]["MapId"];
            }
        }
    }

    void HandleMXMapListResponseError()
    {
        m_mapListError = true;
    }

    void Render() override
    {
        CheckMXRequest();

        if (m_error) {
            UI::Text("\\$f00" + Icons::Times + " \\$z"+m_errorMessage);
            return;
        }

        if (m_mapPack is null) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
            return;
        }

        CheckMXMapListRequest();

        float width = UI::GetWindowSize().x*0.35;
        vec2 posTop = UI::GetCursorPos();

        UI::BeginChild("Summary", vec2(width,0));

        auto thumb = Images::CachedFromURL("https://"+MXURL+"/mappackthumb/"+m_mapPack.MappackId);
        if (thumb.m_texture !is null){
            vec2 thumbSize = thumb.m_texture.GetSize();
            UI::Image(thumb.m_texture, vec2(
                width,
                thumbSize.y / (thumbSize.x / width)
            ));
            if (UI::IsItemHovered()) {
                UI::BeginTooltip();
                UI::Image(thumb.m_texture, vec2(
                    Draw::GetWidth() * 0.6,
                    thumbSize.y / (thumbSize.x / (Draw::GetWidth() * 0.6))
                ));
                UI::EndTooltip();
            }
        }

        for (uint i = 0; i < m_mapPack.Tags.Length; i++) {
            IfaceRender::MapTag(m_mapPack.Tags[i]);
            UI::SameLine();
        }
        UI::NewLine();

        if (!m_mapPack.IsPublic) UI::Text(Icons::Times + " \\$f77Unreleased");
        UI::Text(Icons::ThList + " \\$f77" + m_mapPack.TypeName);
        UI::SetPreviousTooltip("MapPack Type");
        UI::Text(Icons::ListOl + " \\$f77" + m_mapPack.MapCount);
        UI::SetPreviousTooltip("Track Count");

        UI::Text(Icons::Hashtag + " \\$f77" + m_mapPack.MappackId);
        UI::SetPreviousTooltip("MapPack ID");
        UI::SameLine();
        UI::TextDisabled(Icons::Clipboard);
        UI::SetPreviousTooltip("Click to copy to clipboard");
        if (UI::IsItemClicked()) {
            IO::SetClipboard(tostring(m_mapPack.MappackId));
            UI::ShowNotification(Icons::Clipboard + " Map pack ID copied to clipboard");
        }

        if (m_mapPack.IsRequest) UI::Text(Icons::HandPeaceO+ " \\$f77Open for requests!");
        UI::Text(Icons::Calendar + " \\$f77" + m_mapPack.CreatedAt);
        UI::SetPreviousTooltip("Created date");
        if (m_mapPack.CreatedAt != m_mapPack.UpdatedAt) {
            UI::Text(Icons::Refresh + " \\$f77" + m_mapPack.UpdatedAt);
            UI::SetPreviousTooltip("Edited date");
        }

        if (UI::CyanButton(Icons::ExternalLink + " View on "+pluginName)) OpenBrowserURL("https://"+MXURL+"/mappackshow/"+m_mapPack.MappackId);

#if TMNEXT
        if (!m_mapListError && mapPack_maps.Length != 0 && Permissions::PlayLocalMap() && UI::GreenButton(Icons::Check + " Add to Play later")) {
#else
        if (!m_mapListError && mapPack_maps.Length != 0 && UI::GreenButton(Icons::Check + " Add to Play later")) {
#endif
            Renderables::Add(MapPackActionWarn(MapPackActions::AddPlayLater, mapPack_maps));
        }

        if (MX::mapDownloadInProgress){
            UI::Text("\\$f70" + Icons::Download + " \\$zDownloading maps...");
            m_isLoading = true;
        } else {
            m_isLoading = false;
            if (!m_mapDownloaded) {
                if (!m_mapListError && mapPack_maps.Length != 0 && UI::PurpleButton(Icons::Download + " Download Pack")) {
                    Renderables::Add(MapPackActionWarn(MapPackActions::Download, mapPack_maps));
                }
            } else {
                UI::Text("\\$0f0" + Icons::Download + " \\$zMap pack downloaded");
                if (UI::RoseButton(Icons::FolderOpen + " Open Containing Folder")) OpenExplorerPath(IO::FromUserGameFolder("Maps/Downloaded/"+pluginName));
            }
        }

        UI::EndChild();

        UI::SetCursorPos(posTop + vec2(width + 8, 0));
        UI::BeginChild("Description");

        UI::PushFont(g_fontHeader);
        UI::Text(m_mapPack.Name);
        UI::PopFont();

        UI::TextDisabled("By " + m_mapPack.Username);
        UI::SetPreviousTooltip("Click to view "+m_mapPack.Username+"'s profile");
        if (UI::IsItemClicked()) mxMenu.AddTab(UserTab(m_mapPack.UserId), true);

        UI::Separator();

        UI::BeginTabBar("MapPackTabs");

        if(UI::BeginTabItem("Description")){
            UI::BeginChild("MapPackDescriptionChild");
            IfaceRender::MXComment(m_mapPack.Description);
            UI::EndChild();
            UI::EndTabItem();
        }
        if(UI::BeginTabItem("Maps")){
            UI::BeginChild("MapListChild");

            if (m_mapListError) {
                UI::Text("\\$f00" + Icons::Times + " \\$zMap list for this pack is empty.");
            } else {
                if (mapPack_maps.Length == 0) {
                    int HourGlassValue = Time::Stamp % 3;
                    string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                    UI::Text(Hourglass + " Loading...");
                } else {
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

                        UI::ListClipper clipper(mapPack_maps.Length);
                        while(clipper.Step()) {
                            for(int j = clipper.DisplayStart; j < clipper.DisplayEnd; j++)
                            {
                                UI::PushID("ResMap"+j);
                                MX::MapInfo@ map = mapPack_maps[j];
                                IfaceRender::MapResult(map);
                                UI::PopID();
                            }
                        }

                        if (m_MXMapsRequest !is null && m_moreItemsMapList) {
                            UI::TableNextRow();
                            UI::TableSetColumnIndex(0);
                            UI::AlignTextToFramePadding();
                            UI::Text(Icons::HourglassEnd + " Loading...");
                        }

                        UI::EndTable();

                        if (m_MXMapsRequest is null && m_moreItemsMapList && UI::GreenButton("Load more")) {
                            StartMXMapListRequest();
                        }
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