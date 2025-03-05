namespace MX
{
    class MapAuthorInfo
    {
        int UserId;
        string Name;
        string Role;
        bool Uploader;

        MapAuthorInfo(const Json::Value &in json, bool uploader = false)
        {
            try {
                UserId = json["User"]["UserId"];
                Name = json["User"]["Name"];
                Role = json["Role"];
                Uploader = uploader;
            } catch {
                mxWarn("Error parsing author info for the map: " + getExceptionInfo(), true);
            }
        }

        Json::Value ToJson()
        {
            Json::Value json = Json::Object();
            Json::Value userObject = Json::Object();
            try {
                userObject["UserId"] = UserId;
                userObject["Name"] = Name;

                json["User"] = userObject;
                json["Role"] = Role;
            } catch {
                mxWarn("Error converting map author info to json for author " + Name + ": " + getExceptionInfo(), true);
            }

            return json;
        }
    }
}