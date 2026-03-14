namespace IfaceRender
{
    void UserResult(MX::UserInfo@ user)
    {
        UI::TableNextRow();

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();
            UI::Text(user.Name);

            UI::MXUserAvatarTooltip(user.UserId);

            if (UI::IsItemClicked()) {
                mxMenu.AddTab(UserTab(user), true);
            }
        }

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();
            UI::Text(Time::FormatString("%d %b %Y at %R", user.RegisteredTimestamp));
        }

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();
            UI::Text(tostring(user.MapCount));
        }

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();
            UI::Text(tostring(user.MappackCount));
        }

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();
            UI::Text(tostring(user.ReplayCount));
        }

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();
            UI::Text(tostring(user.AwardsReceivedCount));
        }

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();
            UI::Text(tostring(user.AwardsGivenCount));
        }

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();
            UI::Text(tostring(user.CommentsReceivedCount));
        }

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();
            UI::Text(tostring(user.CommentsGivenCount));
        }

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();
            UI::Text(tostring(user.FavoritesReceivedCount));
        }

        if (UI::TableNextColumn()) {
            UI::AlignTextToFramePadding();
            UI::Text(tostring(user.AchievementCount));
        }

        if (UI::TableNextColumn()) {
            if (UI::CyanButton(Icons::Kenney::InfoCircle)) {
                mxMenu.AddTab(UserTab(user), true);
            }

            UI::MXUserAvatarTooltip(user.UserId);
        }
    }
}
