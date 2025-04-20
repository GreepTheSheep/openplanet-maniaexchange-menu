namespace MX
{
    class MapComment
    {
        int Id;
        int UserId;
        string Username;
        string Comment;
        int UpdatedAt;
        bool HasAwarded;
        bool IsAuthor;
        int PostedAt;
        int ReplyTo;
        array<MapComment@> Replies;

        MapComment(const Json::Value &in json)
        {
            try {
                Id = json["CommentId"];
                UserId = json["User"]["UserId"];
                Username = json["User"]["Name"];
                Comment = Format::MXText(json["Comment"]);
                if (json["UpdatedAt"].GetType() != Json::Type::Null) UpdatedAt = Time::ParseFormatString('%FT%T', json["UpdatedAt"]);
                HasAwarded = json["HasAwarded"];
                IsAuthor = json["IsAuthor"];
                PostedAt = Time::ParseFormatString('%FT%T', json["PostedAt"]);
                if (json.HasKey("ReplyTo")) ReplyTo = json["ReplyTo"];

                if (json.HasKey("Replies")) {
                    for (uint i = 0; i < json["Replies"].Length; i++) {
                        try {
                            Replies.InsertLast(MapComment(json["Replies"][i]));
                        } catch {
                            Logging::Warn("Error parsing reply for comment " + Id + ": " + getExceptionInfo());
                        }
                    }
                }
            } catch {
                Logging::Warn("Error parsing comment info for the map: " + getExceptionInfo(), true);
            }
        }
    }
}
