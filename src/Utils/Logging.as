void log(string msg){
    print("["+pluginColor+pluginName+"\\$z] "+msg);
}
void error(string msg, string log = ""){
    vec4 color = UI::HSV(0.0, 0.5, 1.0);
    UI::ShowNotification(Icons::Kenney::ButtonTimes + " " + pluginName + " - Error", msg, color, 5000);
    print("\\$z[\\$f00Error: " + pluginName + "\\$z] " + msg);
    if (log != ""){
        print("\\$z[\\$f00Error: " + pluginName + "\\$z] " + log);
    }
}