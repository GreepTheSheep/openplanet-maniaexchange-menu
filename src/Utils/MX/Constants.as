namespace MX
{
    const uint maxMapsRequest = 40;

    enum Difficulties {
        Beginner,
        Intermediate,
        Advanced,
        Expert,
        Lunatic,
        Impossible
    };

    enum MappackTypes {
        Any = -1,
        Standard,
        Campaign,
        Competition,
        Contest
    };

    enum GameModes {
        Race,
        Stunt,
        Platform,
        Puzzle,
        Royal
    };

    enum AuthorTimeStatus {
        Any = -1,
        Unbeaten,
        Beaten
    };

    const array<string> mapPackFieldsArray = {
        "MappackId",
        "Owner.Name",
        "Owner.UserId",
        "CreatedAt",
        "UpdatedAt",
        "Description",
        "Name",
        "Type",
        "Environment",
        "IsPublic",
        "MaplistReleased",
        "Downloadable",
        "IsRequest",
        "MapCount",
        "Tags"
    };
    const string mapPackFields = Text::Join(mapPackFieldsArray, ",");

    const array<string> mapFieldsArray = {
        "MapId",
        "MapUid",
        "OnlineMapId",
        "Uploader.UserId",
        "Uploader.Name",
        "MapType",
        "UploadedAt",
        "UpdatedAt",
        "Name",
        "GbxMapName",
        "AuthorComments",
        "TitlePack",
        "Mood",
        "DisplayCost",
        "Laps",
        "Environment",
        "Difficulty",
        "VehicleName",
        "Length",
        "Medals.Author",
        "TrackValue",
        "AwardCount",
        "ReplayCount",
        "CommentCount",
        "Images",
        "EmbeddedObjectsCount",
        "EmbeddedItemsSize",
        "ServerSizeExceeded",
        "Tags",
        "Authors",
#if TMNEXT
        "OnlineRecordCount",
#endif
        "AuthorBeaten",
        "AuthorBeatable"
    };
    const string mapFields = Text::Join(mapFieldsArray, ",");

    const array<string> userFieldsArray = {
        "UserId",
        "Name",
        "IngameLogin",
        "Bio",
        "RegisteredAt",
        "MapCount",
        "MappackCount",
        "ReplayCount",
        "AwardsReceivedCount",
        "AwardsGivenCount",
        "CommentsReceivedCount",
        "CommentsGivenCount",
        "FavoritesReceivedCount",
        "VideosReceivedCount",
        "VideosPostedCount",
        "FeaturedMapId",
        "VideosCreatedCount",
        "AchievementCount"
    };
    const string userFields = Text::Join(userFieldsArray, ",");

    const array<string> commentFieldsArray = {
        "CommentId",
        "Comment",
        "ReplyTo",
        "User.UserId",
        "User.Name",
        "PostedAt",
        "UpdatedAt",
        "HasAwarded",
        "IsAuthor"
        "Replies"
    };
    const string commentFields = Text::Join(commentFieldsArray, ",");
}
