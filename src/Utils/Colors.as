namespace Colors {
    // we can't get the background color for different context but this is the color
    // used in table rows, which is where the colored names will be rendered
    const vec3 BACKGROUND_COLOR  = vec3(0.13f, 0.13f, 0.13f);

    float GetLuminosity(vec3 color) {
        return color.x * 0.2126 + color.y * 0.7152 + color.z * 0.0722;
    }

    float GetContrastRatio(vec3 color1, vec3 color2) {
        float lum1 = GetLuminosity(color1);
        float lum2 = GetLuminosity(color2);

        return (Math::Max(lum1, lum2) + 0.05) / (Math::Min(lum1, lum2) + 0.05);
    }

    vec3 HexToRGB(string _code) {
        if (_code.StartsWith("$")) {
            _code = _code.Replace("$", "#");
        }

        vec4 hexColor = Text::ParseHexColor(_code);

        return hexColor.xyz;
    }

    // For anyone reusing this code: FormatGameColor adds $ at the start of the string
    string FixColorCodeContrast(const string &in colorCode) {
        vec3 color = HexToRGB(colorCode);

        float steps = 0.05f;

        if (GetLuminosity(BACKGROUND_COLOR) > 0.5) {
            steps *= -1;
        }

        int attempts = 0;

        while (GetContrastRatio(color, BACKGROUND_COLOR) < 4.5f && attempts < 50) {
            color.x = Math::Clamp(color.x + steps, 0., 1.);
            color.y = Math::Clamp(color.y + steps, 0., 1.);
            color.z = Math::Clamp(color.z + steps, 0., 1.);

            attempts++;
        }

        return Text::FormatGameColor(color);
    }

    string AdjustTextContrast(string _text) {
        Regex::SearchAllResult@ results = Regex::SearchAll(_text, "\\$[0-9a-f]{3}", Regex::Flags::ECMAScript | Regex::Flags::CaseInsensitive);

        for (uint r = 0; r < results.Length; r++) {
            string match = results[r][0];
            _text = _text.Replace(match, FixColorCodeContrast(match));
        }

        return _text;
    }
}
