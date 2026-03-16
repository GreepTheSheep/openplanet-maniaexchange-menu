#if DEPENDENCY_BETTERCHAT
namespace MXBetterChat {
    void PrintStatus() {
        switch (MX::CurrentStatus) {
            case MX::MapStatus::Error:
                BetterChat::AddSystemLine("Server error. Please try again later.");
                break;

            case MX::MapStatus::LoadingInfo:
                BetterChat::AddSystemLine(Icons::AnimatedHourglass + " Loading...");
                break;
            
            case MX::MapStatus::Not_In_Map:
                BetterChat::AddSystemLine("Not in a map.");
                break;

            case MX::MapStatus::Not_Found:
                BetterChat::AddSystemLine("Map was not found on " + pluginName);
                break;

            default:
                BetterChat::AddSystemLine("Unknown error. Please try again later.");
                break;
        }
    }

    void CheckCurrentMap() {
        if (MX::CurrentStatus == MX::MapStatus::LoadingInfo) {
            BetterChat::AddSystemLine(Icons::AnimatedHourglass + " Loading...");
        } else if (!MX::IsCurrentMapCorrect()) {
            BetterChat::AddSystemLine("Searching map on " + shortMXName + "...");
            MX::FetchCurrentMapInfo();
        }

        if (!MX::IsCurrentMapCorrect()) {
            PrintStatus();
        }
    }

    class OpenMapOnMXCmd : BetterChat::ICommand {
        string Icon() { return pluginColor + Icons::ManiaExchange; }
        string Description() { return "Opens the map tab on ManiaExchange"; }

        void OpenMapTab() {
            CheckCurrentMap();

            if (MX::IsCurrentMapCorrect()) {
                if (!UI::IsOverlayShown()) {
                    UI::ShowOverlay();
                }

                if (!mxMenu.isOpened) {
                    mxMenu.isOpened = true;
                }

                mxMenu.AddTab(MapTab(MX::CurrentMapInfo.MapId), true);
            }
        }

        void Run(const string &in text) {
            startnew(CoroutineFunc(OpenMapTab));
        }
    }

    class ShowMapInfoJson : BetterChat::ICommand {
        string Icon() { return pluginColor + Icons::ManiaExchange; }
        string Description() { return "MX DEV: show current map JSON"; }

        void PrintJson() {
            CheckCurrentMap();

            if (MX::IsCurrentMapCorrect()) {
                BetterChat::AddSystemLine(Json::Write(MX::CurrentMapInfo.ToJson()));
            }
        }

        void Run(const string &in text) {
            startnew(CoroutineFunc(PrintJson));
        }
    }

    class MapAwards : BetterChat::ICommand {
        bool m_send;

        MapAwards(bool send) { m_send = send; }

        string Icon() {
            if (m_send) return "\\$acf" + Icons::Trophy;

            return "\\$ef0" + Icons::Trophy;
        }

        string Description() {
            if (m_send) return "Tells the number of awards received on this map";

            return "Prints the number of awards received on this map";
        }

        void PrintAwards() {
            CheckCurrentMap();

            if (MX::IsCurrentMapCorrect()) {
                if (m_send) BetterChat::SendChatMessage("$ef0" + Icons::Trophy + " $zThis map has " + MX::CurrentMapInfo.AwardCount + " awards on " + pluginName + "!");
                else BetterChat::AddSystemLine("$ef0" + Icons::Trophy + " $zAwards: " + MX::CurrentMapInfo.AwardCount);
            }
        }

        void Run(const string &in text) {
            startnew(CoroutineFunc(PrintAwards));
        }
    }

    class MXPage : BetterChat::ICommand {
        bool m_send;

        MXPage(bool send) { m_send = send; }

        string Icon() {
            if (m_send) return "\\$acf" + Icons::ManiaExchange;

            return pluginColor + Icons::ManiaExchange;
        }

        string Description() {
            if (m_send) return "Tells the " + shortMXName + " page of this map";

            return "Opens the " + shortMXName + " page of this map";
        }

        void PrintURL() {
            CheckCurrentMap();

            if (MX::IsCurrentMapCorrect()) {
                if (m_send) {
                    BetterChat::SendChatMessage("$l[" + MXURL + "/mapshow/" + MX::CurrentMapInfo.MapId + "]\"" + MX::CurrentMapInfo.Name + "\" on " + pluginName + "$l");
                } else {
                    OpenBrowserURL(MXURL + "/mapshow/" + MX::CurrentMapInfo.MapId);
                }
            }
        }

        void Run(const string &in text) {
            startnew(CoroutineFunc(PrintURL));
        }
    }

    class TellMXPlugin : BetterChat::ICommand {
        string Icon() { return "\\$acf" + Icons::ManiaExchange; }
        string Description() { return "Tells the " + pluginName + " plugin"; }

        void Run(const string &in text) {
            BetterChat::SendChatMessage(Icons::ManiaExchange + " I'm using the " + pluginName + " plugin for Openplanet! You can access your favorite maps directly from this plugin, including packs and more! $l[https://openplanet.dev/plugin/154]Get it here!$l");
        }
    }
}
#endif