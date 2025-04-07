vec2 itemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing);

class MapColumns {
    float author;
    float titlepack;
    float enviVehicle;

    void Update(array<MX::MapInfo@> maps) {
        if (maps.IsEmpty()) {
            Reset();
            return;
        }

        for (uint i = 0; i < maps.Length; i++) {
            MX::MapInfo@ map = maps[i];

            author = Math::Max(author, Draw::MeasureString(map.Username).x);
#if MP4
            titlepack = Math::Max(titlepack, Draw::MeasureString(map.TitlePack).x);

            string envi = map.EnvironmentName.Length == 0 ? "Unknown" : map.EnvironmentName;
            string car = map.VehicleName.Length == 0 ? "Unknown" : map.VehicleName;
            string enviVehicleStr = envi + "/" + car;

            enviVehicle = Math::Max(enviVehicle, Draw::MeasureString(enviVehicleStr).x);
#endif
        }
    }

    void Reset() {
        author = 0.0f;
        titlepack = 0.0f;
        enviVehicle = 0.0f;
    }
}
