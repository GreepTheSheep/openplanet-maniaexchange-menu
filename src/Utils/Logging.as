void log(string msg, bool disabled = false){
    print((disabled ? "\\$777" : "") + msg);
}
void mxError(string msg, bool showNotification = false){
    if (showNotification) {
        vec4 color = UI::HSV(0.0, 0.5, 1.0);
        UI::ShowNotification(Icons::Kenney::ButtonTimes + " " + pluginName + " - Error", msg, color, 5000);
    }
    print("\\$z[\\$f00Error: " + pluginName + "\\$z] " + msg);
}