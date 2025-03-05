class MostAwardedTab : MapListTab
{
    string t_selectedDate = "This Week";
    string t_selectedMode = "42";

    bool IsVisible() override {return Setting_Tab_MostAwarded_Visible;}
    string GetLabel() override {return Icons::Trophy + " Most Awarded Maps";}

    vec4 GetColor() override { return vec4(0.38f, 0.1f, 0.79f, 1); }

    void GetRequestParams(dictionary@ params) override
    {
        MapListTab::GetRequestParams(params);
        params.Set("order1", t_selectedMode);
        if (t_selectedDate != "All Time") params.Set("order2", "12");
    }

    void RenderHeader() override
    {
        UI::SetNextItemWidth(150);
        if (UI::BeginCombo("##MostAwardDateFilter", t_selectedDate)){
            if (UI::Selectable("This Week", t_selectedDate == "This Week")){
                t_selectedDate = "This Week";
                t_selectedMode = "42";
                Reload();
            }
            if (UI::Selectable("This Month", t_selectedDate == "This Month")){
                t_selectedDate = "This Month";
                t_selectedMode = "44";
                Reload();
            }
            if (UI::Selectable("All Time", t_selectedDate == "All Time")){
                t_selectedDate = "All Time";
                t_selectedMode = "12";
                Reload();
            }
            UI::EndCombo();
        }
        UI::SameLine();
        MapListTab::RenderHeader();
    }
}