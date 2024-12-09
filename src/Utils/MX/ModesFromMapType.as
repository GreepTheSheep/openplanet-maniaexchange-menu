namespace MX
{
    Json::Value ModesFromMapType(){
        Json::Value json = Json::Object();

        // ManiaPlanet
        json["Race"] = ""; // Base ManiaPlanet Map Type
        json["TrackMania\\Race"] = "";
        json["Platform"] = "";
        json["Stunts"] = "";
        json["GoalHuntArena"] = "GoalHunt";
        json["HuntersArena"] = "Hunters";
        json["PursuitArena"] = "Pursuit";
        json["TMOne\\PlatformOneArena"] = "";
        json["EW Stunts - Score Attack"] = "ExtraWorldSolo";
        json["EW Race - Time Attack"] = "ExtraWorldSolo";

        // TMNext
        json["TM_Race"] = ""; // Base TMNext Map Type
        json["TM_Stunt"] = "TrackMania/TM_StuntSolo_Local";
        json["TM_Platform"] = "TrackMania/TM_Platform_Local";
        json["TM_Royal"] = "TrackMania/TM_RoyalTimeAttack_Local";

        // Shootmania
        json["MeleeArena"] = ""; // Base Shootmania Map Type
        json["ObstacleTitleArena"] = "Obstacle";
        json["ObstacleTitleArenaOld"] = "Obstacle";
        json["ObstacleArena"] = "Obstacle";
        json["SiegeV2Arena"] = "SiegePro";
        json["SpeedBallArena"] = "SpeedBall";
        json["RoyalArena"] = "RoyalPro";
        json["EliteArena"] = "ElitePro";
        json["JoustArena"] = "JoustPro";
        json["CTFModeArena"] = "CTFMode";
        json["CTFAgeArena"] = "CTFMode";
        json["BattleArena"] = "BattlePro";

        return json;
    }
}