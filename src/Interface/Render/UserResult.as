namespace IfaceRender
{
    void UserResult(MX::UserInfo@ user)
    {
        UI::TableNextRow();

        UI::TableNextColumn();
        UI::AlignTextToFramePadding();
        UI::Text(user.Name);
        UI::MXUserAvatarTooltip(user.UserId);
        if (UI::IsItemClicked()) mxMenu.AddTab(UserTab(user), true);

        UI::TableNextColumn();
        UI::Text(Time::FormatString("%d %b %Y at %R", user.RegisteredTimestamp));

        UI::TableNextColumn();
        UI::Text(tostring(user.MapCount));

        UI::TableNextColumn();
        UI::Text(tostring(user.MappackCount));

        UI::TableNextColumn();
        UI::Text(tostring(user.ReplayCount));

        UI::TableNextColumn();
        UI::Text(tostring(user.CommentsReceivedCount));

        UI::TableNextColumn();
        UI::Text(tostring(user.CommentsGivenCount));

        UI::TableNextColumn();
        UI::Text(tostring(user.AwardsReceivedCount));

        UI::TableNextColumn();
        UI::Text(tostring(user.AwardsGivenCount));

        UI::TableNextColumn();
        UI::Text(tostring(user.FavoritesReceivedCount));

        UI::TableNextColumn();
        UI::Text(tostring(user.AchievementCount));

        UI::TableNextColumn();

        if (UI::CyanButton(Icons::Kenney::InfoCircle)) {
            mxMenu.AddTab(UserTab(user), true);
        }

        UI::MXUserAvatarTooltip(user.UserId);
    }
}
