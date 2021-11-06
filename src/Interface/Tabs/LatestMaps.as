class LatestMapsTab : MapListTab
{
    
    bool IsVisible() override {return Setting_Tab_Latest_Visible;}
    string GetLabel() override {return Icons::ClockO + " Latest";}

    vec4 GetColor() override { return vec4(0.22f, 0.61f, 0.43f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        MapListTab::GetRequestParams(params);
		params.Set("mode", "2");
    }

    void RenderHeader() override
    {
        if (UI::GreenButton(Icons::Random + " Random result")){
            m_useRandom = true;
            Reload();
        }
    }
}