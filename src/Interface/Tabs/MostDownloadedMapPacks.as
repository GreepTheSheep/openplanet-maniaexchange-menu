class MostDownloadedMapPacks : MapPackListTab
{
    
    bool IsVisible() override {return Setting_Tab_MostDownloadedPacks_Visible;}
    string GetLabel() override {return Icons::Inbox + " Most Downloaded Map Packs";}

    vec4 GetColor() override { return vec4(0.22f, 0.61f, 0.43f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        MapPackListTab::GetRequestParams(params);
        params.Set("priord", "13");
    }

    void RenderHeader() override
    {
        if (UI::GreenButton(Icons::Random + " Random result")){
            m_useRandom = true;
            Reload();
        }
    }
}