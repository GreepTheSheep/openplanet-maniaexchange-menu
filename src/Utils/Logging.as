enum LogLevel {
    Error,
    Warn,
    Info,
    Debug,
    Trace
}

namespace Logging {
    const vec4 ERROR_COLOR = UI::HSV(1.0, 1.0, 1.0);
    const vec4 WARN_COLOR  = UI::HSV(0.11, 1.0, 1.0);

    void Error(const string &in msg, bool showNotification = false) {
        if (Setting_LogLevel >= LogLevel::Error) {
            if (showNotification) {                
                UI::ShowNotification(Icons::ManiaExchange + " " + pluginName + " - Error", msg, ERROR_COLOR, 8000);
            }

            error("[ERROR] " + msg);
        }
    }

    void Warn(const string &in msg, bool showNotification = false) {
        if (Setting_LogLevel >= LogLevel::Warn) {
            if (showNotification) {
                UI::ShowNotification(Icons::ManiaExchange + " " + pluginName + " - Warning", msg, WARN_COLOR, 5000);
            }

            warn("[WARN] " + msg);
        }
    }

    void Info(const string &in msg, bool showNotification = false) {
        if (Setting_LogLevel >= LogLevel::Info) {
            if (showNotification) {
                UI::ShowNotification(Icons::ManiaExchange + " " + pluginName + " - Information", msg);
            }

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