void mxError(string msg, bool showNotification = false){
    if (showNotification) {
        vec4 color = UI::HSV(1.0, 1.0, 1.0);
        UI::ShowNotification(Icons::Kenney::ButtonTimes + " " + pluginName + " - Error", msg, color, 8000);
    }
    error(msg);
}

void mxWarn(string msg, bool showNotification = false){
    if (showNotification) {
        vec4 color = UI::HSV(0.11, 1.0, 1.0);
        UI::ShowNotification(Icons::Kenney::ButtonTimes + " " + pluginName + " - Warning", msg, color, 5000);
    }
    warn(msg);
}