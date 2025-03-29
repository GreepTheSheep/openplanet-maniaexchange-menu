class TagsListTab : MapListTab
{
    array<MX::MapTag@> m_selectedTags;
    string t_tags = "";
    string t_selectedSort = "Latest";
    string t_selectedOrder = "-1";
    bool m_tagInclusive = false;
    bool m_refresh = false;

    bool IsVisible() override {return Setting_Tab_Tags_Visible;}
    string GetLabel() override {return Icons::Tags + " Tags";}

    vec4 GetColor() override { return vec4(0.0f, 0.52f, 0.52f, 1); }

    void GetRequestParams(dictionary@ params) override
    {
        MapListTab::GetRequestParams(params);
        t_tags = "";
        for (uint i = 0; i < m_selectedTags.Length; i++)
        {
            if (i > 0) t_tags += ",";
            t_tags += tostring(m_selectedTags[i].ID);
        }
        params.Set("tag", t_tags);
        if (m_tagInclusive) params.Set("taginclusive", "true");
        if (t_selectedOrder != "-1") {
            params.Set("order1", t_selectedOrder);
        }
    }

    void StartRequest() override
    {
        if (m_selectedTags.Length == 0) {
            return;
        }

        MapListTab::StartRequest();
    }

    void RenderHeader() override
    {
        string selectedTagsNames = "";
        if (m_selectedTags.Length == 0) selectedTagsNames = "No tags selected";
        else if (m_selectedTags.Length == 1) selectedTagsNames = m_selectedTags[0].Name;
        else if (m_selectedTags.Length == MX::m_mapTags.Length) selectedTagsNames = "All tags selected";
        else if (m_selectedTags.Length > 3) selectedTagsNames = m_selectedTags.Length + " tags selected";
        else {
            for (uint i = 0; i < m_selectedTags.Length; i++)
            {
                if (i > 0) selectedTagsNames += ", ";
                selectedTagsNames += m_selectedTags[i].Name;
            }
        }
        if (UI::CollapsingHeader("Tags ("+selectedTagsNames+")###TagsHeader")) {
            for (uint i = 0; i < MX::m_mapTags.Length; i++) {
                MX::MapTag@ tag = MX::m_mapTags[i];
                UI::PushID("TagBtn"+i);
                bool IsSelected = m_selectedTags.FindByRef(tag) != -1;
                IsSelected = UI::Checkbox(tag.Name, IsSelected);
                if (IsSelected) {
                    if (m_selectedTags.FindByRef(tag) == -1) {
                        m_selectedTags.InsertLast(tag);
                        m_refresh = true;
                    }
                } else {
                    if (m_selectedTags.FindByRef(tag) != -1) {
                        m_selectedTags.RemoveAt(m_selectedTags.FindByRef(tag));
                        m_refresh = true;
                    }
                }
                UI::PopID();
            }
        } else if (m_refresh) {
            m_refresh = false;
            Reload();
        }
        bool selectedTagInc = UI::Checkbox("Tag inclusive search", m_tagInclusive);
        UI::SetItemTooltip("If checked, maps must contain all selected tags.");
        if (selectedTagInc != m_tagInclusive) {
            m_tagInclusive = selectedTagInc;
            Reload();
        }
        UI::SameLine();
        UI::SetNextItemWidth(150);
        if (UI::BeginCombo("##TagListFilter", t_selectedSort)){
            if (UI::Selectable("Latest", t_selectedSort == "Latest")){
                t_selectedSort = "Latest";
                t_selectedOrder = "-1";
                Reload();
            }
            if (UI::Selectable("Most Awarded", t_selectedSort == "Most Awarded")){
                t_selectedSort = "Most Awarded";
                t_selectedOrder = "12";
                Reload();
            }
            UI::EndCombo();
        }
        UI::SameLine();
        MapListTab::RenderHeader();

        UI::Separator();
    }
}