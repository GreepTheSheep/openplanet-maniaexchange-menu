#if DEPENDENCY_BETTERCHAT
namespace MXBetterChat
{
    class OpenMapOnMXCmd : BetterChat::ICommand
    {
        string Icon() { return pluginColor + Icons::Exchange; }
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
        string Icon() { return pluginColor + Icons::Exchange; }
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
            if (m_send) return "Tells the number of awards given on this map";
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

    class TellMXPage : BetterChat::ICommand
    {
        string Icon() { return "\\$acf" + Icons::Exchange; }
        string Description() { return "Tells the " + MXURL + " page of this map"; }

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
                BetterChat::SendChatMessage("$l[https://"+MXURL+"/maps/"+currentMapInfo.TrackID+"]\"" + currentMapInfo.Name + "\" on " + pluginName + "$l");
            }
        }
    }
}
#endif