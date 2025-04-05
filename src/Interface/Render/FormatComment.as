namespace IfaceRender
{
    void MXComment(const string &in comment){
        string formatted = "";

        formatted =
            comment.Replace("[tmx]", "Trackmania\\$075Exchange\\$z")
                .Replace("[mx]", "Mania\\$09FExchange\\$z")
                .Replace("[i]", "*")
                .Replace("[/i]", "*")
                .Replace("[u]", "__")
                .Replace("[/u]", "__")
                .Replace("[s]", "~~")
                .Replace("[/s]", "~~")
                .Replace("[hr]", "")
                .Replace("[list]", "\n")
                .Replace("[/list]", "\n")
                .Replace("&nbsp;", " ")
                .Replace("\r", "  ");

        // bold text replacement
        formatted = Regex::Replace(formatted, "\\[b\\] *?(.*?) *?\\[\\/b\\]", "**$1**");

        // url regex replacement: https://regex101.com/r/UcN0NN/1
        formatted = Regex::Replace(formatted, "\\[url=([^\\]]*)\\]([^\\[]*)\\[\\/url\\]", "[$2]($1)");

        // img replacement: https://regex101.com/r/WafxU9/1
        formatted = Regex::Replace(formatted, "\\[img\\]([^\\[]*)\\[\\/img\\]", "( Image: $1 )");

        // item replacement: https://regex101.com/r/c9LwXn/1
        formatted = Regex::Replace(formatted, "\\[item\\]([^\\r^\\n]*)", "- $1");

        // quote replacement: https://regex101.com/r/kuI7TO/1
        formatted = Regex::Replace(formatted, "\\[quote\\]([^\\[]*)\\[\\/quote\\]", "> $1");

        // youtube replacement
        formatted = Regex::Replace(formatted, "\\[youtube\\]([^\\[]*)\\[\\/youtube\\]", "[Youtube video]($1)");

        // user replacement
        formatted = Regex::Replace(formatted, "\\[user\\]([^\\[]*)\\[\\/user\\]", "( User ID: $1 )");

        // track replacement
        formatted = Regex::Replace(formatted, "\\[track\\]([^\\[]*)\\[\\/track\\]", "( Track ID: $1 )");
        formatted = Regex::Replace(formatted, "\\[track=([^\\]]*)\\]([^\\[]*)\\[\\/track\\]", "( Track ID: $2 )");

        // align replacement
        formatted = Regex::Replace(formatted, "\\[align=([^\\]]*)\\]([^\\[]*)\\[\\/align\\]", "$2");

        UI::Markdown(formatted);
    }
}