class TOTDTab : MapListTab
{
    bool IsVisible() override {return Setting_Tab_TOTD_Visible;}
    string GetLabel() override {return Icons::Calendar + " Tracks of the Day";}

    vec4 GetColor() override { return vec4(0.04f, 0.79f, 0.88f, 1); }

    void GetRequestParams(dictionary@ params) override
    {
        MapListTab::GetRequestParams(params);
        params.Set("mode", "25");
    }
}