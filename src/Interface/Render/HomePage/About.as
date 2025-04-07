namespace HomePageTabRender {
    void About()
    {
        if (UI::Button(Icons::KeyboardO + " \\$zContact ManiaExchange")) OpenBrowserURL("https://"+MXURL+"/postcreate?PmTargetUserId=11");
        UI::SameLine();
        if (UI::RedButton(Icons::Heart + " \\$zSupport ManiaExchange")) OpenBrowserURL("https://"+MXURL+"/about?r=support");

        UI::AlignTextToFramePadding();
        UI::Text("Follow the ManiaExchange network on");
        UI::SameLine();
        if (UI::Button(Icons::Facebook + " Facebook")) OpenBrowserURL("https://facebook.com/maniaexchange/");
        UI::SameLine();
        if (UI::Button(Icons::Twitter + " Twitter")) OpenBrowserURL("https://twitter.com/maniaexchange/");
        UI::SameLine();
        if (UI::Button(Icons::YoutubePlay + " YouTube")) OpenBrowserURL("https://youtube.com/maniaexchangetracks/");
        UI::SameLine();
        if (UI::Button(Icons::DiscordAlt + " Discord")) OpenBrowserURL("https://discord.mania.exchange/");

        UI::PushFont(Fonts::Header);
        UI::SeparatorText(pluginColor + Icons::Plug + " \\$z " + "Plugin");
        UI::PopFont();
        UI::Text("Made by \\$777" + Meta::ExecutingPlugin().Author);
        UI::Text("Version \\$777" + Meta::ExecutingPlugin().Version);
        UI::Text("Plugin ID \\$777" + Meta::ExecutingPlugin().ID);
        UI::Text("Site ID \\$777" + Meta::ExecutingPlugin().SiteID);
        UI::Text("Type \\$777" + tostring(Meta::ExecutingPlugin().Type));
#if SIG_DEVELOPER
        UI::SameLine();
        UI::Text("\\$777(\\$f39"+Icons::Code+" \\$777Dev mode)");
#endif
        if (UI::Button(Icons::Heart + " \\$zSponsor")) OpenBrowserURL("https://github.com/sponsors/GreepTheSheep");
        UI::SameLine();
        if (UI::Button(Icons::Kenney::GithubAlt + " Github")) OpenBrowserURL(repoURL);
        UI::SameLine();
        if (UI::Button(Icons::DiscordAlt + " Discord")) OpenBrowserURL("https://greep.gq/discord");
        UI::SameLine();
        if (UI::Button(Icons::Heartbeat + " Plugin Home")) OpenBrowserURL("https://openplanet.nl/files/" + Meta::ExecutingPlugin().SiteID);

        UI::PushFont(Fonts::Header);
        UI::SeparatorText("\\$f39" + Icons::Heartbeat + " \\$z " + "Openplanet");
        UI::PopFont();
        UI::Text("Version \\$777" + Meta::OpenplanetBuildInfo());
    }
}