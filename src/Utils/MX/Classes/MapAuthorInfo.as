namespace MX
{
    class MapAuthorInfo
    {
        int UserID;
        string Username;
        string Role;
        bool Uploader;

        MapAuthorInfo(const Json::Value &in json)
        {
            try {
                UserID = json["UserID"];
                Username = json["Username"];
                Role = json["Role"];
                Uploader = json["Uploader"];
            } catch {
                mxWarn("Error parsing author info for the map: " + getExceptionInfo(), true);
            }
        }
    }
}