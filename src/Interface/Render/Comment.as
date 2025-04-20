namespace IfaceRender
{
    void MapComment(MX::MapComment@ comment)
    {
        UI::PushStyleColor(UI::Col::Border, vec4(1));
        UI::PushStyleVar(UI::StyleVar::ChildBorderSize, 1);
        UI::PushStyleVar(UI::StyleVar::ChildRounding, 5.0);

        UI::BeginChild("MapComment"+comment.Id, vec2(UI::GetContentRegionAvail().x, 0), UI::ChildFlags::Border | UI::ChildFlags::AutoResizeY);

        UI::Text(comment.Username);
        UI::SetItemTooltip("Click to view " + comment.Username + "'s profile");
        if (UI::IsItemClicked()) mxMenu.AddTab(UserTab(comment.UserId), true);

        if (comment.HasAwarded) {
            UI::SameLine();
            UI::Text("· \\$FD0" + Icons::Trophy);
            UI::SetItemTooltip("User has awarded this map");
        }

        if (comment.IsAuthor) {
            UI::SameLine();
            UI::Text("· " + Icons::Wrench);
            UI::SetItemTooltip("User is a map author");
        }

        UI::SameLine();
        vec2 cursor = UI::GetCursorPos();
        vec2 region = UI::GetContentRegionAvail();
        string timeFormatted = Time::FormatString("%d %b %Y at %R", comment.PostedAt);
        UI::SetCursorPos(cursor + vec2(region.x - Draw::MeasureString(timeFormatted).x, 0));
        UI::Text(timeFormatted);

        UI::Separator();

        UI::Markdown(comment.Comment);

        UI::EndChild();
        UI::PopStyleVar(2);
        UI::PopStyleColor();
    }
}
