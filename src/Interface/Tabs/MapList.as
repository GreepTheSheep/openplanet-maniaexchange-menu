class MapListTab : Tab
{
    string GetLabel() override {return Icons::Kenney::InfoCircle + " MapListBase";}

    vec4 GetColor() override { return vec4(0.0f, 0.0f, 0.0f, 1); }

    void Render() override
    {
        if (UI::BeginTable("List", 5)) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Style", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn(Icons::Trophy, UI::TableColumnFlags::WidthFixed, 40);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 80);
            UI::TableHeadersRow();
			UI::EndTable();
		}
    }
}