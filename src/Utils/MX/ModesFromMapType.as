namespace MX
{
    Json::Value ModesFromMapType(){
        Json::Value json = Json::Object();

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