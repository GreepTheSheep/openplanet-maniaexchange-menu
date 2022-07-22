namespace MX
{
    class MapEmbeddedObject
    {
        int ID;
        string ObjectPath;
        string ObjectAuthor;
        string Name;
        bool onIX;
        int UserID;
        string Username;

        MapEmbeddedObject(const Json::Value &in json, bool willFetchID = true)
        {
            try {
                ObjectPath = json["ObjectPath"];
                ObjectAuthor = json["ObjectAuthor"];
                Name = json["Name"];
                onIX = json["onIX"];
                if (json["UserID"].GetType() != Json::Type::Null) UserID = json["UserID"];
                if (json["Username"].GetType() != Json::Type::Null) Username = json["Username"];
                if (willFetchID) startnew(CoroutineFunc(TryGetID));
                else ID = -2;
            } catch {
                mxWarn("Error parsing embedded object info for the map", true);
            }
        }

        void TryGetID()
        {
            string url = "https://item.exchange/itemsearch/search?api=on&format=json&filename="+Name+"&authorlogin="+ObjectAuthor;
            if (isDevMode) trace("MapEmbeddedObject::StartRequest (TryGetID): "+url);
            Net::HttpRequest@ req = API::Get(url);
            while (!req.Finished()) {
                yield();
            }
            string res = req.String();
            if (isDevMode) trace("MapEmbeddedObject::CheckRequest (TryGetID): " + res);
            @req = null;
            auto json = Json::Parse(res);

            if (json.GetType() == Json::Type::Null) {
                print("MapEmbeddedObject::CheckRequest (TryGetID): Error parsing response");
                ID = -1;
                return;
            }
            // Handle the response
            if (json.HasKey("results") && json["results"].GetType() == Json::Type::Array && json["results"].Length > 0) {
                ID = json["results"][0]["ID"];
                trace("Object ID found for " + ObjectPath + ": " + ID);
                return;
            }
            ID = 0;
        }
    }
}