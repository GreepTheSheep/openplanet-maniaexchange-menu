class FeaturedMapsTab : MapListTab
{
    
    string GetLabel() override {return Icons::Star + " Featured";}

    vec4 GetColor() override { return vec4(0.8f, 0.09f, 0.48f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        MapListTab::GetRequestParams(params);
		params.Set("mode", "23");
    }
}