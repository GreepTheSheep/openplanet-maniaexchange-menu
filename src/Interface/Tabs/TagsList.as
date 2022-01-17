class TagsListTab : MapListTab
{
    string t_tags = "";
    string t_selectedTab = "Select a tag";

    bool IsVisible() override {return Setting_Tab_Tags_Visible;}
    string GetLabel() override {return Icons::Tags + " Tags";}

    vec4 GetColor() override { return vec4(0.0f, 0.52f, 0.52f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        MapListTab::GetRequestParams(params);
        params.Set("tags", t_tags);
    }

    void RenderHeader() override
    {
        if (UI::BeginCombo("", t_selectedTab)){
            for (uint i = 0; i < MX::m_mapTags.get_Length(); i++)
            {
                MX::MapTag@ tag = MX::m_mapTags[i];
                if (UI::Selectable(tag.Name, t_selectedTab == tag.Name)){
                    if (t_selectedTab != tag.Name) {
                        t_selectedTab = tag.Name;
                        t_tags = tostring(tag.ID);  
                        Reload();
                    }
                }
            }
            UI::EndCombo();
        }
        if (t_selectedTab != "Select a tag"){
            UI::SameLine();
            if (UI::GreenButton(Icons::Random + " Random result")){
                m_useRandom = true;
                Reload();
            }
        }
    }
}