namespace MX {
    dictionary Icons = {
        { "award",     Icons::Trophy },
        { "bronze",    Icons::Trophy },
        { "silver",    Icons::Trophy },
        { "gold",      Icons::Trophy },
        { "done",      Icons::CheckSquareO },
        { "undone",    Icons::Times },
        { "tmx",       Icons::ManiaExchange },
        { "mx",        Icons::ManiaExchange },
        { "Y",         Icons::ThumbsOUp },
        { "thdown",    Icons::ThumbsODown },
        { "heart",     Icons::Heart }
    };

    // colors taken from ManiaExchange

    const vec3 BEGINNER_COLOR = vec3(1);
    const vec3 INTERMEDIATE_COLOR = vec3(0.3, 0.8, 0.5);
    const vec3 ADVANCED_COLOR = vec3(0, 0.25, 0.8);
    const vec3 EXPERT_COLOR = vec3(1, 0, 0);
    const vec3 IMPOSSIBLE_COLOR = vec3(0);
    const vec3 LUNATIC_COLOR = vec3(0.8, 0.15, 0.7);

    const array<vec3> DIFFICULTY_COLORS = {
        BEGINNER_COLOR,
        INTERMEDIATE_COLOR,
        ADVANCED_COLOR,
        EXPERT_COLOR,
        IMPOSSIBLE_COLOR,
        LUNATIC_COLOR
    };

    void RenderDifficultyIcon(MX::Difficulties difficulty) {
        vec2 pos = UI::GetCursorPos();
        vec3 diffColor = DIFFICULTY_COLORS[int(difficulty)];

        UI::PushStyleColor(UI::Col::Text, vec4(diffColor, 0.3));

        UI::AlignTextToFramePadding();
        UI::Text(Icons::Kenney::SignalHigh);

        UI::PopStyleColor();

        UI::PushStyleColor(UI::Col::Text, vec4(diffColor, 1));

        UI::SetCursorPos(pos);

        UI::AlignTextToFramePadding();

        switch (difficulty) {
            case MX::Difficulties::Lunatic:
            case MX::Difficulties::Impossible:
                UI::Text(Icons::Kenney::SignalHigh);
                break;
            case MX::Difficulties::Expert:
            case MX::Difficulties::Advanced:
                UI::Text(Icons::Kenney::SignalMedium);
                break;
            case MX::Difficulties::Intermediate:
            case MX::Difficulties::Beginner:
            default:
                UI::Text(Icons::Kenney::SignalLow);
                break;
        }

        UI::PopStyleColor();

        UI::SetItemTooltip(tostring(difficulty));
    }
}
