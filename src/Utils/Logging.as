enum LogLevel {
    Error,
    Warn,
    Info,
    Debug,
    Trace
}

namespace Logging {
    void Error(const string &in msg, bool showNotification = false) {
        if (Setting_LogLevel >= LogLevel::Error) {
            if (showNotification) {
                vec4 color = UI::HSV(1.0, 1.0, 1.0);
                UI::ShowNotification(Icons::Kenney::ButtonTimes + " " + pluginName + " - Error", msg, color, 8000);
            }

            error("[ERROR] " + msg);
        }
    }

    void Warn(const string &in msg, bool showNotification = false) {
        if (Setting_LogLevel >= LogLevel::Warn) {
            if (showNotification) {
                vec4 color = UI::HSV(0.11, 1.0, 1.0);
                UI::ShowNotification(Icons::Kenney::ButtonTimes + " " + pluginName + " - Warning", msg, color, 5000);
            }

            warn("[WARN] " + msg);
        }
    }

    void Info(const string &in msg) {
        if (Setting_LogLevel >= LogLevel::Info) {
            print("[INFO] " + msg);
        }
    }

    void Debug(const string &in msg) {
        if (Setting_LogLevel >= LogLevel::Debug) {
            print("[DEBUG] " + msg);
        }
    }

    void Trace(const string &in msg) {
        if (Setting_LogLevel >= LogLevel::Trace) {
            trace("[TRACE] " + msg);
        }
    }
}