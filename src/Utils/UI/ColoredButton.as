namespace UI
{
    bool RedButton(const string &in text) { return ButtonColored(text, 0.0f); }
    bool GreenButton(const string &in text) { return ButtonColored(text, 0.33f); }
    bool OrangeButton(const string &in text) { return ButtonColored(text, 0.1f); }
    bool CyanButton(const string &in text) { return ButtonColored(text, 0.5f); }
    bool PurpleButton(const string &in text) { return ButtonColored(text, 0.8f); }
    bool RoseButton(const string &in text) { return ButtonColored(text, 0.9f); }
    bool YellowButton(const string &in text) { return ButtonColored(text, 0.2f); }
    bool GoldButton(const string &in text) { return ButtonColored(text, 0.12f, 1.f, 0.7f); }
}