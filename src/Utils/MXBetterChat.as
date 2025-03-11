#if DEPENDENCY_BETTERCHAT
namespace MXBetterChat
{
    class OpenMapOnMXCmd : BetterChat::ICommand
    {
        string Icon() { return pluginColor + Icons::ManiaExchange; }
        string Description() { return "Opens the map tab on ManiaExchange"; }

        void Run(const string &in text)
        {
            if (currentMapID < 0)
            {
                if (currentMapID == -1) {
                    BetterChat::AddSystemLine("Map was not found on " + pluginName);
                } else if (currentMapID == -2) {
                    BetterChat::AddSystemLine("Server error. Please try again later.");
                } else if (currentMapID == -3) {
                    BetterChat::AddSystemLine("Loading... Please try again later.");
                } else if (currentMapID == -4) {
                    BetterChat::AddSystemLine("Not in a map.");
                } else {
                    BetterChat::AddSystemLine("Unknown error. Please try again later.");
                }
            } else
            {
                if (!UI::IsOverlayShown()) UI::ShowOverlay();
                if (!mxMenu.isOpened) mxMenu.isOpened = true;
                mxMenu.AddTab(MapTab(currentMapID), true);
            }
        }
    }

    class ShowMapInfoJson : BetterChat::ICommand
    {
        string Icon() { return pluginColor + Icons::ManiaExchange; }
        string Description() { return "MX DEV: show current map JSON"; }

        void Run(const string &in text)
        {
            if (currentMapID < 0)
            {
                if (currentMapID == -1) {
                    BetterChat::AddSystemLine("Map was not found on " + pluginName);
                } else if (currentMapID == -2) {
                    BetterChat::AddSystemLine("Server error. Please try again later.");
                } else if (currentMapID == -3) {
                    BetterChat::AddSystemLine("Loading... Please try again later.");
                } else if (currentMapID == -4) {
                    BetterChat::AddSystemLine("Not in a map.");
                } else {
                    BetterChat::AddSystemLine("Unknown error. Please try again later.");
                }
            } else
            {
                BetterChat::AddSystemLine(Json::Write(currentMapInfo.ToJson()));
            }
        }
    }

    class MapAwards : BetterChat::ICommand
    {
        bool m_send;

        MapAwards(bool send) { m_send = send; }

        string Icon()
        {
            if (m_send) return "\\$acf" + Icons::Trophy;
            else return "\\$ef0" + Icons::Trophy;
        }
        string Description()
        {
            if (m_send) return "Tells the number of awards received on this map";
            else return "Prints the number of awards received on this map";
        }

        void Run(const string &in text)
        {
            if (currentMapID < 0)
            {
                if (currentMapID == -1) {
                    BetterChat::AddSystemLine("Map was not found on " + pluginName);
                } else if (currentMapID == -2) {
                    BetterChat::AddSystemLine("Server error. Please try again later.");
                } else if (currentMapID == -3) {
                    BetterChat::AddSystemLine("Loading... Please try again later.");
                } else if (currentMapID == -4) {
                    BetterChat::AddSystemLine("Not in a map.");
                } else {
                    BetterChat::AddSystemLine("Unknown error. Please try again later.");
                }
            } else
            {
                if (m_send) BetterChat::SendChatMessage("$ef0" + Icons::Trophy + " $zThis map has " + currentMapInfo.AwardCount + " awards on " + pluginName + "!");
                else BetterChat::AddSystemLine("$ef0" + Icons::Trophy + " $zAwards: " + currentMapInfo.AwardCount);
            }
        }
    }

    class MXPage : BetterChat::ICommand
    {
        bool m_send;

        MXPage(bool send) { m_send = send; }

        string Icon()
        {
            if (m_send) return "\\$acf" + Icons::ManiaExchange;
            else return pluginColor + Icons::ManiaExchange;
        }
        string Description()
        {
            if (m_send) return "Tells the " + MXURL + " page of this map";
            else return "Opens the " + MXURL + " page of this map";
        }

        void Run(const string &in text)
        {
            if (currentMapID < 0)
            {
                if (currentMapID == -1) {
                    BetterChat::AddSystemLine("Map was not found on " + pluginName);
                } else if (currentMapID == -2) {
                    BetterChat::AddSystemLine("Server error. Please try again later.");
                } else if (currentMapID == -3) {
                    BetterChat::AddSystemLine("Loading... Please try again later.");
                } else if (currentMapID == -4) {
                    BetterChat::AddSystemLine("Not in a map.");
                } else {
                    BetterChat::AddSystemLine("Unknown error. Please try again later.");
                }
            } else
            {
                if (m_send) BetterChat::SendChatMessage("$l[https://"+MXURL+"/mapshow/"+currentMapInfo.MapId+"]\"" + currentMapInfo.Name + "\" on " + pluginName + "$l");
                else OpenBrowserURL("https://"+MXURL+"/mapshow/"+currentMapInfo.MapId);
            }
        }
    }

    class TellMXPlugin : BetterChat::ICommand
    {
        string Icon() { return "\\$acf" + Icons::ManiaExchange; }
        string Description() { return "Tells the " + pluginName + " plugin"; }

        void Run(const string &in text)
        {
            BetterChat::SendChatMessage(Icons::ManiaExchange + " I'm using the "+ pluginName +" plugin for Openplanet! You can access to your favorite maps directly from this plugin, including packs and more! $l[https://openplanet.dev/plugin/154]Get it here!$l");
        }
    }
}
#endif