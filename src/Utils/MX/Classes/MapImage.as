namespace MX
{
    class MapImage
    {
        int Position;
        int Width;
        int Height;
        bool HasHighQuality;

        MapImage(const Json::Value &in json)
        {
            try {
                Position = json["Position"];
                Width = json["Width"];
                Height = json["Height"];
                HasHighQuality = json["HasHighQuality"];
            } catch {
                mxWarn("Failed to parse image info for the map: " + getExceptionInfo());
            }
        }

        Json::Value ToJson()
        {
            Json::Value json = Json::Object();

            try {
                json["Position"] = Position;
                json["Width"] = Width;
                json["Height"] = Height;
                json["HasHighQuality"] = HasHighQuality;
            } catch {
                mxWarn("Error converting map image to json for map: " + getExceptionInfo());
            }

            return json;
        }
    }
}
