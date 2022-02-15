class SearchTab : MapListTab
{
    string u_search;
    uint64 u_typingStart;
    string t_selectedMode = "Track name";
    string t_paramMode = "trackname";

    bool IsVisible() override {return Setting_Tab_Search_Visible;}
    string GetLabel() override {return Icons::Search + " Search";}

    vec4 GetColor() override { return vec4(0.22f, 0.61f, 0.43f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        MapListTab::GetRequestParams(params);
        params.Set(t_paramMode, u_search);
    }

    void StartRequest() override
    {
        if (u_search.Length < 2) {
            return;
        }

        MapListTab::StartRequest();
    }

    void CheckStartRequest() override
    {
        if (m_request !is null) {
            return;
        }

        if (u_typingStart == 0) {
            return;
        }

        if (Time::Now > u_typingStart + 1000) {
            u_typingStart = 0;
            StartRequest();
        }
    }

    void RenderHeader() override
    {
        UI::SetNextItemWidth(120);
        if (UI::BeginCombo("##NamesFilter", t_selectedMode)){
            if (UI::Selectable("Track name", t_selectedMode == "Track name")){
                t_selectedMode = "Track name";
                t_paramMode = "trackname";
                Reload();
            }
            if (UI::Selectable("Author name", t_selectedMode == "Author name")){
                t_selectedMode = "Author name";
                t_paramMode = "author";
                Reload();
            }
            UI::EndCombo();
        }
        UI::SameLine();
        bool changed = false;
        u_search = UI::InputText("Search", u_search, changed);
        if (changed) {
            u_typingStart = Time::Now;
            Clear();
        }
        if (u_search != ""){
            UI::SameLine();
            if (UI::GreenButton(Icons::Random + " Random result")){
                m_useRandom = true;
                Reload();
            }
        }
    }
}