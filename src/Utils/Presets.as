namespace Presets {
    enum Type {
        Map,
        Mappack,
        User
    }

    void SavePreset(const string &in name, const Json::Value &in filters, Type presetType, bool edit = false) {
        const string typeName = tostring(presetType);

        if (filters.GetType() != Json::Type::Object) {
            Logging::Error("Invalid JSON type for preset filters. Expected object, received " + tostring(filters.GetType()));
            return;
        }

        switch (presetType) {
            case Type::Map:
            case Type::Mappack:
            case Type::User:
                Logging::Info("Saving " + typeName + " preset \"" + name + "\" to file.");
                Logging::Debug(Json::Write(filters, true));
                break;
            default:
                Logging::Error("Unknown preset type " + typeName + " passed to Save function. Ignoring...");
                return;
        }

        if (g_Presets.GetType() == Json::Type::Null) {
            Logging::Debug("Failed to find presets file when saving preset. Creating...");
            CreatePresetsFile();
        } else if (!edit && g_Presets[typeName].HasKey(name)) {
            Logging::Warn("Trying to add " + typeName + " preset \"" + name + "\" when one with that name already exists!");
            return;
        }

        g_Presets[typeName][name] = filters;
        UpdatePresetsFile();
    }

    void EditPreset(const string &in name, const Json::Value &in filters, Type presetType) {
        SavePreset(name, filters, presetType, true);
    }

    void DeletePreset(const string &in name, Type presetType) {
        const string typeName = tostring(presetType);

        switch (presetType) {
            case Type::Map:
            case Type::Mappack:
            case Type::User:
                Logging::Info("Deleting " + typeName + " preset \""+ name +"\".");
                break;
            default:
                Logging::Error("Unknown preset type " + typeName + " passed to Delete function. Ignoring...");
                return;
        }

        if (g_Presets.GetType() == Json::Type::Null) {
            Logging::Warn("Trying to delete preset when presets file doesn't exist. Please report this to the devs.");
            return;
        }
        
        if (!g_Presets[typeName].HasKey(name)) {
            Logging::Error("Presets file doesn't have a preset called \"" + name + "\"");
            return;
        }

        g_Presets[typeName].Remove(name);
        UpdatePresetsFile();
    }

    void CreatePresetsFile() {
        Logging::Debug("Creating presets file.");

        g_Presets["Map"] = Json::Object();
        g_Presets["Mappack"] = Json::Object();
        g_Presets["User"] = Json::Object();

        Json::ToFile(PresetsLocation, g_Presets);
    }

    void UpdatePresetsFile() {
        Logging::Debug("Updating presets file.");
        Logging::Debug(Json::Write(g_Presets, true));

        Json::ToFile(PresetsLocation, g_Presets);
    }

    void LoadPresets() {
        if (!IO::FileExists(PresetsLocation)) {
            CreatePresetsFile();
            return;
        }

        Logging::Debug("Loading presets file.");

        g_Presets = Json::FromFile(PresetsLocation);
    }
}
