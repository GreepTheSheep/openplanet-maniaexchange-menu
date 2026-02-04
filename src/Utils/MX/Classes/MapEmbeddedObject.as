namespace MX {
    class MapEmbeddedObject {
        int ID;
        string ObjectPath;
        string ObjectAuthor;
        string Name;
        bool onIX;
        int UserId;
        string Username;

        bool m_loading;
        bool m_error;
        bool m_skipId;

        MapEmbeddedObject(const Json::Value &in json, bool willFetchID = true) {
            try {
                ObjectPath = json["ObjectPath"];
                ObjectAuthor = json["ObjectAuthor"];
                onIX = json["onIX"];

                Name = Path::GetFileName(ObjectPath); // TODO temp fix, change to json["Name"] once it's added

                if (json["Author"].GetType() != Json::Type::Null) {
                    UserId = json["Author"]["UserId"];
                    Username = json["Author"]["Name"];
                }

                if (IsOnItemExchange && willFetchID) {
                    startnew(CoroutineFunc(TryGetID));
                } else {
                    m_skipId = true;
                }
            } catch {
                Logging::Warn("Error parsing embedded object info for the map: " + getExceptionInfo(), true);
            }
        }

        bool get_IsOnItemExchange() { return onIX; }
        bool get_IsLoading()        { return m_loading; }
        bool get_LoadingError()     { return m_error; }
        bool get_Skipped()          { return m_skipId; }

        void TryGetID() {
            try {
                m_loading = true;

                string url = "https://item.exchange/itemsearch/search?api=on&format=json&filename=" + Net::UrlEncode(Name) + "&authorlogin=" + Net::UrlEncode(ObjectAuthor);
                Logging::Debug("MapEmbeddedObject::StartRequest (TryGetID): "+url);

                Net::HttpRequest@ req = API::Get(url);

                while (!req.Finished()) {
                    yield();
                }

                string res = req.String();
                auto json = req.Json();

                m_loading = false;

                Logging::Debug("MapEmbeddedObject::CheckRequest (TryGetID): " + res);

                if (json.GetType() == Json::Type::Null || !json.HasKey("results")) {
                    Logging::Debug("MapEmbeddedObject::CheckRequest (TryGetID): Error parsing response");
                    m_error = true;
                    return;
                }

                if (req.ResponseCode() >= 400 || json["results"].Length == 0) {
                    onIX = false;
                    return;
                }

                ID = json["results"][0]["ID"];
                Logging::Trace("Object ID found for " + ObjectPath + ": " + ID);
            } catch {
                Logging::Warn("Failed to fetch object ID from ItemExchange: " + getExceptionInfo());
                m_loading = false;
                m_error = true;
            }
        }
    }
}