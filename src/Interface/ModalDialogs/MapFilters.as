class MapFilters : BaseFilters
{
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
    MX::AuthorTimeStatus m_authorTimeStatus = MX::AuthorTimeStatus::Any;

    MapFilters(Tab@ tab) {
        super(tab);
        m_size = vec2(800, 600);
    }

    string get_Name() override {
        return "Map filters";
    }

    Presets::Type get_PresetType() override {
        return Presets::Type::Map;
    }

    void ResetParameters() override {
        BaseFilters::ResetParameters();

        m_name = "";
        m_author = "";
        m_selectedDifficulties.RemoveRange(0, m_selectedDifficulties.Length);
        m_maptype = "Any";
        m_modSearch = "";
        m_titlepack = "Any";
        m_authorTimeStatus = MX::AuthorTimeStatus::Any;
        m_includedTags.RemoveRange(0, m_includedTags.Length);
        m_excludedTags.RemoveRange(0, m_excludedTags.Length);
        m_tagInclusiveSearch = false;
        m_fromDate = "";
        m_toDate = "";
        m_selectedVehicles.RemoveRange(0, m_selectedVehicles.Length);
        m_selectedEnvironments.RemoveRange(0, m_selectedEnvironments.Length);
        m_minLength = 0;
        m_maxLength = 0;
    }

    void RenderFilters() override {
        float itemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x;

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
            default: difficultyText = tostring(m_selectedDifficulties.Length) + " selected"; break;
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
            if (UI::IsWindowAppearing()) {
                m_searchCombo = "";
            }

            UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
            m_searchCombo = UI::InputText("##MapTypeSearch", m_searchCombo);

            UI::Separator();

            for (uint i = 0; i < MX::m_maptypes.Length; i++) {
                string maptype = MX::m_maptypes[i];

                if (!maptype.ToLower().Contains(m_searchCombo.ToLower())) continue;

                if (UI::Selectable(maptype, m_maptype == maptype)) {
                    m_maptype = maptype;
                }
            }

            UI::EndCombo();
        }

        if (m_maptype != "Any" && UI::ResetButton()) {
            m_maptype = "Any";
        }

#if MP4
        UI::SetCenteredItemText("Title pack:");
        if (UI::BeginCombo("##TitlePackFilter", m_titlepack)) {
            if (UI::IsWindowAppearing()) {
                m_searchCombo = "";
            }

            UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
            m_searchCombo = UI::InputText("##TitlePackSearch", m_searchCombo);

            UI::Separator();

            for (uint i = 0; i < MX::m_titlepacks.Length; i++) {
                string titlepack = MX::m_titlepacks[i];

                if (!titlepack.ToLower().Contains(m_searchCombo.ToLower())) continue;

                if (UI::Selectable(titlepack, m_titlepack == titlepack)) {
                    m_titlepack = titlepack;
                }
            }

            UI::EndCombo();
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
            default: includeText = tostring(m_includedTags.Length) + " selected"; break;
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
            default: excludeText = tostring(m_excludedTags.Length) + " selected"; break;
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
        UI::SetItemTooltip("Minimum date when the map was uploaded to " + shortMXName + ", formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if (m_fromDate != "" && UI::ResetButton()) {
            m_fromDate = "";
        }

        UI::SetCenteredItemText("To:");
        m_toDate = UI::InputText("##ToDateFilter", m_toDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::DateCallback);
        UI::SetItemTooltip("Maximum date when the map was uploaded to " + shortMXName + ", formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if (m_toDate != "" && UI::ResetButton()) {
            m_toDate = "";
        }

#if MP4
        if (repo == MP4mxRepos::Trackmania) {
            UI::PaddedHeaderSeparator("Environment / Vehicle");
#else
            UI::PaddedHeaderSeparator("Vistas / Vehicle");
#endif

            if (MX::m_environments.Length > 1) {
#if MP4
                UI::SetItemText("Environment:");
#else
                UI::SetItemText("Vistas:");
#endif

                string enviText;
                switch (m_selectedEnvironments.Length) {
                    case 0: enviText = "Any"; break;
                    case 1: enviText = m_selectedEnvironments[0].Name; break;
                    default: enviText = tostring(m_selectedEnvironments.Length) + " selected"; break;
                }

                if (UI::BeginCombo("###EnviFilter", enviText)) {
                    if (UI::IsWindowAppearing()) {
                        m_searchCombo = "";
                    }

                    UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
                    m_searchCombo = UI::InputText("##EnviSearch", m_searchCombo);

                    UI::Separator();

                    for (uint i = 0; i < MX::m_environments.Length; i++) {
                        MX::MapEnvironment@ envi = MX::m_environments[i];

                        if (!envi.Name.ToLower().Contains(m_searchCombo.ToLower())) continue;

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
                    default: vehicleText = tostring(m_selectedVehicles.Length) + " selected"; break;
                }

                if (UI::BeginCombo("##VehicleFilter", vehicleText)) {
                    if (UI::IsWindowAppearing()) {
                        m_searchCombo = "";
                    }

                    UI::SetNextItemWidth(UI::GetContentRegionAvail().x - itemSpacing);
                    m_searchCombo = UI::InputText("##VehicleSearch", m_searchCombo);

                    UI::Separator();

                    for (uint i = 0; i < MX::m_vehicles.Length; i++) {
                        string vehicleName = MX::m_vehicles[i];

                        if (!vehicleName.ToLower().Contains(m_searchCombo.ToLower())) continue;

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

            UI::SetItemText("AT Status:");

            if (UI::BeginCombo("##ATStatus", tostring(m_authorTimeStatus))) {
                for (int i = -1; i <= MX::AuthorTimeStatus::Beaten; i++) {
                    MX::AuthorTimeStatus status = MX::AuthorTimeStatus(i);

                    if (UI::Selectable(tostring(status), m_authorTimeStatus == status)) {
                        m_authorTimeStatus = status;
                    }
                }

                UI::EndCombo();
            }

            UI::SetItemTooltip("The status of the Author Time for the map");
#if MP4
        }
#endif
    }

    void GetRequestParams(dictionary@ params) override {
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
        if (m_selectedEnvironments.Length > 0) {
            array<string> enviIds;

            for (uint i = 0; i < m_selectedEnvironments.Length; i++) {
                enviIds.InsertLast(tostring(m_selectedEnvironments[i].ID));
            }

            params.Set("environment", string::Join(enviIds, ","));
        }

        if (m_selectedVehicles.Length > 0) {
            params.Set("vehicle", string::Join(m_selectedVehicles, ","));
        }

        // Length

        if (m_minLength > 0) params.Set("authortimemin", tostring(m_minLength));
        if (m_maxLength > 0) params.Set("authortimemax", tostring(m_maxLength));

        if (m_authorTimeStatus != MX::AuthorTimeStatus::Any) {
            params.Set("inauthortimebeaten", tostring(int(m_authorTimeStatus)));
        }
    }

    Json::Value ToJson() override {
        Json::Value json = Json::Object();

        json["name"]             = m_name;
        json["author"]           = m_author;
        json["difficulties"]     = m_selectedDifficulties;
        json["mod"]              = m_modSearch;
        json["maptype"]          = m_maptype;
        json["titlepack"]        = m_titlepack;
        json["tagInclusive"]     = m_tagInclusiveSearch;
        json["fromDate"]         = m_fromDate;
        json["toDate"]           = m_toDate;
        json["vehicles"]         = m_selectedVehicles;
        json["minLength"]        = m_minLength;
        json["maxLength"]        = m_maxLength;
        json["authorTimeStatus"] = m_authorTimeStatus;

        array<int> enviIds;

        for (uint i = 0; i < m_selectedEnvironments.Length; i++) {
            enviIds.InsertLast(m_selectedEnvironments[i].ID);
        }

        json["environments"] = enviIds;

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
        ResetParameters();

        m_name               = json["name"];
        m_author             = json["author"];
        m_modSearch          = json["mod"];
        m_maptype            = json["maptype"];
        m_titlepack          = json["titlepack"];
        m_tagInclusiveSearch = json["tagInclusive"];
        m_fromDate           = json["fromDate"];
        m_toDate             = json["toDate"];
        m_minLength          = json["minLength"];
        m_maxLength          = json["maxLength"];
        m_authorTimeStatus   = MX::AuthorTimeStatus(int(json["authorTimeStatus"]));

        for (uint i = 0; i < json["difficulties"].Length; i++) {
            MX::Difficulties diff = MX::Difficulties(int(json["difficulties"][i]));

            m_selectedDifficulties.InsertLast(diff);
        }

        for (uint i = 0; i < json["vehicles"].Length; i++) {
            string vehicle = json["vehicles"][i];

            m_selectedVehicles.InsertLast(vehicle);
        }

        array<int> enviIds = JsonToIntArray(json["environments"]);
        array<int> tagIds = JsonToIntArray(json["includedTags"]);
        array<int> etagsIds = JsonToIntArray(json["excludedTags"]);

        for (uint i = 0; i < MX::m_environments.Length; i++) {
            int id = MX::m_environments[i].ID;

            if (enviIds.Find(id) != -1) {
                m_selectedEnvironments.InsertLast(MX::m_environments[i]);
            }

            if (m_selectedEnvironments.Length == enviIds.Length) {
                break;
            }
        }

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
