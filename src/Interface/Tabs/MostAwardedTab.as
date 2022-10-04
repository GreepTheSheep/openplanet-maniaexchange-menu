class MostAwardedTab : MapListTab
{
    string t_selectedDate = "This Week";
    string t_selectedMode = "4";

    bool IsVisible() override {return Setting_Tab_MostAwarded_Visible;}
    string GetLabel() override {return Icons::Trophy + " Most Awarded Maps";}

    vec4 GetColor() override { return vec4(0.38f, 0.1f, 0.79f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        MapListTab::GetRequestParams(params);
        params.Set("priord", "8");
        params.Set("mode", t_selectedMode);
    }

    void RenderHeader() override
    {
        if (UI::BeginCombo("##MostAwardDateFilter", t_selectedDate)){
            if (UI::Selectable("All Time", t_selectedDate == "All Time")){
                t_selectedDate = "All Time";
                t_selectedMode = "0";
                Reload();
            }
            if (UI::Selectable("This Week", t_selectedDate == "This Week")){
                t_selectedDate = "This Week";
                t_selectedMode = "4";
                Reload();
            }
            if (UI::Selectable("This Month", t_selectedDate == "This Month")){
                t_selectedDate = "This Month";
                t_selectedMode = "5";
                Reload();
            }
            UI::EndCombo();
        }
        UI::SameLine();
        MapListTab::RenderHeader();
    }
}