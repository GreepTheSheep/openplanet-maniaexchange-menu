class FeaturedMapsTab : MapListTab
{

    bool IsVisible() override {return Setting_Tab_Featured_Visible;}
    string GetLabel() override {return Icons::Star + " Featured";}

    vec4 GetColor() override { return vec4(0.8f, 0.09f, 0.48f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        MapListTab::GetRequestParams(params);
        params.Set("mode", "23");
    }

    void RenderHeader() override
    {
        if (UI::GreenButton(Icons::Random + " Random result")){
            m_useRandom = true;
            Reload();
        }
    }
}