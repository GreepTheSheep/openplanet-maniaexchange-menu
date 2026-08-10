class MappackFilters : BaseFilters
{
    string m_name;
    string m_manager;
    MX::MappackTypes m_type = MX::MappackTypes::Any;

    // Tags
    array<MX::MapTag@> m_includedTags;
    array<MX::MapTag@> m_excludedTags;
    bool m_tagInclusiveSearch;

    // Creation date
    string m_fromDate;
    string m_toDate;

    MappackFilters(Tab@ tab) {
        super(tab);
        m_size = vec2(800, 500);
    }

    string get_Name() override {
        return "Mapppack filters";
    }

    Presets::Type get_PresetType() override {
        return Presets::Type::Mappack;
    }

    void ResetParameters(bool resetPreset = true) override {
        BaseFilters::ResetParameters(resetPreset);

        m_name = "";
        m_manager = "";
        m_type = MX::MappackTypes::Any;
        m_includedTags.RemoveRange(0, m_includedTags.Length);
        m_excludedTags.RemoveRange(0, m_excludedTags.Length);
        m_tagInclusiveSearch = false;
        m_fromDate = "";
        m_toDate = "";
    }

    void RenderFilters() override {
        float itemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x;

        UI::PaddedHeaderSeparator("Mappack");

        UI::SetItemText("Name:");
        m_name = UI::InputText("##NameFilter", m_name);

        if (m_name != "" && UI::ResetButton()) {
            m_name = "";
        }

        UI::SetCenteredItemText("Manager:");
        m_manager = UI::InputText("##ManagerFilter", m_manager);
        UI::SetItemTooltip(shortMXName + " username of a manager for the mappack.\n\nThis can include users who didn't create the mappack");

        if (m_manager != "" && UI::ResetButton()) {
            m_manager = "";
        }

        UI::VPadding();

        UI::SetItemText("Type:");
        if (UI::BeginCombo("##MappackTypeFilter", tostring(m_type))) {
            for (int i = -1; i <= MX::MappackTypes::Contest; i++) {
                if (UI::Selectable(tostring(MX::MappackTypes(i)), m_type == MX::MappackTypes(i))) {
                    m_type = MX::MappackTypes(i);
                }
            }

            UI::EndCombo();
        }

        if (m_type != MX::MappackTypes::Any && UI::ResetButton()) {
            m_type = MX::MappackTypes::Any;
        }

        UI::PaddedHeaderSeparator("Tags");

        UI::SetItemText("Include:");

        string includeText;
        switch (m_includedTags.Length) {
            case 0: includeText = "No tags"; break;
            case 1: includeText = m_includedTags[0].Name; break;
            default: includeText = tostring(m_includedTags.Length) + " tags"; break;
        }

        if (UI::BeginCombo("###TagsIncludeCombo", includeText)) {
            if (UI::IsWindowAppearing()) {
                m_searchCombo = "";
            }

            UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
            m_searchCombo = UI::InputText("##TagSearch", m_searchCombo);

            UI::Separator();

            for (uint i = 0; i < MX::m_mapTags.Length; i++) {
                MX::MapTag@ tag = MX::m_mapTags[i];

                if (!tag.Name.ToLower().Contains(m_searchCombo.ToLower())) continue;

                UI::PushID("TagBtn" + i);

                bool inArray = m_includedTags.FindByRef(tag) != -1;

                if (UI::Checkbox(tag.Name, inArray)) {
                    if (!inArray) {
                        m_includedTags.InsertLast(tag);
                    }
                } else if (inArray) {
                    m_includedTags.RemoveAt(m_includedTags.FindByRef(tag));
                }

                UI::PopID();
            }

            UI::EndCombo();
        }

        if (m_includedTags.Length > 0 && UI::ResetButton()) {
            m_includedTags.RemoveRange(0, m_includedTags.Length);
        }

        UI::SetCenteredItemText("Exclude:");

        string excludeText;
        switch (m_excludedTags.Length) {
            case 0: excludeText = "No tags"; break;
            case 1: excludeText = m_excludedTags[0].Name; break;
            default: excludeText = tostring(m_excludedTags.Length) + " tags"; break;
        }

        if (UI::BeginCombo("###TagsExcludeCombo", excludeText)) {
            if (UI::IsWindowAppearing()) {
                m_searchCombo = "";
            }

            UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
            m_searchCombo = UI::InputText("##TagSearch", m_searchCombo);

            UI::Separator();

            for (uint i = 0; i < MX::m_mapTags.Length; i++) {
                MX::MapTag@ tag = MX::m_mapTags[i];

                if (!tag.Name.ToLower().Contains(m_searchCombo.ToLower())) continue;

                UI::PushID("TagExBtn" + i);

                bool inArray = m_excludedTags.FindByRef(tag) != -1;

                if (UI::Checkbox(tag.Name, inArray)) {
                    if (!inArray) {
                        m_excludedTags.InsertLast(tag);
                    }
                } else if (inArray) {
                    m_excludedTags.RemoveAt(m_excludedTags.FindByRef(tag));
                }

                UI::PopID();
            }

            UI::EndCombo();
        }

        if (m_excludedTags.Length > 0 && UI::ResetButton()) {
            m_excludedTags.RemoveRange(0, m_excludedTags.Length);
        }

        UI::VPadding();

        m_tagInclusiveSearch = UI::Checkbox("Tag inclusive search", m_tagInclusiveSearch);
        UI::SetItemTooltip("If checked, maps must contain all selected tags.");

        UI::PaddedHeaderSeparator("Date");

        UI::SetItemText("From:");
        m_fromDate = UI::InputText("##FromDateFilter", m_fromDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::DateCallback);
        UI::SetItemTooltip("Minimum date when the mappack was created, formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if (m_fromDate != "" && UI::ResetButton()) {
            m_fromDate = "";
        }

        UI::SetCenteredItemText("To:");
        m_toDate = UI::InputText("##ToDateFilter", m_toDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::DateCallback);
        UI::SetItemTooltip("Maximum date when the mappack was created, formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if (m_toDate != "" && UI::ResetButton()) {
            m_toDate = "";
        }

        UI::PaddedHeaderSeparator("Custom parameters");

        UI::TextWrapped("Custom parameters that can be passed to the " + shortMXName + " API. Use it for any parameter this plugin might be missing.");

        UI::NewLine();

        m_customParams.Render();
    }

    void GetRequestParams(dictionary@ params) override {
        if (m_name != "") params.Set("name", m_name);
        if (m_manager != "") params.Set("manager", m_manager);
        if (m_type != MX::MappackTypes::Any) params.Set("primarytype", tostring(int(m_type)));

        // Tags

        if (m_includedTags.Length > 0) {
            array<string> tagIds;

            for (uint i = 0; i < m_includedTags.Length; i++) {
                tagIds.InsertLast(tostring(m_includedTags[i].ID));
            }

            params.Set("tag", Text::Join(tagIds, ","));
        }

        if (m_excludedTags.Length > 0) {
            array<string> etagsIds;

            for (uint i = 0; i < m_excludedTags.Length; i++) {
                etagsIds.InsertLast(tostring(m_excludedTags[i].ID));
            }

            params.Set("etag", Text::Join(etagsIds, ","));
        }

        if (m_tagInclusiveSearch) params.Set("taginclusive", "true");

        // Upload date

        if (m_fromDate != "" && Date::IsValid(m_fromDate)) {
            params.Set("createdafter", m_fromDate);
        }

        if (m_toDate != "" && Date::IsValid(m_toDate)) {
            params.Set("createdbefore", m_toDate);
        }

        m_customParams.AddToDictionary(params);
    }

    Json::Value ToJson() override {
        Json::Value json = Json::Object();

        json["name"]         = m_name;
        json["manager"]      = m_manager;
        json["type"]         = m_type;
        json["fromDate"]     = m_fromDate;
        json["toDate"]       = m_toDate;
        json["tagInclusive"] = m_tagInclusiveSearch;
        json["customParams"] = m_customParams.ToJson();

        array<int> tagIds;

        for (uint i = 0; i < m_includedTags.Length; i++) {
            tagIds.InsertLast(m_includedTags[i].ID);
        }

        json["includedTags"] = tagIds;

        array<int> etagsIds;

        for (uint i = 0; i < m_excludedTags.Length; i++) {
            etagsIds.InsertLast(m_excludedTags[i].ID);
        }

        json["excludedTags"] = etagsIds;

        return json;
    }

    void LoadPreset(Json::Value@ json) override {
        ResetParameters(false);

        m_name               = json["name"];
        m_manager            = json["manager"];
        m_fromDate           = json["fromDate"];
        m_toDate             = json["toDate"];
        m_type               = MX::MappackTypes(int(json["type"]));
        m_tagInclusiveSearch = json["tagInclusive"];

        if (json.HasKey("customParams")) {
            m_customParams.LoadJson(json["customParams"]);
        }

        array<int> tagIds = JsonToIntArray(json["includedTags"]);
        array<int> etagsIds = JsonToIntArray(json["excludedTags"]);

        for (uint i = 0; i < MX::m_mapTags.Length; i++) {
            MX::MapTag@ tag = MX::m_mapTags[i];

            if (tagIds.Find(tag.ID) != -1) {
                m_includedTags.InsertLast(tag);
            }

            if (etagsIds.Find(tag.ID) != -1) {
                m_excludedTags.InsertLast(tag);
            }

            if (m_includedTags.Length == tagIds.Length && m_excludedTags.Length == etagsIds.Length) {
                break;
            }
        }
    }
}
