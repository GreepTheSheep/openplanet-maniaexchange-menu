namespace MX
{
    class SortingOrder
    {
        int Key;
        string Name;

        SortingOrder(const Json::Value &in json)
        {
            try {
                Key = json["Key"];
                Name = json["Name"];
            } catch {
                Name = json["Name"];
                Logging::Warn("Error parsing sorting order " + Name + ": " + getExceptionInfo());
            }
        }
    }
}
