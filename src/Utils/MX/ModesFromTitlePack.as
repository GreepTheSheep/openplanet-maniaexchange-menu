namespace MX
{
    Json::Value ModesFromTitlePack(){
        Json::Value json = Json::Object();

        // Base title packs
        json["TMCanyon"] = "SingleMap";
        json["TMStadium"] = "SingleMap";
        json["TMValley"] = "SingleMap";
        json["TMLagoon"] = "SingleMap";

        // Envimix
        json["TMAll"] = "SingleMap";
        json["Envimix_Turbo"] = "EnvimixSolo";
        json["Nadeo_Envimix"] = "EnvimixSolo";

        // Environments recreations
        // json["TMOneAlpine"] = "Unbitn/TMOne/TimeAttackOne";
        // json["TMOneSpeed"] = "Unbitn/TMOne/TimeAttackOne";
        // json["TMOneBay"] = "Unbitn/TMOne/TimeAttackOne";
        json["TM2Rally"] = "GlobalSolo";
        json["TM2U_Island"] = "SoloUni";
        json["TM2_Coast"] = "CoastSolo";

        // Gamemodes recreations
        json["Platform"] = "PlatformSolo";
        json["ExtraWorld"] = "ExtraWorldSolo";
        json["ModePlus"] = "GlobalSolo";

        // Competition
        json["esl_comp"] = "SingleMap";

        // Other
        json["TMPlus_Canyon"] = "SingleMap";
        json["TMPlus_Lagoon"] = "SingleMap";

        return json;
    }
}
