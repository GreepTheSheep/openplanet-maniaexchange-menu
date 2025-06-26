namespace Format {
    const int regexFlags = Regex::Flags::ECMAScript | Regex::Flags::CaseInsensitive;

    string MXText(const string &in comment)
    {
        if (comment.Length == 0) {
            return comment;
        }

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
        formatted = Regex::Replace(formatted, "\\[b\\] *?(.*?) *?\\[\\/b\\]", "**$1**", regexFlags);

        // automatic links. See https://daringfireball.net/projects/markdown/syntax#autolink
        formatted = Regex::Replace(formatted, "(https?:\\/\\/(?:www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b(?:[-a-zA-Z0-9()@:%_\\+.~#?&//=]*))", "<$1>", regexFlags);

        // url regex replacement: https://regex101.com/r/UcN0NN/1
        formatted = Regex::Replace(formatted, "\\[url=([^\\]]*)\\]([^\\[]*)\\[\\/url\\]", "[$2]($1)", regexFlags);

        // img replacement: https://regex101.com/r/WafxU9/1
        formatted = Regex::Replace(formatted, "\\[img\\]([^\\[]*)\\[\\/img\\]", "( Image: $1 )", regexFlags);

        // item replacement: https://regex101.com/r/c9LwXn/1
        formatted = Regex::Replace(formatted, "\\[item\\]([^\\r^\\n]*)", "- $1", regexFlags);

        // quote replacement: https://regex101.com/r/kuI7TO/1
        formatted = Regex::Replace(formatted, "\\[quote\\]([^\\[]*)\\[\\/quote\\]", "> $1", regexFlags);

        // youtube replacement
        formatted = Regex::Replace(formatted, "\\[youtube\\]([^\\[]*)\\[\\/youtube\\]", "[Youtube video]($1)", regexFlags);

        // user replacement
        formatted = Regex::Replace(formatted, "\\[user\\]([^\\[]*)\\[\\/user\\]", "( User ID: $1 )", regexFlags);

        // track replacement
        formatted = Regex::Replace(formatted, "\\[track\\]([^\\[]*)\\[\\/track\\]", "( Track ID: $1 )", regexFlags);
        formatted = Regex::Replace(formatted, "\\[track=([^\\]]*)\\]([^\\[]*)\\[\\/track\\]", "( Track ID: $2 )", regexFlags);

        // align replacement
        formatted = Regex::Replace(formatted, "\\[align=([^\\]]*)\\]([^\\[]*)\\[\\/align\\]", "$2", regexFlags);

        Regex::SearchAllResult@ results = Regex::SearchAll(formatted, "[(:](\\w+)[):]");

        for (uint r = 0; r < results.Length; r++) {
            string[] result = results[r]; // TODO remove when the new OP version is released
            string match = result[0];
            string shortname = result[1];

            if (MX::Icons.Exists(shortname)) {
                formatted = formatted.Replace(match, string(MX::Icons[shortname]));
            }
        }

        return formatted;
    }

    string GithubChangelog(string _body)
    {
        // Directs urls
        _body = Regex::Replace(_body, "(https?:\\/\\/[^\\[ ]*)", "[" + Icons::ExternalLink + " $1]($1)", regexFlags);

        // Issues links
        _body = Regex::Replace(_body, "\\(?#([0-9]+)\\)?", "[#$1]("+repoURL+"/issues/$1)");

        return _body;
    }

    string GbxText(const string &in name)
    {
        // remove BOMs and newlines
        string text = Regex::Replace(name, "[\u200B-\u200F\uFEFF\\n]", "");

        array<string> formatCodes = Regex::Search(text, "^(\\$([0-9a-f]{1,3}|[gimnostuwz<>]|[hlp](\\[[^\\]]+\\])?) *)+", regexFlags);

        if (formatCodes.Length > 0) {
            text = text.Replace(formatCodes[0], formatCodes[0].Replace(" ", ""));
        }

        return text;
    }
}
