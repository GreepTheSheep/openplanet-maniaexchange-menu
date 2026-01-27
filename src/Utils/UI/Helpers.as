namespace UI
{
    // Alignment

    void CenterAlign() {
        vec2 region = UI::GetWindowSize();
        vec2 position = UI::GetCursorPos();
        UI::SetCursorPos(vec2(region.x / 2, position.y));
    }

    void SetItemText(const string &in text, int width = 300) {
        UI::AlignTextToFramePadding();
        UI::Text(text);
        UI::SameLine();
        UI::SetNextItemWidth(width - UI::MeasureString(text).x);
    }

    void SetCenteredItemText(const string &in text, int width = 300) {
        UI::SameLine();
        UI::CenterAlign();
        SetItemText(text, width);
    }

    // Padding

    void VPadding() {
        UI::Dummy(vec2(0, 10));
    }

    void VPadding(int y) {
        UI::Dummy(vec2(0, y));
    }

    void VPadding(float y) {
        UI::Dummy(vec2(0., y));
    }

    void PaddedSeparator(const string &in text) {
        UI::VPadding(5);
        UI::SeparatorText(text);
        UI::VPadding(5);
    }

    void PaddedHeaderSeparator(const string &in text) {
        UI::PushFont(Fonts::MidBold);
        UI::PaddedSeparator(text);
        UI::PopFont();
    }

    // Button

    bool ResetButton() {
        UI::SameLine();
        UI::Text(Icons::Times);
        if (UI::IsItemHovered()) UI::SetMouseCursor(UI::MouseCursor::Hand);
        UI::SetItemTooltip("Reset field");

        return UI::IsItemClicked();
    }

    vec2 MeasureButton(const string &in label) {
        vec2 text = UI::MeasureString(label);
        vec2 padding = UI::GetStyleVarVec2(UI::StyleVar::FramePadding);

        return text + padding * 2;
    }

    void RightAlignButton(float buttonWidth, int buttonCount = 1) {
        vec2 region = UI::GetContentRegionAvail();
        vec2 pos = UI::GetCursorPos();
        float itemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x;
        int spacingCount = buttonCount - 1;
        float newPos = Math::Max(region.x - buttonWidth - (itemSpacing * spacingCount), 0.0);
        UI::SetCursorPosX(pos.x + newPos);
    }

    void RightAlignButtons(float buttonsWidth, int buttonCount) {
        RightAlignButton(buttonsWidth, buttonCount);
    }
}
