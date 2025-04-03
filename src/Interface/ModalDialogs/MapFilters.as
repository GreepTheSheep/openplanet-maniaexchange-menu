class MapFilters : ModalDialog
{
    Tab@ activeTab;

    string m_name;
    string m_author;
    array<MX::Difficulties> m_selectedDifficulties;
    string m_modSearch;
    string m_maptype = "Any";
    string m_titlepack = "Any";

    // Tags
    array<MX::MapTag@> m_includedTags;
    array<MX::MapTag@> m_excludedTags;
    bool m_tagInclusiveSearch;

    // Upload date
    string m_fromDate;
    string m_toDate;

    // Environment / Vehicle
    array<MX::MapEnvironment@> m_selectedEnvironments;
    array<string> m_selectedVehicles;

    // Length (milliseconds/respawns/points)
    int m_minLength = 0;
    int m_maxLength = 0;

    // To search in combos
    string maptypeSearchCombo;
    string titlepackSearchCombo;
    string tagSearchCombo;
    string etagSearchCombo;
    string enviSearchCombo;
    string vehicleSearchCombo;

    MapFilters(Tab@ tab) {
        super(Icons::Filter + " \\$zFilters###MapFilters");
        m_size = vec2(800, 600);
        @activeTab = tab;
    }

    void ResetParameters() {
        m_name = "";
        m_author = "";
        m_selectedDifficulties.RemoveRange(0, m_selectedDifficulties.Length);
        m_maptype = "Any";
        m_modSearch = "";
        m_titlepack = "Any";
        m_includedTags.RemoveRange(0, m_includedTags.Length);
        m_excludedTags.RemoveRange(0, m_excludedTags.Length);
        m_tagInclusiveSearch = false;
        m_fromDate = "";
        m_toDate = "";
        m_selectedVehicles.RemoveRange(0, m_selectedVehicles.Length);
        m_selectedEnvironments.RemoveRange(0, m_selectedEnvironments.Length);
        m_minLength = 0;
        m_maxLength = 0;
        maptypeSearchCombo = "";
        titlepackSearchCombo = "";
        tagSearchCombo = "";
        etagSearchCombo = "";
        enviSearchCombo = "";
        vehicleSearchCombo = "";
    }

    void RenderDialog() override {
        float itemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x;
        float scale = UI::GetScale();

        UI::PaddedHeaderSeparator("Map");

        UI::SetItemText("Name:");
        m_name = UI::InputText("##NameFilter", m_name);

        if (m_name != "" && UI::ResetButton()) {
            m_name = "";
        }

        UI::SetCenteredItemText("Author:");
        m_author = UI::InputText("##AuthorFilter", m_author);

        if (m_author != "" && UI::ResetButton()) {
            m_author = "";
        }

        UI::VPadding();

        UI::SetItemText("Difficulty:");

        string difficultyText;
        switch (m_selectedDifficulties.Length) {
            case 0: difficultyText = "Any"; break;
            case 1: difficultyText = tostring(m_selectedDifficulties[0]); break;
            default: difficultyText = tostring(m_selectedDifficulties.Length) + " difficulties"; break;
        }

        if (UI::BeginCombo("###DifficultyFilter", difficultyText)) {
            for (uint i = 0; i <= MX::Difficulties::Impossible; i++) {
                UI::PushID("DifficultyBtn" + i);

                bool inArray = m_selectedDifficulties.Find(MX::Difficulties(i)) != -1;

                if (UI::Checkbox(tostring(MX::Difficulties(i)), inArray)) {
                    if (!inArray) {
                        m_selectedDifficulties.InsertLast(MX::Difficulties(i));
                    }
                } else if (inArray) {
                    m_selectedDifficulties.RemoveAt(m_selectedDifficulties.Find(MX::Difficulties(i)));
                }

                UI::PopID();
            }

            UI::EndCombo();
        }

        if (m_selectedDifficulties.Length > 0 && UI::ResetButton()) {
            m_selectedDifficulties.RemoveRange(0, m_selectedDifficulties.Length);
        }

        UI::SetCenteredItemText("Texture mod:");
        m_modSearch = UI::InputText("##ModFilter", m_modSearch);
        UI::SetItemTooltip("Name of the texture mod used by the map.");

        if (m_modSearch != "" && UI::ResetButton()) {
            m_modSearch = "";
        }

        UI::VPadding();

        UI::SetItemText("Map Type:");
        if (UI::BeginCombo("##MapTypeFilter", m_maptype)) {
            UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
            maptypeSearchCombo = UI::InputText("##MapTypeSearch", maptypeSearchCombo);

            UI::Separator();

            for (uint i = 0; i < MX::m_maptypes.Length; i++) {
                string maptype = MX::m_maptypes[i];

                if (!maptype.ToLower().Contains(maptypeSearchCombo.ToLower())) continue;

                if (UI::Selectable(maptype, m_maptype == maptype)) {
                    m_maptype = maptype;
                }
            }

            UI::EndCombo();
        } else {
            // Reset search bar on combo closing
            maptypeSearchCombo = "";
        }

        if (m_maptype != "Any" && UI::ResetButton()) {
            m_maptype = "Any";
        }

#if MP4
        UI::SetCenteredItemText("Title pack:");
        if (UI::BeginCombo("##TitlePackFilter", m_titlepack)) {
            UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
            titlepackSearchCombo = UI::InputText("##TitlePackSearch", titlepackSearchCombo);

            UI::Separator();

            for (uint i = 0; i < MX::m_titlepacks.Length; i++) {
                string titlepack = MX::m_titlepacks[i];

                if (!titlepack.ToLower().Contains(titlepackSearchCombo.ToLower())) continue;

                if (UI::Selectable(titlepack, m_titlepack == titlepack)) {
                    m_titlepack = titlepack;
                }
            }

            UI::EndCombo();
        } else {
            titlepackSearchCombo = "";
        }

        if (m_titlepack != "Any" && UI::ResetButton()) {
            m_titlepack = "Any";
        }
#endif

        UI::PaddedHeaderSeparator("Tags");

        UI::SetItemText("Include:");

        string includeText;
        switch (m_includedTags.Length) {
            case 0: includeText = "No tags"; break;
            case 1: includeText = m_includedTags[0].Name; break;
            default: includeText = tostring(m_includedTags.Length) + " tags"; break;
        }

        if (UI::BeginCombo("###TagsIncludeCombo", includeText)) {
            UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
            tagSearchCombo = UI::InputText("##TagSearch", tagSearchCombo);

            UI::Separator();

            for (uint i = 0; i < MX::m_mapTags.Length; i++) {
                MX::MapTag@ tag = MX::m_mapTags[i];

                if (!tag.Name.ToLower().Contains(tagSearchCombo.ToLower())) continue;

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
        } else {
            tagSearchCombo = "";
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
            UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
            etagSearchCombo = UI::InputText("##TagSearch", etagSearchCombo);

            UI::Separator();

            for (uint i = 0; i < MX::m_mapTags.Length; i++) {
                MX::MapTag@ tag = MX::m_mapTags[i];

                if (!tag.Name.ToLower().Contains(etagSearchCombo.ToLower())) continue;

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
        } else {
            etagSearchCombo = "";
        }

        if (m_excludedTags.Length > 0 && UI::ResetButton()) {
            m_excludedTags.RemoveRange(0, m_excludedTags.Length);
        }

        UI::VPadding();

        m_tagInclusiveSearch = UI::Checkbox("Tag inclusive search", m_tagInclusiveSearch);
        UI::SetItemTooltip("If checked, maps must contain all selected tags.");

        UI::PaddedHeaderSeparator("Date");

        UI::SetItemText("From:");
        m_fromDate = UI::InputText("##FromDateFilter", m_fromDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::InputTextCallback(UI::DateCallback));
        UI::SetItemTooltip("Minimum date when the map was uploaded to " + shortMXName + ", formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if (m_fromDate != "" && UI::ResetButton()) {
            m_fromDate = "";
        }

        UI::SetCenteredItemText("To:");
        m_toDate = UI::InputText("##ToDateFilter", m_toDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::InputTextCallback(UI::DateCallback));
        UI::SetItemTooltip("Maximum date when the map was uploaded to " + shortMXName + ", formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if (m_toDate != "" && UI::ResetButton()) {
            m_toDate = "";
        }

#if MP4
        if (repo == MP4mxRepos::Trackmania) {
            UI::PaddedHeaderSeparator("Environment / Vehicle");
#else
            UI::PaddedHeaderSeparator("Vehicle");
#endif

            if (MX::m_environments.Length > 1) {
                UI::SetItemText("Environment:");

                string enviText;
                switch (m_selectedEnvironments.Length) {
                    case 0: enviText = "Any"; break;
                    case 1: enviText = m_selectedEnvironments[0].Name; break;
                    default: enviText = tostring(m_selectedEnvironments.Length) + " environments"; break;
                }

                if (UI::BeginCombo("###EnviFilter", enviText)) {
                    UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
                    enviSearchCombo = UI::InputText("##EnviSearch", enviSearchCombo);

                    UI::Separator();

                    for (uint i = 0; i < MX::m_environments.Length; i++) {
                        MX::MapEnvironment@ envi = MX::m_environments[i];

                        if (!envi.Name.ToLower().Contains(enviSearchCombo.ToLower())) continue;

                        UI::PushID("EnviBtn" + i);

                        bool inArray = m_selectedEnvironments.FindByRef(envi) != -1;

                        if (UI::Checkbox(envi.Name, inArray)) {
                            if (!inArray) {
                                m_selectedEnvironments.InsertLast(envi);
                            }
                        } else if (inArray) {
                            m_selectedEnvironments.RemoveAt(m_selectedEnvironments.FindByRef(envi));
                        }

                        UI::PopID();
                    }

                    UI::EndCombo();
                } else {
                    enviSearchCombo = "";
                }

                if (m_selectedEnvironments.Length > 0 && UI::ResetButton()) {
                    m_selectedEnvironments.RemoveRange(0, m_selectedEnvironments.Length);
                }
            }

            if (MX::m_vehicles.Length > 1) {
                if (MX::m_environments.Length > 1) UI::SetCenteredItemText("Vehicle:");
                else UI::SetItemText("Vehicle:");

                string vehicleText;
                switch (m_selectedVehicles.Length) {
                    case 0: vehicleText = "Any"; break;
                    case 1: vehicleText = m_selectedVehicles[0]; break;
                    default: vehicleText = tostring(m_selectedVehicles.Length) + " vehicles"; break;
                }

                if (UI::BeginCombo("##VehicleFilter", vehicleText)) {
                    UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
                    vehicleSearchCombo = UI::InputText("##VehicleSearch", vehicleSearchCombo);

                    UI::Separator();

                    for (uint i = 0; i < MX::m_vehicles.Length; i++) {
                        string vehicleName = MX::m_vehicles[i];

                        if (!vehicleName.ToLower().Contains(vehicleSearchCombo.ToLower())) continue;

                        UI::PushID("VehicleBtn" + i);

                        bool inArray = m_selectedVehicles.Find(vehicleName) != -1;

                        if (UI::Checkbox(vehicleName, inArray)) {
                            if (!inArray) {
                                m_selectedVehicles.InsertLast(vehicleName);
                            }
                        } else if (inArray) {
                            m_selectedVehicles.RemoveAt(m_selectedVehicles.Find(vehicleName));
                        }

                        UI::PopID();
                    }

                    UI::EndCombo();
                } else {
                    vehicleSearchCombo = "";
                }
#if TMNEXT
                UI::SetItemTooltip("\\$f90" + Icons::ExclamationTriangle + "\\$z This will filter by the base vehicle used by the map, it won't include maps that use car triggers instead.\n\nTo include those maps, consider filtering by tags instead.");
#endif

                if (m_selectedVehicles.Length > 0 && UI::ResetButton()) {
                    m_selectedVehicles.RemoveRange(0, m_selectedVehicles.Length);
                }
            }

            UI::PaddedHeaderSeparator("Length");

            UI::SetItemText("From:");
            m_minLength = UI::InputInt("##FromLengthFilter", m_minLength, 0);
            UI::SetItemTooltip("Minimum duration of the map, based on the author medal, in milliseconds.\n\nCan also be used for respawns (Platform) and points (Stunt).");

            if (m_minLength != 0 && UI::ResetButton()) {
                m_minLength = 0;
            }

            UI::SetCenteredItemText("To:");
            m_maxLength = UI::InputInt("##ToLengthFilter", m_maxLength, 0);
            UI::SetItemTooltip("Maximum duration of the map, based on the author medal, in milliseconds.\n\nCan also be used for respawns (Platform) and points (Stunt).");

            if (m_maxLength != 0 && UI::ResetButton()) {
                m_maxLength = 0;
            }

            UI::BeginDisabled();

            UI::SetItemText("Time:");
            UI::Text(Time::Format(m_minLength));

            UI::SetCenteredItemText("Time:");
            UI::Text(Time::Format(m_maxLength));

            UI::EndDisabled();
#if MP4
        }
#endif

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
        if (m_name != "") params.Set("name", m_name);
        if (m_author != "") params.Set("author", m_author);
        if (m_modSearch != "") params.Set("mod", m_modSearch);
        if (m_maptype != "Any") params.Set("maptype", m_maptype);
#if MP4
        if (m_titlepack != "Any") params.Set("titlepack", m_titlepack);
#endif

        if (m_selectedDifficulties.Length > 0) {
            array<string> diffIds;

            for (uint i = 0; i < m_selectedDifficulties.Length; i++) {
                diffIds.InsertLast(tostring(int(m_selectedDifficulties[i])));
            }

            params.Set("difficulty", string::Join(diffIds, ","));
        }

        // Tags

        if (m_includedTags.Length > 0) {
            array<string> tagIds;

            for (uint i = 0; i < m_includedTags.Length; i++) {
                tagIds.InsertLast(tostring(m_includedTags[i].ID));
            }

            params.Set("tag", string::Join(tagIds, ","));
        }

        if (m_excludedTags.Length > 0) {
            array<string> etagsIds;

            for (uint i = 0; i < m_excludedTags.Length; i++) {
                etagsIds.InsertLast(tostring(m_excludedTags[i].ID));
            }

            params.Set("etag", string::Join(etagsIds, ","));
        }

        if (m_tagInclusiveSearch) params.Set("taginclusive", "true");

        // Upload date

        if (m_fromDate != "" && Date::IsValid(m_fromDate)) {
            params.Set("uploadedafter", m_fromDate);
        }

        if (m_toDate != "" && Date::IsValid(m_toDate)) {
            params.Set("uploadedbefore", m_toDate);
        }

        // Environment / Vehicle
#if MP4
        if (m_selectedEnvironments.Length > 0) {
            array<string> enviIds;

            for (uint i = 0; i < m_selectedEnvironments.Length; i++) {
                enviIds.InsertLast(tostring(m_selectedEnvironments[i].ID));
            }

            params.Set("environment", string::Join(enviIds, ","));
        }
#endif

        if (m_selectedVehicles.Length > 0) {
            params.Set("vehicle", string::Join(m_selectedVehicles, ","));
        }

        // Length

        if (m_minLength > 0) params.Set("authortimemin", tostring(m_minLength));
        if (m_maxLength > 0) params.Set("authortimemax", tostring(m_maxLength));
    }
}
