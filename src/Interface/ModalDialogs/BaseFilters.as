class BaseFilters : ModalDialog
{
    Tab@ activeTab;

    // Presets
    Json::Value@ preset;
    string presetName;
    bool creatingPreset;
    string newName;

    // To search in combos
    string m_searchCombo;

    BaseFilters(Tab@ tab) {
        super(Icons::Filter + " " + Name + "###" + Name);
        @activeTab = tab;
    }

    string get_Name() {
        return "Base filters";
    }

    Presets::Type get_PresetType() {
        return Presets::Type::Map;
    }

    void ResetParameters() {
        @preset = null;
        presetName = "";
        newName = "";
        creatingPreset = false;
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
            startnew(CoroutineFunc(activeTab.Reload));
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

        if (creatingPreset) {
            comboName = "Create preset";
        } else if (preset !is null) {
            comboName = presetName;
        }

        if (UI::BeginCombo("##Presets", comboName)) {
            if (UI::Selectable("None", preset is null && !creatingPreset)) {
                ResetParameters();
            }

            if (UI::Selectable("Create preset", creatingPreset)) {
                creatingPreset = true;
                @preset = null;
                presetName = "";
                newName = "";
            }

            for (uint k = 0; k < keys.Length; k++) {
                if (UI::Selectable(keys[k], keys[k] == presetName)) {
                    creatingPreset = false;
                    presetName = keys[k];
                    @preset = presets[keys[k]];
                    newName = "";
                    LoadPreset(preset);
                }
            }

            UI::EndCombo();
        }

        if (preset !is null) {
            UI::SameLine();

            if (UI::GreenButton(Icons::FloppyO)) {
                Json::Value@ newPreset = ToJson();
                Presets::EditPreset(presetName, newPreset, PresetType);
            }

            UI::SetItemTooltip("Edit preset with the current filters");

            UI::SameLine();

            if (UI::RedButton(Icons::TrashO)) {
                Presets::DeletePreset(presetName, PresetType);
                ResetParameters();
            }

            UI::SetItemTooltip("Delete preset");
        }

        if (creatingPreset) {
            UI::VPadding();

            UI::SetItemText("Name: ");

            newName = UI::InputText("##PresetName", newName);

            bool nameExists = keys.Find(newName) != -1;

            UI::SameLine();

            UI::BeginDisabled(newName == "" || nameExists);

            if (UI::GreenButton(Icons::FloppyO)) {
                Json::Value@ newPreset = ToJson();
                Presets::SavePreset(newName, newPreset, PresetType);
                presetName = newName;
                @preset = newPreset;
                newName = "";
                creatingPreset = false;
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
