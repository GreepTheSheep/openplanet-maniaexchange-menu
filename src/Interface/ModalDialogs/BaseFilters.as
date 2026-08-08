class BaseFilters : ModalDialog
{
    Tab@ m_activeTab;

    // Presets
    Json::Value@ m_preset;
    string m_presetName;
    bool m_creatingPreset;
    string m_newName;

    // To search in combos
    string m_searchCombo;

    BaseFilters(Tab@ tab) {
        super(Icons::Filter + " " + Name + "###" + Name);
        @m_activeTab = tab;
    }

    string get_Name() {
        return "Base filters";
    }

    Presets::Type get_PresetType() {
        return Presets::Type::Map;
    }

    void ResetParameters(bool resetPreset = true) {
        if (resetPreset) {
            @m_preset = null;
            m_presetName = "";
        }

        m_newName = "";
        m_creatingPreset = false;
        m_searchCombo = "";
    }

    void GetRequestParams(dictionary@ params) { }
    void LoadPreset(Json::Value@ json) { }
    void RenderFilters() { }

    Json::Value ToJson() {
        return Json::Object();
    }

    void RenderButtons() {
        float itemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).y;

        vec2 searchButton = UI::MeasureButton(Icons::Search + " Search");
        vec2 resetButton = UI::MeasureButton(Icons::Repeat + " Reset");

        vec2 region = UI::GetContentRegionAvail();
        UI::VPadding(region.y - searchButton.y - itemSpacing);

        UI::RightAlignButtons(searchButton.x + resetButton.x, 2);

        if (UI::GreenButton(Icons::Search + " Search")) {
            startnew(CoroutineFunc(m_activeTab.Reload));
            Close();
        }

        UI::SameLine();

        if (UI::OrangeButton(Icons::Repeat + " Reset")) {
            ResetParameters();
        }
    }

    void RenderPresets() {
        if (g_Presets.GetType() == Json::Type::Null || !g_Presets.HasKey(tostring(PresetType))) {
            return;
        }

        Json::Value@ presets = g_Presets[tostring(PresetType)];

        if (presets.GetType() != Json::Type::Object) {
            return;
        }

        UI::AlignTextToFramePadding();

        UI::SetItemText("Presets:");

        array<string> keys = presets.GetKeys();

        string comboName = "None";

        if (m_creatingPreset) {
            comboName = "Create preset";
        } else if (m_preset !is null) {
            comboName = m_presetName;
        }

        if (UI::BeginCombo("##Presets", comboName)) {
            if (UI::Selectable("None", m_preset is null && !m_creatingPreset)) {
                ResetParameters();
            }

            if (UI::Selectable("Create preset", m_creatingPreset)) {
                m_creatingPreset = true;
                @m_preset = null;
                m_presetName = "";
                m_newName = "";
            }

            UI::Separator();

            for (uint k = 0; k < keys.Length; k++) {
                if (UI::Selectable(keys[k], keys[k] == m_presetName)) {
                    m_creatingPreset = false;
                    m_presetName = keys[k];
                    @m_preset = presets[keys[k]];
                    m_newName = "";
                    LoadPreset(m_preset);
                }
            }

            UI::EndCombo();
        }

        if (m_preset !is null) {
            UI::SameLine();

            if (UI::GreenButton(Icons::FloppyO)) {
                Json::Value@ newPreset = ToJson();
                Presets::EditPreset(m_presetName, newPreset, PresetType);
            }

            UI::SetItemTooltip("Edit preset with the current filters");

            UI::SameLine();

            if (UI::RedButton(Icons::TrashO)) {
                Presets::DeletePreset(m_presetName, PresetType);
                ResetParameters();
            }

            UI::SetItemTooltip("Delete preset");
        }

        if (m_creatingPreset) {
            UI::VPadding();

            UI::SetItemText("Name: ");

            m_newName = UI::InputText("##PresetName", m_newName);

            bool nameExists = keys.Find(m_newName) != -1;

            UI::SameLine();

            UI::BeginDisabled(m_newName == "" || nameExists);

            if (UI::GreenButton(Icons::FloppyO)) {
                Json::Value@ newPreset = ToJson();
                Presets::SavePreset(m_newName, newPreset, PresetType);
                m_presetName = m_newName;
                @m_preset = newPreset;
                m_newName = "";
                m_creatingPreset = false;
            }

            UI::SetItemTooltip("Save current filters as a new preset.");

            UI::EndDisabled();

            if (nameExists) UI::Text("\\$f90" + Icons::ExclamationTriangle + "\\$z A preset with that name already exists!");
        }
    }

    void RenderDialog() override {
        RenderPresets();
        RenderFilters();
        RenderButtons();
    }
}
