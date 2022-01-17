array<MX::MapInfo@> mapPack_maps;

class MapPackTab : Tab
{
    Net::HttpRequest@ m_MXrequest;
    Net::HttpRequest@ m_MXMapsRequest;
    MX::MapPackInfo@ m_mapPack;

    int m_mapPackId;
    bool m_isLoading = false;
    bool m_error = false;
    bool m_mapListError = false;

    Resources::Font@ g_fontHeader = Resources::GetFont("DroidSans-Bold.ttf", 24);

    MapPackTab(int packId) {
        mapPack_maps.RemoveRange(0, mapPack_maps.get_Length());
        m_mapPackId = packId;
        StartMXRequest(m_mapPackId);
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

    void StartMXRequest(int packId)
    {
        string url = "https://"+MXURL+"/api/mappack/get_info/"+packId;
        if (IsDevMode()) trace("MapPackTab::StartRequest (MX): "+url);
        @m_MXrequest = API::Get(url);
    }

    void CheckMXRequest()
    {
        // If there's a request, check if it has finished
        if (m_MXrequest !is null && m_MXrequest.Finished()) {
            // Parse the response
            string res = m_MXrequest.String();
            if (IsDevMode()) trace("MapPackTab::CheckRequest (MX): " + res);
            @m_MXrequest = null;
            auto json = Json::Parse(res);

            if (json.get_Length() == 0) {
                print("MapPackTab::CheckRequest (MX): Error parsing response");
                HandleMXResponseError();
                return;
            }
            StartMXMapListRequest(m_mapPackId);
            // Handle the response
            HandleMXResponse(json);
        }
    }

    void HandleMXResponse(const Json::Value &in json)
    {
        @m_mapPack = MX::MapPackInfo(json);
    }

    void HandleMXResponseError()
    {
        m_error = true;
    }

    void StartMXMapListRequest(int packId)
    {
        string url = "https://"+MXURL+"/api/mappack/get_mappack_tracks/"+packId;
        if (IsDevMode()) trace("MapPackTab::StartRequest (Map List): "+url);
        @m_MXMapsRequest = API::Get(url);
    }

    void CheckMXMapListRequest()
    {
        // If there's a request, check if it has finished
        if (m_MXMapsRequest !is null && m_MXMapsRequest.Finished()) {
            // Parse the response
            string res = m_MXMapsRequest.String();
            if (IsDevMode()) trace("MapPackTab::CheckRequest (Map List): " + res);
            @m_MXMapsRequest = null;
            auto json = Json::Parse(res);

            if (json.get_Length() == 0) {
                print("MapPackTab::CheckRequest (Map List): Error parsing response");
                HandleMXMapListResponseError();
                return;
            }
            // Handle the response
            HandleMXMapListResponse(json);
        }
    }

    void HandleMXMapListResponse(const Json::Value &in json)
    {
        for (uint i = 0; i < json.get_Length(); i++) {
            mapPack_maps.InsertLast(MX::MapInfo(json[i]));
        }
    }

    void HandleMXMapListResponseError()
    {
        m_mapListError = true;
    }

    void Render() override
    {
        CheckMXRequest();
        CheckMXMapListRequest();

        if (m_error) {
            UI::Text("\\$f00" + Icons::Times + " \\$zMap Pack not found");
            return;
        }

        if (m_mapPack is null) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
            return;
        }

        float width = UI::GetWindowSize().x*0.35;
        vec2 posTop = UI::GetCursorPos();

        UI::BeginChild("Summary", vec2(width,0));

        auto thumb = Images::CachedFromURL("https://"+MXURL+"/mappack/thumbnail/"+m_mapPack.ID);
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

        if (m_mapPack.Unreleased) UI::Text(Icons::Times + " \\$f77Unreleased");
        UI::Text(Icons::ThList + " \\$f77" + m_mapPack.TypeName);
        UI::Text(Icons::ListOl + " \\$f77" + m_mapPack.TrackCount);

        UI::Text(Icons::Hashtag + " \\$f77" + m_mapPack.ID);
        UI::SameLine();
        UI::TextDisabled(Icons::Clipboard);
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::Text("Click to copy to clipboard");
            UI::EndTooltip();
        }
        if (UI::IsItemClicked()) {
            IO::SetClipboard(tostring(m_mapPack.ID));
            UI::ShowNotification(Icons::Clipboard + " Map pack ID copied to clipboard");
        }

        if (m_mapPack.Request) UI::Text(Icons::HandPeaceO+ " \\$f77Open for requests!");
        UI::Text(Icons::Calendar + " \\$f77" + m_mapPack.Created);
        if (m_mapPack.Created != m_mapPack.Edited) UI::Text(Icons::Refresh + " \\$f77" + m_mapPack.Edited);

        if (UI::CyanButton(Icons::ExternalLink + " View on "+pluginName)) OpenBrowserURL("https://"+MXURL+"/mappack/view/"+m_mapPack.ID);

#if TMNEXT
        if (!m_mapListError && mapPack_maps.Length != 0 && Permissions::PlayLocalMap() && UI::GreenButton(Icons::Check + " Add to Play later")) {
#else
        if (!m_mapListError && mapPack_maps.Length != 0 && UI::GreenButton(Icons::Check + " Add to Play later")) {
#endif
            Dialogs::Question("\\$f90" + Icons::ExclamationTriangle + " \\$zThis will add " + mapPack_maps.Length + " maps to the Play later list, are you sure?", function(){
                for (uint i = 0; i < mapPack_maps.Length; i++) {
                    g_PlayLaterMaps.InsertAt(g_PlayLaterMaps.Length, mapPack_maps[i]);
                }
                SavePlayLater(g_PlayLaterMaps);
                Dialogs::Message("\\$0f0"+Icons::Check+" \\$zAdded "+mapPack_maps.Length+" maps to the Play Later list");
            }, function(){});
        }

        UI::EndChild();

        UI::SetCursorPos(posTop + vec2(width + 8, 0));
        UI::BeginChild("Description");

        UI::PushFont(g_fontHeader);
        UI::Text(m_mapPack.Name);
        UI::PopFont();

        UI::TextDisabled("By " + m_mapPack.Username);

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
                    if (UI::BeginTable("List", 5)) {
                        UI::TableSetupScrollFreeze(0, 1);
                        PushTabStyle();
                        UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                        UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthStretch);
                        UI::TableSetupColumn("Style", UI::TableColumnFlags::WidthStretch);
                        UI::TableSetupColumn(Icons::Trophy, UI::TableColumnFlags::WidthFixed, 40);
                        UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 80);
                        UI::TableHeadersRow();
                        PopTabStyle();
                        for(uint j = 0; j < mapPack_maps.get_Length(); j++)
                        {
                            UI::PushID("ResMap"+j);
                            MX::MapInfo@ map = mapPack_maps[j];
                            IfaceRender::MapResult(map);
                            UI::PopID();
                        }
                        UI::EndTable();
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