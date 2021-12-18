class HomePageTab : Tab {
    string GetLabel() override { return Icons::Home; }

    vec4 GetColor() override { return pluginColorVec; }

    void Render() override {
        UI::Text(pluginName);
    }
}