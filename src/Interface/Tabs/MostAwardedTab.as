class MostAwardedTab : MapListTab
{
    bool IsVisible() override { return Setting_Tab_MostAwarded_Visible; }
    string GetLabel() override { return Icons::Trophy + " Most Awarded"; }

    vec4 GetColor() override { return vec4(0.38f, 0.1f, 0.79f, 1); }

    MostAwardedTab() {
        m_sortingName = "This Week";
        m_sortingKey = 42;
    }

    void GetRequestParams(dictionary@ params) override
    {
        MapListTab::GetRequestParams(params);
        if (m_sortingKey != 12) params.Set("order2", "12");
    }

    void RenderSortingOrders() override
    {
        UI::AlignTextToFramePadding();

        UI::Text("Sort:");
        UI::SameLine();
        UI::SetNextItemWidth(150);
        if (UI::BeginCombo("##MapSortOrders", m_sortingName)) {
            if (UI::Selectable("This Week", m_sortingName == "This Week")) {
                m_sortingName = "This Week";
                m_sortingKey = 42;
                Reload();
            }
            if (UI::Selectable("This Month", m_sortingName == "This Month")) {
                m_sortingName = "This Month";
                m_sortingKey = 44;
                Reload();
            }
            if (UI::Selectable("All Time", m_sortingName == "All Time")) {
                m_sortingName = "All Time";
                m_sortingKey = 12;
                Reload();
            }
            UI::EndCombo();
        }
    }
}
