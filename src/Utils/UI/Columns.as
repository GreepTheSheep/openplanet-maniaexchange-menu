class MapColumns {
    float author;
    float titlepack;
    float enviVehicle;

    void Update(array<MX::MapInfo@> maps) {
        Reset();

        uint start = Time::Now;

        foreach (MX::MapInfo@ map : maps) {
            if (Time::Now > start + 50) {
                start = Time::Now;
                yield();
            }

            author = Math::Max(author, UI::MeasureString(map.Username).x);
#if MP4
            titlepack = Math::Max(titlepack, UI::MeasureString(map.TitlePack).x);

            string envi = map.EnvironmentName.Length == 0 ? "Unknown" : map.EnvironmentName;
            string car = map.VehicleName.Length == 0 ? "Unknown" : map.VehicleName;
            string enviVehicleStr = envi + "/" + car;

            enviVehicle = Math::Max(enviVehicle, UI::MeasureString(enviVehicleStr).x);
#endif
        }
    }

    void Reset() {
        author = 0.0f;
        titlepack = 0.0f;
        enviVehicle = 0.0f;
    }
}
