namespace MX
{
    class MapEmbeddedObject
    {
        int ID;
        string ObjectPath;
        string ObjectAuthor;
        string Name;
        bool onIX;
        int UserId;
        string Username;

        MapEmbeddedObject(const Json::Value &in json, bool willFetchID = true)
        {
            try {
                ObjectPath = json["ObjectPath"];
                ObjectAuthor = json["ObjectAuthor"];
                onIX = json["onIX"];

                Name = Path::GetFileName(ObjectPath); // TODO temp fix, change to json["Name"] once it's added

                if (json["Author"].GetType() != Json::Type::Null) {
                    UserId = json["Author"]["UserId"];
                    Username = json["Author"]["Name"];
                }

                if (!onIX) ID = 0;
                else if (willFetchID) startnew(CoroutineFunc(TryGetID));
                else ID = -2;
            } catch {
                Logging::Warn("Error parsing embedded object info for the map: " + getExceptionInfo(), true);
            }
        }

        void TryGetID()
        {
            string url = "https://item.exchange/itemsearch/search?api=on&format=json&filename=" + Net::UrlEncode(Name) + "&authorlogin=" + Net::UrlEncode(ObjectAuthor);
            Logging::Debug("MapEmbeddedObject::StartRequest (TryGetID): "+url);
            Net::HttpRequest@ req = API::Get(url);
            while (!req.Finished()) {
                yield();
            }
            string res = req.String();
            auto json = req.Json();
            @req = null;

            Logging::Debug("MapEmbeddedObject::CheckRequest (TryGetID): " + res);

            if (json.GetType() == Json::Type::Null) {
                Logging::Debug("MapEmbeddedObject::CheckRequest (TryGetID): Error parsing response");
                ID = -1;
                return;
            }
            // Handle the response
            if (json.HasKey("results") && json["results"].GetType() == Json::Type::Array && json["results"].Length > 0) {
                ID = json["results"][0]["ID"];
                Logging::Trace("Object ID found for " + ObjectPath + ": " + ID);
                return;
            }
            ID = 0;
        }
    }
}