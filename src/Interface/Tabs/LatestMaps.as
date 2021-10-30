class LatestMapsTab : MapListTab
{
    
    string GetLabel() override {return Icons::ClockO + " Latest";}

    vec4 GetColor() override { return vec4(0.22f, 0.61f, 0.43f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        MapListTab::GetRequestParams(params);
		params.Set("mode", "2");
    }
}