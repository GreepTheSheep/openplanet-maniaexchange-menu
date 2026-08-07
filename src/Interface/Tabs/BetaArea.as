class BetaAreaTab : MapListTab
{
    bool IsVisible() override { return Setting_Tab_BetaArea_Visible; }

    string GetLabel() override { return Icons::Flask + " Beta Area"; }

    vec4 GetColor() override { return vec4(0.12f, 0.55f, 1.0f, 1); }

    void GetRequestParams(dictionary@ params) override
    {
        MapListTab::GetRequestParams(params);
        params.Set("inbeta", "1");
    }
}
