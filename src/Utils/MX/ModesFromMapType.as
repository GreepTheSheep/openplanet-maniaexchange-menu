namespace MX
{
    const dictionary ModesFromMapType = {
#if MP4
        // ManiaPlanet
        { "Race",                     "" }, // Base ManiaPlanet Map Type
        { "TrackMania\\Race",         "" },
        { "Platform",                 "" },
        { "Stunts",                   "" },
        { "GoalHuntArena",            "GoalHunt" },
        { "HuntersArena",             "Hunters" },
        { "PursuitArena",             "Pursuit" },
        { "TMOne\\PlatformOneArena",  "" },
        { "EW Stunts - Score Attack", "ExtraWorldSolo" },
        { "EW Race - Time Attack",    "ExtraWorldSolo"},

        // Shootmania
        { "MeleeArena",               "" }, // Base Shootmania Map Type
        { "ObstacleTitleArena",       "Obstacle" },
        { "ObstacleTitleArenaOld",    "Obstacle" },
        { "ObstacleArena",            "Obstacle" },
        { "SiegeV2Arena",             "SiegePro" },
        { "SpeedBallArena",           "SpeedBall" },
        { "RoyalArena",               "RoyalPro" },
        { "EliteArena",               "ElitePro" },
        { "JoustArena",               "JoustPro" },
        { "CTFModeArena",             "CTFMode" },
        { "CTFAgeArena",              "CTFMode" },
        { "BattleArena",              "BattlePro" }
#elif TMNEXT
        { "TM_Race",                  "" },
        { "TM_Stunt",                 "TrackMania/TM_StuntSolo_Local" },
        { "TM_Platform",              "TrackMania/TM_Platform_Local" },
        { "TM_Royal",                 "TrackMania/TM_RoyalTimeAttack_Local" }
#endif
    };
}