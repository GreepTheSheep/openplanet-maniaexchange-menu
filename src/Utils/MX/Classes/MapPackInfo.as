namespace MX
{
    class MapPackInfo
    {
        int MappackId;
        int UserId;
        string Username;
        string CreatedAt;
        string UpdatedAt;
        string Description;
        string Name;
        MappackTypes Type;
        int Environment;
        bool IsPublic;
        bool MaplistReleased;
        bool Downloadable;
        bool IsRequest;
        uint MapCount;
        array<MapTag@> Tags;

        // Map list
        array<MapInfo@> Maps;
        MapColumns@ columnWidths = MapColumns();
        Status m_listStatus = Status::Not_Started;

        // Download
        Status m_downloadStatus = Status::Not_Started;

        // For pagination
        bool LastItem;

        MapPackInfo(const Json::Value &in json)
        {
            try {
                MappackId = json["MappackId"];
                Name = json["Name"];
                CreatedAt = json["CreatedAt"];
                if (json["Description"].GetType() != Json::Type::Null) Description = Format::MXText(json["Description"]);
                Type = MappackTypes(int(json["Type"]));
                IsPublic = json["IsPublic"];
                MaplistReleased = json["MaplistReleased"];
                Downloadable = json["Downloadable"];
                IsRequest = json["IsRequest"];
                MapCount = json["MapCount"];

                // Environment is null if mappack is empty
                if (json["Environment"].GetType() != Json::Type::Null) {
                    Environment = json["Environment"];
                }

                if (json["UpdatedAt"].GetType() != Json::Type::Null) {
                    UpdatedAt = json["UpdatedAt"];
                } else {
                    UpdatedAt = json["CreatedAt"];
                }

                if (json["Owner"].GetType() != Json::Type::Null) {
                    UserId = json["Owner"]["UserId"];
                    Username = json["Owner"]["Name"];
                }

                // Tags is an array of tag objects
                if (json["Tags"].GetType() != Json::Type::Null) {
                    const Json::Value@ tagObjects = json["Tags"];

                    for (uint i = 0; i < tagObjects.Length; i++)
                    {
                        for (uint j = 0; j < m_mapTags.Length; j++)
                        {
                            if (m_mapTags[j].ID == tagObjects[i]["TagId"]) {
                                Tags.InsertLast(m_mapTags[j]);
                                break;
                            }
                        }
                    }

                    if (Tags.Length > 1) {
                        Tags.Sort(function(a, b) { return a.Name < b.Name; });
                    }
                }
            } catch {
                Name = json["Name"];
                Logging::Warn("Error parsing infos for the map pack " + Name + ": " + getExceptionInfo(), true);
            }
        }

        Json::Value ToJson()
        {
            Json::Value json = Json::Object();
            try {
                json["MappackId"] = MappackId;
                json["UserId"] = UserId;
                json["Username"] = Username;
                json["CreatedAt"] = CreatedAt;
                json["UpdatedAt"] = UpdatedAt;
                json["Description"] = Description;
                json["Name"] = Name;
                json["Type"] = Type;
                json["IsPublic"] = IsPublic;
                json["MaplistReleased"] = MaplistReleased;
                json["Downloadable"] = Downloadable;
                json["IsRequest"] = IsRequest;
                json["MapCount"] = MapCount;

                Json::Value ownerObject = Json::Object();
                ownerObject["UserId"] = UserId;
                ownerObject["Name"] = Username;

                json["Owner"] = ownerObject;

                Json::Value tagArray = Json::Array();
                for (uint i = 0; i < Tags.Length; i++)
                {
                    tagArray.Add(Tags[i].ToJson());
                }

                json["Tags"] = tagArray;
            } catch {
                Logging::Warn("Error converting map pack info to json for map pack " + Name + ": " + getExceptionInfo(), true);
            }
            return json;
        }

        string get_TypeName() {
            return tostring(Type);
        }

        string get_EnvironmentName() {
            if (Environment == 0) {
                return "Multiple";
            }

            for (uint i =  0; i < m_environments.Length; i++) {
                if (m_environments[i].ID == Environment) {
                    return m_environments[i].Name;
                }
            }

            return "Unknown";
        }

        int get_LastId() {
            if (Maps.IsEmpty()) {
                return 0;
            }

            return Maps[Maps.Length - 1].MapId;
        }

        bool get_MoreMaps() {
            if (Maps.IsEmpty()) {
                return true;
            }

            return !Maps[Maps.Length - 1].LastItem;
        }

        bool get_Loading()   { return m_listStatus == Status::Loading; }
        bool get_ListError() { return m_listStatus == Status::Error; }

        void FetchMaps() {
            if (MapCount == 0 || Loading) {
                return;
            }

            dictionary mapParams = {
                { "fields", MX::mapFields },
                { "mappackid", tostring(MappackId) },
                { "count", "1000"}
            };

            if (MoreMaps && LastId != 0) {
                mapParams.Set("after", tostring(LastId));
            }

            m_listStatus = Status::Loading;
            array<MapInfo@> mapList = GetMaps(mapParams);
            m_listStatus = Status::Completed;
            
            if (mapList.IsEmpty()) {
                Logging::Error("[MappackInfo::FetchMaps] API returned 0 maps! Expected " + MapCount);
                m_listStatus = Status::Error;
                return;
            }

            foreach (MX::MapInfo@ map : mapList) {
                map.MapPackName = Name;
                Maps.InsertLast(map);
            }

            columnWidths.Update(Maps);
        }

        void LoadMore() {
            if (MapCount == 0 || !MoreMaps || Loading) {
                return;
            }

            Logging::Debug("[MappackInfo::LoadMore] Fetching more maps for mappack ID #" + MappackId);
            FetchMaps();
        }

        bool get_Downloading() { return m_downloadStatus == Status::Loading; }
        bool get_Downloaded()  { return m_downloadStatus == Status::Completed; }

        void DownloadMaps() {
            if (MapCount == 0 || Downloading) {
                return;
            }

            Logging::Info("Downloading " + Maps.Length + " maps to your Downloaded folder", true);

            m_downloadStatus = Status::Loading;

            if (Maps.IsEmpty()) {
                FetchMaps();
            }

            while (MoreMaps && MapCount < Maps.Length) {
                LoadMore();
                sleep(100);
            }

            foreach (MapInfo@ map : Maps) {
                map.DownloadMap();
                sleep(100);
            }

            m_downloadStatus = Status::Completed;

            UI::ShowNotification(pluginName, Icons::Check + " Succesfully downloaded " + Maps.Length + " maps to your Downloaded Maps folder", UI::HSV(0.33, 0.7, 0.65));
        }

        void AddToPlayLater() {
            if (MapCount == 0) {
                return;
            }

            Logging::Info("Adding " + Maps.Length + " maps to the Play Later list", true);

            if (Maps.IsEmpty()) {
                FetchMaps();
            }

            while (MoreMaps && MapCount < Maps.Length) {
                LoadMore();
                sleep(100);
            }

            foreach (MapInfo@ map : Maps) {
                if (g_PlayLaterMaps.Find(map) == -1) {
                    g_PlayLaterMaps.InsertLast(map);
                    yield();
                }
            }

            SavePlayLater(g_PlayLaterMaps);
            UI::ShowNotification(pluginName, Icons::Check + " Succesfully added " + Maps.Length + " maps to the Play Later list", UI::HSV(0.33, 0.7, 0.65));
        }
    }
}