class MapColumns {
    float author;
    float titlepack;
    float environment;
    float vehicle;
    float length;

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
#endif

            string envi = map.EnvironmentName;
            environment = Math::Max(environment, UI::MeasureString(envi).x);

            string car = map.VehicleName.Length == 0 ? "Unknown" : map.VehicleName;
            vehicle = Math::Max(vehicle, UI::MeasureString(car).x);

            length = Math::Max(length, UI::MeasureString(map.LengthStr).x);
        }
    }

    void Reset() {
        author = 0.0f;
        titlepack = 0.0f;
        environment = 0.0f;
        vehicle = 0.0f;
        length = 0.0f;
    }
}
