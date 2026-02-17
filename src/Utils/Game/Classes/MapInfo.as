namespace TM {
    class MapInfo {
        string Uid;
        string MapId;
        string GbxName;
        string Name;
        string Author = "Unknown";
        string AuthorId;
        uint AuthorScore;
        uint GoldScore;
        uint SilverScore;
        uint BronzeScore;
        string DownloadUrl;
        string ThumbnailUrl;
        int Timestamp;
        bool HasClones;
        string MapType;
        string Vista;
        MX::MapInfo@ MXMapInfo;
        Json::Value@ jsonCache;

        // to keep the original order in favorites
        int Position;

        MapInfo(CNadeoServicesMap@ map) {
            try {
                Uid = map.Uid;
                MapId = map.Id;
                GbxName = Format::GbxText(map.Name);
                Name = Text::StripFormatCodes(GbxName);
                AuthorId = map.AuthorAccountId;
                AuthorScore = map.AuthorScore;
                GoldScore = map.GoldScore;
                SilverScore = map.SilverScore;
                BronzeScore = map.BronzeScore;
                DownloadUrl = map.FileUrl;
                ThumbnailUrl = map.ThumbnailUrl;
                Timestamp = map.TimeStamp;
                HasClones = map.HasClones;
                MapType = CleanMapType(map.Type);
                Vista = map.CollectionName;

                if (map.AuthorDisplayName != "") {
                    Author = map.AuthorDisplayName;
                }

                @jsonCache = ToJson();
            } catch {
                Logging::Warn("Error parsing infos for map " + Name + ": " + getExceptionInfo());
            }
        }

        Json::Value ToJson() {
            if (jsonCache !is null) return jsonCache;

            Json::Value json = Json::Object();

            try {
                json["Uid"] = Uid;
                json["Id"] = MapId;
                json["Name"] = GbxName;
                json["AuthorDisplayName"] = Author;
                json["AuthorAccountId"] = AuthorId;
                json["AuthorScore"] = AuthorScore;
                json["GoldScore"] = GoldScore;
                json["SilverScore"] = SilverScore;
                json["BronzeScore"] = BronzeScore;
                json["FileUrl"] = DownloadUrl;
                json["ThumbnailUrl"] = ThumbnailUrl;
                json["TimeStamp"] = Timestamp;
                json["HasClones"] = HasClones;
                json["Type"] = MapType;
                json["CollectionName"] = Vista;
            } catch {
                Logging::Warn("Error converting map info to json for map " + Name + ": " + getExceptionInfo());
            }

            return json;
        }

        bool opEquals(MapInfo@ b) {
            return Uid == b.Uid;
        }
    }
}