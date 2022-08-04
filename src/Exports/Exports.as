namespace ManiaExchange
{
    // Opens the menu and shows a map from its ID
    import void ShowMapInfo(int mapID) from "ManiaExchange";

    // Opens the menu and shows a map pack from its ID
    import void ShowMapPackInfo(int mapPackID) from "ManiaExchange";

    // Opens the menu and shows a user from its ID
    import void ShowUserInfo(int userID) from "ManiaExchange";

    // The Current Map ID
    import int GetCurrentMapID() from "ManiaExchange";

    // The Current Map Info
    import MX::MapInfo@ GetCurrentMapInfo() from "ManiaExchange";

    // The Map Info by its ID
    import MX::MapInfo@ GetMapInfoAsync(int mapID) from "ManiaExchange";
}