class Tab
{
    bool IsVisible() { return true; }
    bool CanClose() { return false; }

    string GetLabel() { return ""; }

    string GetTooltip() { return ""; }

    vec4 GetColor() { return vec4(0.2f, 0.4f, 0.8f, 1); }

    void PushTabStyle()
    {
        vec4 color = GetColor();
        UI::PushStyleColor(UI::Col::Tab, color * vec4(0.5f, 0.5f, 0.5f, 0.75f));
        UI::PushStyleColor(UI::Col::TabHovered, color * vec4(1.2f, 1.2f, 1.2f, 0.85f));
        UI::PushStyleColor(UI::Col::TabActive, color);
        UI::PushStyleColor(UI::Col::TableRowBgAlt, vec4(0.10f, 0.10f, 0.10f, 1));
        UI::PushStyleColor(UI::Col::TableRowBg, vec4(0.13f, 0.13f, 0.13f, 1));
    }

    void PopTabStyle()
    {
        UI::PopStyleColor(5);
    }

    void Reload() {}

    void Render() {}
}