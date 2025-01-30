namespace MX
{
    class MapTag
    {
        int ID;
        string Name;
        string Color;

        MapTag(const Json::Value &in json)
        {
            try {
                ID = json["ID"];
                Name = json["Name"];
                Color = json["Color"];
            } catch {
                Name = json["Name"];
                mxWarn("Error parsing tag " + Name + ": " + getExceptionInfo());
            }
        }
    }
}