namespace MX
{
    Json::Value ModesFromMapType(){
        Json::Value json = Json::Object();

        // Trackmania
        json["Race"] = ""; // ManiaPlanet Map Type
        json["TM_Race"] = ""; // Base TMNEXT Map Type
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