class UserTab : Tab
{
    int m_userId;
    bool m_isYourProfileTab;

    UserTab(const int &in userId, bool yourProfile = false) {
        m_userId = userId;
        m_isYourProfileTab = yourProfile;
    }

    bool CanClose() override { return !m_isYourProfileTab; }

    string GetLabel() override {
        if (m_isYourProfileTab) {
            return Icons::User + " Your Profile";
        } else {
            return Icons::User + " " + tostring(m_userId);
        }
        // if (m_error) {
        //     m_isLoading = false;
        //     return "\\$f00"+Icons::Times+" \\$zError";
        // }
        // if (m_map is null) {
        //     m_isLoading = true;
        //     return Icons::Map+" Loading...";
        // } else {
        //     m_isLoading = false;
        //     string res = Icons::Map+" ";
        //     if (Setting_ColoredMapName) res += ColoredString(m_map.GbxMapName);
        //     else res += m_map.Name;
        //     return res;
        // }
    }

    vec4 GetColor() override {
        if (m_isYourProfileTab) return vec4(1,0.65,0,1);
        return vec4(0,0.5,1,1);
    }

    void Render() override
    {
        UI::Text(tostring(m_userId));
    }
}