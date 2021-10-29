class LatestMapsTab : MapListTab
{
    
    string GetLabel() override {return Icons::ClockO + " Latest";}

    vec4 GetColor() override { return vec4(0.0f, 0.0f, 0.0f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        MapListTab::GetRequestParams(params);
		params.Set("mode", "2");
    }
}