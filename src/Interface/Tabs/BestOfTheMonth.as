class BestOfTheMonthTab : MapListTab
{
    
    string GetLabel() override {return Icons::Trophy + " Best Of The Month";}

    vec4 GetColor() override { return vec4(0.38f, 0.1f, 0.79f, 1); }

    void GetRequestParams(dictionary@ params)
    {
        MapListTab::GetRequestParams(params);
		params.Set("priord", "8");
		params.Set("mode", "5");
    }
}