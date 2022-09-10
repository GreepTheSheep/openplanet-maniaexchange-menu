namespace HomePageTabRender {
    void Changelog()
    {
        GH::CheckReleasesReq();
        if (GH::ReleasesReq is null && GH::Releases.Length == 0) {
            if (!GH::releasesRequestError) {
                GH::StartReleasesReq();
            } else {
                UI::Text("Error while loading releases");
            }
        }
        if (GH::ReleasesReq !is null) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
        }

        if (GH::ReleasesReq is null && GH::Releases.Length > 0) {
            UI::BeginTabBar("MainUISettingsTabBar", UI::TabBarFlags::FittingPolicyScroll);
            for (uint i = 0; i < GH::Releases.Length; i++) {
                GH::Release@ release = GH::Releases[i];

                if (UI::BeginTabItem((release.name.Replace('v', '') == Meta::ExecutingPlugin().Version ? "\\$090": "") + Icons::Tag + " \\$z" + release.name)) {
                    UI::BeginChild("Changelog"+release.name);
                    UI::Markdown(IfaceRender::FormatChangelogBody(release.body));
                    UI::EndChild();
                    UI::EndTabItem();
                }
            }
            UI::EndTabBar();
        }
    }
}