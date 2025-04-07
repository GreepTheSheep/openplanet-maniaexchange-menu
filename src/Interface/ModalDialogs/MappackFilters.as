class MappackFilters : ModalDialog
{
    Tab@ activeTab;

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

    // To search in combos
    string tagSearchCombo;
    string etagSearchCombo;

    MappackFilters(Tab@ tab) {
        super(Icons::Filter + " \\$zMappack filters###MappackFilters");
        m_size = vec2(800, 500);
        @activeTab = tab;
    }

    void ResetParameters() {
        t_name = "";
        t_manager = "";
        t_type = MX::MappackTypes::Any;
        t_includedTags.RemoveRange(0, t_includedTags.Length);
        t_excludedTags.RemoveRange(0, t_excludedTags.Length);
        t_tagInclusiveSearch = false;
        t_fromDate = "";
        t_toDate = "";
        tagSearchCombo = "";
        etagSearchCombo = "";
    }

    void RenderDialog() override {
        float itemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x;
        float scale = UI::GetScale();

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
            UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
            tagSearchCombo = UI::InputText("##TagSearch", tagSearchCombo);

            UI::Separator();

            for (uint i = 0; i < MX::m_mapTags.Length; i++) {
                MX::MapTag@ tag = MX::m_mapTags[i];

                if (!tag.Name.ToLower().Contains(tagSearchCombo.ToLower())) continue;

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
        } else {
            tagSearchCombo = "";
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
            UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
            etagSearchCombo = UI::InputText("##TagSearch", etagSearchCombo);

            UI::Separator();

            for (uint i = 0; i < MX::m_mapTags.Length; i++) {
                MX::MapTag@ tag = MX::m_mapTags[i];

                if (!tag.Name.ToLower().Contains(etagSearchCombo.ToLower())) continue;

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
        } else {
            etagSearchCombo = "";
        }

        if (t_excludedTags.Length > 0 && UI::ResetButton()) {
            t_excludedTags.RemoveRange(0, t_excludedTags.Length);
        }

        UI::VPadding();

        t_tagInclusiveSearch = UI::Checkbox("Tag inclusive search", t_tagInclusiveSearch);
        UI::SetItemTooltip("If checked, maps must contain all selected tags.");

        UI::PaddedHeaderSeparator("Date");

        UI::SetItemText("From:");
        t_fromDate = UI::InputText("##FromDateFilter", t_fromDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::InputTextCallback(UI::DateCallback));
        UI::SetItemTooltip("Minimum date when the mappack was created, formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if (t_fromDate != "" && UI::ResetButton()) {
            t_fromDate = "";
        }

        UI::SetCenteredItemText("To:");
        t_toDate = UI::InputText("##ToDateFilter", t_toDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::InputTextCallback(UI::DateCallback));
        UI::SetItemTooltip("Maximum date when the mappack was created, formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if (t_toDate != "" && UI::ResetButton()) {
            t_toDate = "";
        }

        vec2 region = UI::GetContentRegionAvail();
        UI::VPadding(region.y - 45 * scale);

        vec2 pos = UI::GetCursorPos();
        UI::SetCursorPos(vec2(region.x - 175 * scale, pos.y));

        if (UI::GreenButton(Icons::Search + " Search")) {
            startnew(CoroutineFunc(activeTab.Reload));
            Close();
        }

        UI::SameLine();

        if (UI::OrangeButton(Icons::Repeat + " Reset")) {
            ResetParameters();
        }
    }

    void GetRequestParams(dictionary@ params) {
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
}
