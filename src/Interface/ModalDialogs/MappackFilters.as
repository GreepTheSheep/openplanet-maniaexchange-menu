class MappackFilters : BaseFilters
{
    string t_name;
    string t_manager;
    MX::MappackTypes t_type = MX::MappackTypes::Any;

    // Tags
    array<MX::MapTag@> t_includedTags;
    array<MX::MapTag@> t_excludedTags;
    bool t_tagInclusiveSearch;

    // Creation date
    string t_fromDate;
    string t_toDate;

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

    void ResetParameters() override {
        BaseFilters::ResetParameters();

        t_name = "";
        t_manager = "";
        t_type = MX::MappackTypes::Any;
        t_includedTags.RemoveRange(0, t_includedTags.Length);
        t_excludedTags.RemoveRange(0, t_excludedTags.Length);
        t_tagInclusiveSearch = false;
        t_fromDate = "";
        t_toDate = "";
    }

    void RenderFilters() override {
        float itemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x;

        UI::PaddedHeaderSeparator("Mappack");

        UI::SetItemText("Name:");
        t_name = UI::InputText("##NameFilter", t_name);

        if (t_name != "" && UI::ResetButton()) {
            t_name = "";
        }

        UI::SetCenteredItemText("Manager:");
        t_manager = UI::InputText("##ManagerFilter", t_manager);
        UI::SetItemTooltip(shortMXName + " username of a manager for the mappack.\n\nThis can include users who didn't create the mappack");

        if (t_manager != "" && UI::ResetButton()) {
            t_manager = "";
        }

        UI::VPadding();

        UI::SetItemText("Type:");
        if (UI::BeginCombo("##MappackTypeFilter", tostring(t_type))) {
            for (int i = -1; i <= MX::MappackTypes::Contest; i++) {
                if (UI::Selectable(tostring(MX::MappackTypes(i)), t_type == MX::MappackTypes(i))) {
                    t_type = MX::MappackTypes(i);
                }
            }

            UI::EndCombo();
        }

        if (t_type != MX::MappackTypes::Any && UI::ResetButton()) {
            t_type = MX::MappackTypes::Any;
        }

        UI::PaddedHeaderSeparator("Tags");

        UI::SetItemText("Include:");

        string includeText;
        switch (t_includedTags.Length) {
            case 0: includeText = "No tags"; break;
            case 1: includeText = t_includedTags[0].Name; break;
            default: includeText = tostring(t_includedTags.Length) + " tags"; break;
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

                bool inArray = t_includedTags.FindByRef(tag) != -1;

                if (UI::Checkbox(tag.Name, inArray)) {
                    if (!inArray) {
                        t_includedTags.InsertLast(tag);
                    }
                } else if (inArray) {
                    t_includedTags.RemoveAt(t_includedTags.FindByRef(tag));
                }

                UI::PopID();
            }

            UI::EndCombo();
        }

        if (t_includedTags.Length > 0 && UI::ResetButton()) {
            t_includedTags.RemoveRange(0, t_includedTags.Length);
        }

        UI::SetCenteredItemText("Exclude:");

        string excludeText;
        switch (t_excludedTags.Length) {
            case 0: excludeText = "No tags"; break;
            case 1: excludeText = t_excludedTags[0].Name; break;
            default: excludeText = tostring(t_excludedTags.Length) + " tags"; break;
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

                bool inArray = t_excludedTags.FindByRef(tag) != -1;

                if (UI::Checkbox(tag.Name, inArray)) {
                    if (!inArray) {
                        t_excludedTags.InsertLast(tag);
                    }
                } else if (inArray) {
                    t_excludedTags.RemoveAt(t_excludedTags.FindByRef(tag));
                }

                UI::PopID();
            }

            UI::EndCombo();
        }

        if (t_excludedTags.Length > 0 && UI::ResetButton()) {
            t_excludedTags.RemoveRange(0, t_excludedTags.Length);
        }

        UI::VPadding();

        t_tagInclusiveSearch = UI::Checkbox("Tag inclusive search", t_tagInclusiveSearch);
        UI::SetItemTooltip("If checked, maps must contain all selected tags.");

        UI::PaddedHeaderSeparator("Date");

        UI::SetItemText("From:");
        t_fromDate = UI::InputText("##FromDateFilter", t_fromDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::DateCallback);
        UI::SetItemTooltip("Minimum date when the mappack was created, formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if (t_fromDate != "" && UI::ResetButton()) {
            t_fromDate = "";
        }

        UI::SetCenteredItemText("To:");
        t_toDate = UI::InputText("##ToDateFilter", t_toDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::DateCallback);
        UI::SetItemTooltip("Maximum date when the mappack was created, formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if (t_toDate != "" && UI::ResetButton()) {
            t_toDate = "";
        }
    }

    void GetRequestParams(dictionary@ params) override {
        if (t_name != "") params.Set("name", t_name);
        if (t_manager != "") params.Set("manager", t_manager);
        if (t_type != MX::MappackTypes::Any) params.Set("primarytype", tostring(int(t_type)));

        // Tags

        if (t_includedTags.Length > 0) {
            array<string> tagIds;

            for (uint i = 0; i < t_includedTags.Length; i++) {
                tagIds.InsertLast(tostring(t_includedTags[i].ID));
            }

            params.Set("tag", string::Join(tagIds, ","));
        }

        if (t_excludedTags.Length > 0) {
            array<string> etagsIds;

            for (uint i = 0; i < t_excludedTags.Length; i++) {
                etagsIds.InsertLast(tostring(t_excludedTags[i].ID));
            }

            params.Set("etag", string::Join(etagsIds, ","));
        }

        if (t_tagInclusiveSearch) params.Set("taginclusive", "true");

        // Upload date

        if (t_fromDate != "" && Date::IsValid(t_fromDate)) {
            params.Set("createdafter", t_fromDate);
        }

        if (t_toDate != "" && Date::IsValid(t_toDate)) {
            params.Set("createdbefore", t_toDate);
        }
    }

    Json::Value ToJson() override {
        Json::Value json = Json::Object();

        json["name"]         = t_name;
        json["manager"]      = t_manager;
        json["type"]         = t_type;
        json["fromDate"]     = t_fromDate;
        json["toDate"]       = t_toDate;
        json["tagInclusive"] = t_tagInclusiveSearch;

        array<int> tagIds;

        for (uint i = 0; i < t_includedTags.Length; i++) {
            tagIds.InsertLast(t_includedTags[i].ID);
        }

        json["includedTags"] = tagIds;

        array<int> etagsIds;

        for (uint i = 0; i < t_excludedTags.Length; i++) {
            etagsIds.InsertLast(t_excludedTags[i].ID);
        }

        json["excludedTags"] = etagsIds;

        return json;
    }

    void LoadPreset(Json::Value@ json) override {
        ResetParameters();

        t_name               = json["name"];
        t_manager            = json["manager"];
        t_fromDate           = json["fromDate"];
        t_toDate             = json["toDate"];
        t_type               = MX::MappackTypes(int(json["type"]));
        t_tagInclusiveSearch = json["tagInclusive"];

        array<int> tagIds = JsonToIntArray(json["includedTags"]);
        array<int> etagsIds = JsonToIntArray(json["excludedTags"]);

        for (uint i = 0; i < MX::m_mapTags.Length; i++) {
            MX::MapTag@ tag = MX::m_mapTags[i];

            if (tagIds.Find(tag.ID) != -1) {
                t_includedTags.InsertLast(tag);
            }

            if (etagsIds.Find(tag.ID) != -1) {
                t_excludedTags.InsertLast(tag);
            }

            if (t_includedTags.Length == tagIds.Length && t_excludedTags.Length == etagsIds.Length) {
                break;
            }
        }
    }
}
