namespace MX {
    class MapEmbeddedObject {
        int ID;
        string ObjectPath;
        string ObjectAuthor;
        string Name;
        bool onIX;
        int UserId;
        string Username;

        MapEmbeddedObject(const Json::Value &in json) {
            try {
                ObjectPath = json["ObjectPath"];
                ObjectAuthor = json["ObjectAuthor"];
                onIX = json["onIX"];

                Name = Path::GetFileName(ObjectPath); // TODO temp fix, change to json["Name"] once it's added

                if (json["Author"].GetType() != Json::Type::Null) {
                    UserId = json["Author"]["UserId"];
                    Username = json["Author"]["Name"];
                }
            } catch {
                Logging::Warn("Error parsing embedded object info for the map: " + getExceptionInfo(), true);
            }
        }

        bool get_IsOnItemExchange() { return onIX; }

        string get_Url() {
            if (!IsOnItemExchange) {
                return "";
            }

            return "https://item.exchange/itemsearch?filename=" + Net::UrlEncode(Name) + "&authorlogin=" + Net::UrlEncode(ObjectAuthor);
        }
    }
}