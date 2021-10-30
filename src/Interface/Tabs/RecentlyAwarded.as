class RecentlyAwardedTab : MapListTab
{
    
    string GetLabel() override {return Icons::Trophy + " Recently Awarded";}

    vec4 GetColor() override { return vec4(0.52f, 1.0f, 0.43f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        MapListTab::GetRequestParams(params);
		params.Set("mode", "3");
    }
}