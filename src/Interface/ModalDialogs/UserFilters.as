class UserFilters : ModalDialog
{
    Tab@ activeTab;

    string m_name;
    string m_login;
    string m_favId;

    // Counts
    int m_minMaps;
    int m_maxMaps;
    int m_minAwards;
    int m_maxAwards;
    int m_minAwardsGiven;
    int m_maxAwardsGiven;

    // Creation date
    string m_fromDate;
    string m_toDate;

    // Other
    bool m_supporter;
    bool m_crew;

    UserFilters(Tab@ tab) {
        super(Icons::Filter + " \\$zUser filters###UserFilters");
        m_size = vec2(800, 550);
        @activeTab = tab;
    }

    void ResetParameters() {
        m_name = "";
        m_favId = "";
        m_login = "";
        m_minMaps = 0;
        m_maxMaps = 0;
        m_minAwards = 0;
        m_maxAwards = 0;
        m_minAwardsGiven = 0;
        m_maxAwardsGiven = 0;
        m_fromDate = "";
        m_toDate = "";
        m_supporter = false;
        m_crew = false;
    }

    void RenderDialog() override {
        float scale = UI::GetScale();

        UI::PaddedHeaderSeparator("User");

        UI::SetItemText("Name:");
        m_name = UI::InputText("##NameFilter", m_name);

        if (m_name != "" && UI::ResetButton()) {
            m_name = "";
        }

        UI::SetCenteredItemText("Favorite User ID:");
        m_favId = UI::InputText("##FavIdFilter", m_favId, UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackCharFilter | UI::InputTextFlags::CallbackAlways, UI::MXIdCallback);
        UI::SetItemTooltip("The ID of one of the accounts this user has favorited.\n\nE.g., to filter by users who have Ubisoft Nadeo as one of\nits favorite users, set this to 21.");

        if (m_favId != "" && UI::ResetButton()) {
            m_favId = "";
        }

#if TMNEXT
        UI::SetItemText("Driver login:");
        m_login = UI::InputText("##LoginFilter", m_login);
        UI::SetItemTooltip("The account login of the user.\n\nNote: This refers to the unique player login ID, NOT the account name.");

        if (m_login != "" && UI::ResetButton()) {
            m_login = "";
        }
#endif

        UI::PaddedHeaderSeparator("Maps");

        UI::SetItemText("Min:");
        m_minMaps = UI::InputInt("##MinMapsFilter", m_minMaps, 0);
        UI::SetItemTooltip("Minimum amount of maps uploaded to " + shortMXName + ".");

        if (m_minMaps != 0 && UI::ResetButton()) {
            m_minMaps = 0;
        }

        UI::SetCenteredItemText("Max:");
        m_maxMaps = UI::InputInt("##MaxMapsFilter", m_maxMaps, 0);
        UI::SetItemTooltip("Maximum amount of maps uploaded to " + shortMXName + ".");

        if (m_maxMaps != 0 && UI::ResetButton()) {
            m_maxMaps = 0;
        }

        UI::PaddedHeaderSeparator("Awards received");

        UI::SetItemText("Min:");
        m_minAwards = UI::InputInt("##MinAwardsFilter", m_minAwards, 0);

        if (m_minAwards != 0 && UI::ResetButton()) {
            m_minAwards = 0;
        }

        UI::SetCenteredItemText("Max:");
        m_maxAwards = UI::InputInt("##MaxAwardsFilter", m_maxAwards, 0);

        if (m_maxAwards != 0 && UI::ResetButton()) {
            m_maxAwards = 0;
        }

        UI::PaddedHeaderSeparator("Awards given");

        UI::SetItemText("Min:");
        m_minAwardsGiven = UI::InputInt("##MinAwardsGivenFilter", m_minAwardsGiven, 0);
        UI::SetItemTooltip("Minimum amount of awards given to other users.");

        if (m_minAwardsGiven != 0 && UI::ResetButton()) {
            m_minAwardsGiven = 0;
        }

        UI::SetCenteredItemText("Max:");
        m_maxAwardsGiven = UI::InputInt("##MaxAwardsGivenFilter", m_maxAwardsGiven, 0);
        UI::SetItemTooltip("Maximum amount of awards given to other users.");

        if (m_maxAwardsGiven != 0 && UI::ResetButton()) {
            m_maxAwardsGiven = 0;
        }

        UI::PaddedHeaderSeparator("Registered at");

        UI::SetItemText("From:");
        m_fromDate = UI::InputText("##FromDateFilter", m_fromDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::DateCallback);
        UI::SetItemTooltip("Minimum date when the account was registered, formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if (m_fromDate != "" && UI::ResetButton()) {
            m_fromDate = "";
        }

        UI::SetCenteredItemText("To:");
        m_toDate = UI::InputText("##ToDateFilter", m_toDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::DateCallback);
        UI::SetItemTooltip("Maximum date when the account was registered, formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if (m_toDate != "" && UI::ResetButton()) {
            m_toDate = "";
        }

        UI::PaddedHeaderSeparator("Other");

        m_supporter = UI::Checkbox("Supporter", m_supporter);
        m_crew = UI::Checkbox(shortMXName + " Crew", m_crew);

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
        if (m_favId != "") params.Set("favoritetarget", m_favId);
#if TMNEXT
        if (m_login != "") params.Set("driverlogin", m_login);
#endif

        if (m_minMaps > 0) params.Set("mapsmin", tostring(m_minMaps));
        if (m_maxMaps > 0) params.Set("mapsmax", tostring(m_maxMaps));

        if (m_minAwards > 0) params.Set("awardsmin", tostring(m_minAwards));
        if (m_maxAwards > 0) params.Set("awardsmax", tostring(m_maxAwards));

        if (m_minAwardsGiven > 0) params.Set("awardsgivenmin", tostring(m_minAwardsGiven));
        if (m_maxAwardsGiven > 0) params.Set("awardsgivenmax", tostring(m_maxAwardsGiven));

        if (m_supporter) params.Set("insupporters", "1");
        if (m_crew) params.Set("inmoderators", "1");

        // Registration date

        if (m_fromDate != "" && Date::IsValid(m_fromDate)) {
            params.Set("registeredafter", m_fromDate);
        }

        if (m_toDate != "" && Date::IsValid(m_toDate)) {
            params.Set("registeredbefore", m_toDate);
        }
    }
}
