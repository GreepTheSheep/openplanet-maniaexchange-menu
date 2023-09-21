class LatestMapsTab : MapListTab
{

    bool IsVisible() override {return Setting_Tab_Latest_Visible;}
    string GetLabel() override {return Icons::ClockO + " Latest";}

    vec4 GetColor() override { return vec4(0.22f, 0.61f, 0.43f, 1); }

    void GetRequestParams(dictionary@ params) override
    {
        MapListTab::GetRequestParams(params);
        params.Set("mode", "2");
    }
}