class InfoTab : Tab
{
    string GetLabel() override {return Icons::Kenney::InfoCircle + " Info";}

    vec4 GetColor() override { return vec4(0.0f, 0.0f, 0.0f, 0); }

    void Render() override
    {
        UI::Text("Map List");
    }
}