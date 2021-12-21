namespace HomePageTabRender {
    void About()
    {                
        if (UI::Button(Icons::KeyboardO + " \\$zContact ManiaExchange")) OpenBrowserURL("https://"+MXURL+"/messaging/compose/11");
        UI::SameLine();
        if (UI::RedButton(Icons::Heart + " \\$zSupport ManiaExchange")) OpenBrowserURL("https://"+MXURL+"/support");

        UI::Text("Follow the ManiaExchange network on");
        UI::SameLine();
        if (UI::Button(Icons::Facebook + " Facebook")) OpenBrowserURL("https://facebook.com/maniaexchange/");
        UI::SameLine();
        if (UI::Button(Icons::Twitter + " Twitter")) OpenBrowserURL("https://twitter.com/maniaexchange/");
        UI::SameLine();
        if (UI::Button(Icons::YoutubePlay + " YouTube")) OpenBrowserURL("https://youtube.com/maniaexchangetracks/");
        UI::SameLine();
        if (UI::Button(Icons::DiscordAlt + " Discord")) OpenBrowserURL("https://discord.mania.exchange/");

        UI::Separator();

        UI::Text(pluginColor + Icons::Plug);
        UI::SameLine();
        UI::PushFont(Header);
        UI::Text("Plugin");
        UI::PopFont();
        UI::Text("Made by \\$777" + Meta::ExecutingPlugin().get_Author());
        UI::Text("Version \\$777" + Meta::ExecutingPlugin().get_Version());
        UI::Text("Plugin ID \\$777" + Meta::ExecutingPlugin().get_ID());
        UI::Text("Site ID \\$777" + Meta::ExecutingPlugin().get_SiteID());
        UI::Text("Type \\$777" + changeEnumStyle(tostring(Meta::ExecutingPlugin().get_Type())));
        if (IsDevMode()) {
            UI::SameLine();
            UI::Text("\\$777(\\$f39"+Icons::Code+" \\$777Dev mode)");
        }
        if (UI::Button(Icons::Heart + " \\$zSponsor")) OpenBrowserURL("https://github.com/sponsors/GreepTheSheep");
        UI::SameLine();
        if (UI::Button(Icons::Kenney::GithubAlt + " Github")) OpenBrowserURL(repoURL);
        UI::SameLine();
        if (UI::Button(Icons::DiscordAlt + " Discord")) OpenBrowserURL("https://greep.gq/discord");
        UI::SameLine();
        if (UI::Button(Icons::Heartbeat + " Plugin Home")) OpenBrowserURL("https://openplanet.nl/files/" + Meta::ExecutingPlugin().get_SiteID());
        
        UI::Separator();
        UI::Text("\\$f39" + Icons::Heartbeat);
        UI::SameLine();
        UI::PushFont(Header);
        UI::Text("Openplanet");
        UI::PopFont();
        UI::Text("Version \\$777" + Meta::OpenplanetBuildInfo());
    }
}