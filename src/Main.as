string inputMapID = "";
int currentMapID = -4;
MX::MapInfo@ currentMapInfo;
Window mxMenu;
bool openedMainMenu;

void RenderMenu()
{
#if TMNEXT
    if (!hasPermissions) return;
#endif
    if (UI::MenuItem(nameMenu + Icons::APIStatus + "###" + pluginName + "Menu", "", Setting_ShowMenu)) {
        if (MX::APIDown) {
            Renderables::Add(APIDownWarning());
        } else {
            Setting_ShowMenu = !Setting_ShowMenu;
        }
    }
}

void RenderMenuMain() {
#if TMNEXT
    if (!hasPermissions) return;
#endif
    if (UI::BeginMenu(nameMenu + Icons::APIStatus + "###" + pluginName + "Menu")) {
        openedMainMenu = true;

        if (!MX::APIDown) {
            if (MX::APIRefresh) {
                UI::Text(Icons::AnimatedHourglass + " Please wait...");
            } else {
                if (UI::MenuItem(pluginColor + Icons::WindowMaximize + "\\$z Open " + shortMXName + " menu", "", Setting_ShowMenu)) {
                    Setting_ShowMenu = !Setting_ShowMenu;
                }

                if (UI::BeginMenu(pluginColor + Icons::ICursor + "\\$z Enter map ID")) {
                    bool pressedEnter = false;
                    inputMapID = UI::InputText("##InputMapId", inputMapID, pressedEnter, UI::InputTextFlags::EnterReturnsTrue | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackCharFilter | UI::InputTextFlags::CallbackAlways, UI::MXIdCallback);

                    if (inputMapID != "") {
                        if (pressedEnter || UI::MenuItem(Icons::Play + " Play map")) {
                            UI::ShowNotification("Loading map...");
                            startnew(MX::LoadMapAsync, Text::ParseInt(inputMapID));
                        }

                        if (UI::MenuItem(Icons::Kenney::InfoCircle + " Open information")) {
                            if (!Setting_ShowMenu) Setting_ShowMenu = true;
                            mxMenu.AddTab(MapTab(Text::ParseInt(inputMapID)), true);
                        }
                    }

                    UI::EndMenu();
                }

                if (currentMapID > 0) {
                    UI::Separator();
                    if (UI::MenuItem(Icons::Kenney::InfoCircle + " " + Text::OpenplanetFormatCodes(currentMapInfo.GbxMapName))) {
                        if (!Setting_ShowMenu) Setting_ShowMenu = true;
                        mxMenu.AddTab(MapTab(currentMapID), true);
                    }
                }

                if (currentMapID == -1) {
                    UI::Separator();
                    UI::TextDisabled(Icons::Times + " Current map not found on " + shortMXName);
                }

                if (currentMapID == -2) {
                    UI::Separator();
                    UI::TextDisabled("Error while checking the current map on " + shortMXName);
                }

                if (currentMapID == -3) {
                    UI::Separator();
                    UI::TextDisabled(Icons::AnimatedHourglass + " Loading...");
                }

#if SIG_DEVELOPER
                if (currentMapID == -4) {
                    UI::Separator();
                    UI::TextDisabled("Not in a map.");
                }

                if (currentMapID == -5) {
                    UI::Separator();
                    UI::TextDisabled("In map editor.");
                }
#endif
            }
        } else {
            UI::TextDisabled("\\$f00" + Icons::Server + " \\$z" + shortMXName + " is down!");
            UI::TextDisabled("Consider to check your internet connection.");

            if (!MX::APIRefresh && UI::Button(Icons::Refresh + " Refresh")) {
                startnew(MX::CheckForAPILoaded);
            }

            if (MX::APIRefresh) {
                UI::Text(Icons::AnimatedHourglass + " Refreshing...");
            }
        }

        UI::Separator();

        if (UI::BeginMenu(Icons::ClockO + " Play later (" + g_PlayLaterMaps.Length + ")")) {
            if (g_PlayLaterMaps.Length > 0) {
                for (uint i = 0; i < g_PlayLaterMaps.Length; i++) {
                    MX::MapInfo@ map = g_PlayLaterMaps[i];
                    if (UI::BeginMenu((Setting_ColoredMapName ? Text::OpenplanetFormatCodes(map.GbxMapName) : map.Name) + " \\$z\\$sby " + map.Username)) {
                        if (UI::MenuItem(Icons::Play + " Play map")) {
                            UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(map.GbxMapName) + "\\$z\\$s by " + map.Username);
                            startnew(CoroutineFunc(map.PlayMap));
                        }

                        if (!MX::APIDown && UI::MenuItem(Icons::Kenney::InfoCircle + " Open information")) {
                            if (!Setting_ShowMenu) Setting_ShowMenu = true;
                            mxMenu.AddTab(MapTab(map), true);
                        }

                        if (UI::MenuItem("\\$f00" + Icons::TrashO + " Remove map")) {
                            g_PlayLaterMaps.RemoveAt(i);
                            SavePlayLater(g_PlayLaterMaps);
                            UI::ShowNotification(Text::OpenplanetFormatCodes(map.GbxMapName) + "\\$z\\$s by " + map.Username + " has been removed!");
                        }

                        UI::EndMenu();
                    }
                }
            } else {
                UI::TextDisabled("The list is empty!");
                UI::Separator();
                UI::TextDisabled("To add a map here,");
                UI::TextDisabled("select a map in the menu");
                UI::TextDisabled("and click on 'Add to Play later'");
            }

            UI::EndMenu();
        }

        if (g_PlayLaterMaps.Length > 0 && UI::MenuItem("\\$f00" + Icons::TrashO + " Clear list")) {
            Renderables::Add(ClearPlayLaterListWarn());
        }

        UI::Separator();

#if DEPENDENCY_NADEOSERVICES
        // TODO: Add in-game favorites list from NadeoServices
        if (UI::BeginMenu(pluginColor + Icons::Heart + " \\$zFavorites (" + MXNadeoServicesGlobal::g_favoriteMaps.Length + ")")) {
            if (MXNadeoServicesGlobal::g_favoriteMaps.Length > 0) {
                for (uint i = 0; i < MXNadeoServicesGlobal::g_favoriteMaps.Length; i++) {
                    NadeoServices::MapInfo@ mapNadeo = MXNadeoServicesGlobal::g_favoriteMaps[i];

                    if (mapNadeo.MXMapInfo !is null) {
                        MX::MapInfo@ map = mapNadeo.MXMapInfo;
                        if (UI::BeginMenu((Setting_ColoredMapName ? Text::OpenplanetFormatCodes(map.GbxMapName) : map.Name) + " \\$z\\$sby " + map.Username)) {
                            if (UI::MenuItem(Icons::Play + " Play map")) {
                                UI::ShowNotification("Loading map...", Text::OpenplanetFormatCodes(map.GbxMapName) + " \\$zby " + map.Username);
                                startnew(CoroutineFunc(map.PlayMap));
                            }

                            if (!MX::APIDown && UI::MenuItem(Icons::Kenney::InfoCircle + " Open information")) {
                                if (!Setting_ShowMenu) Setting_ShowMenu = true;
                                mxMenu.AddTab(MapTab(map), true);
                            }

                            if (UI::MenuItem("\\$f00" + Icons::TrashO + " Remove map")) {
                                startnew(MXNadeoServicesGlobal::RemoveMapFromFavoritesAsync, mapNadeo);
                            }

                            UI::EndMenu();
                        }
                    } else {
                        if (UI::BeginMenu((Setting_ColoredMapName ? Text::OpenplanetFormatCodes(mapNadeo.GbxName) : mapNadeo.Name) + "\\$z by " + mapNadeo.Author)) {
                            UI::TextDisabled(Icons::Times + " This map is not available on " + pluginName);

                            if (UI::MenuItem("\\$f00" + Icons::TrashO + " Remove map")) {
                                startnew(MXNadeoServicesGlobal::RemoveMapFromFavoritesAsync, mapNadeo);
                            }

                            UI::EndMenu();
                        }
                    }
                }
            } else {
                UI::TextDisabled("The list is empty!");
                UI::Separator();
                UI::TextDisabled("To add a map here,");
                UI::TextDisabled("select a map in the menu");
                UI::TextDisabled("and click on 'Add to Favorites'");
            }
            UI::EndMenu();
        }

        UI::Separator();
#endif

        if (UI::BeginMenu(pluginColor + Icons::InfoCircle + " \\$zAbout")) {
            if (UI::BeginMenu("\\$f00" + Icons::Heart + "\\$z Support")) {
                if (UI::MenuItem(pluginColor + Icons::Heart + " \\$zSupport ManiaExchange")) OpenBrowserURL(MXURL + "/about?r=support");
                if (UI::MenuItem(Icons::Heartbeat + " \\$zSupport the plugin creator")) OpenBrowserURL("https://github.com/sponsors/GreepTheSheep");
                UI::EndMenu();
            }

            UI::Separator();

            if (UI::BeginMenu(pluginColor + Icons::KeyboardO + " \\$zContact")) {
                if (UI::MenuItem(pluginColor + Icons::KeyboardO + " \\$zContact ManiaExchange")) OpenBrowserURL(MXURL + "/postcreate?PmTargetUserId=11");
                if (UI::MenuItem(Icons::DiscordAlt + " Plugin creator's Discord")) OpenBrowserURL("https://greep.gq/discord");
                UI::EndMenu();
            }

            UI::Separator();

            if (UI::MenuItem("ManiaExchange on Bluesky")) OpenBrowserURL("https://bsky.app/profile/maniaexchange.bsky.social");
            if (UI::MenuItem(pluginColor + Icons::Facebook + " \\$zManiaExchange on Facebook")) OpenBrowserURL("https://facebook.com/maniaexchange/");
            if (UI::MenuItem(pluginColor + Icons::YoutubePlay + " \\$zManiaExchange on YouTube")) OpenBrowserURL("https://youtube.com/maniaexchangetracks/");
            if (UI::MenuItem(pluginColor + Icons::DiscordAlt + " \\$zManiaExchange on Discord")) OpenBrowserURL("https://discord.mania.exchange/");

            UI::EndMenu();
         }

        if (UI::BeginMenu("\\$f90" + Icons::CircleThin + " \\$zAdvanced")) {
            UI::TextDisabled("Actual Repository URL: ");
            UI::TextDisabled(MXURL);

            if (UI::MenuItem(pluginColor + Icons::ExternalLink + " \\$zOpen " + pluginName + " in browser")) OpenBrowserURL(MXURL);

            UI::Separator();

            if (!MX::APIRefresh && UI::MenuItem(Icons::Refresh + " Refresh Tags and Seasons")) {
                startnew(MX::CheckForAPILoaded);
            }

#if DEPENDENCY_NADEOSERVICES
            if (!MXNadeoServicesGlobal::APIRefresh && UI::MenuItem("\\$850" + Icons::Refresh + " \\$zRefresh favorite maps list")) {
                startnew(MXNadeoServicesGlobal::ReloadFavoriteMapsAsync);
            }
#endif

            UI::EndMenu();
        }

        UI::EndMenu();
    }
}

void Main() {
#if TMNEXT
    if (!hasPermissions) {
        Logging::Error("You need Club / Standard access to use this plugin!", true);
        return;
    }
#endif

    startnew(Fonts::Load);

#if MP4
    if (repo == MP4mxRepos::Trackmania) MXURL = "https://tm.mania.exchange";
    else if (repo == MP4mxRepos::Shootmania) MXURL = "https://sm.mania.exchange";
#endif
    await(startnew(MX::CheckForAPILoaded));

    g_PlayLaterMaps = LoadPlayLater();

#if DEPENDENCY_BETTERCHAT
    startnew(BetterChatRegisterCommands);
#endif

    startnew(MapChecker);

#if DEPENDENCY_NADEOSERVICES
    startnew(MXNadeoServicesGlobal::LoadNadeoServices);

    while (!mxMenu.isOpened && !openedMainMenu) {
        yield();
    }

    startnew(MXNadeoServicesGlobal::RefreshFavoriteMapsLoop);
#endif
}

void MapChecker() {
    CTrackMania@ app = cast<CTrackMania>(GetApp());

    while (true) {
        yield();

        if (IsInEditor()) {
            currentMapID = -5;
            continue;
        }

        if (app.RootMap is null) {
            currentMapID = -4;
            continue;
        }

        if (!MX::APIDown && currentMapID < -1) {
            currentMapID = MX::GetCurrentMapMXID();

            if (currentMapID < 0 && currentMapID != -3) {
                Logging::Debug("MX ID error: " + currentMapID);
                sleep(30000);
            }
        }
    }
}

#if DEPENDENCY_BETTERCHAT
void BetterChatRegisterCommands() {
    try {
        BetterChat::RegisterCommand("mx", MXBetterChat::OpenMapOnMXCmd());
        BetterChat::RegisterCommand("maniaexchange", MXBetterChat::OpenMapOnMXCmd());
        BetterChat::RegisterCommand("mx-page", MXBetterChat::MXPage(false));
        BetterChat::RegisterCommand("mx-tell-page", MXBetterChat::MXPage(true));
        BetterChat::RegisterCommand("mx-awards", MXBetterChat::MapAwards(false));
        BetterChat::RegisterCommand("mx-tell-awards", MXBetterChat::MapAwards(true));
        BetterChat::RegisterCommand("mx-tell-plugin", MXBetterChat::TellMXPlugin());
#if SIG_DEVELOPER
        BetterChat::RegisterCommand("mx-json", MXBetterChat::ShowMapInfoJson());
#endif
    } catch {
        Logging::Error("Better Chat: unable to register commands: " + getExceptionInfo(), true);
    }
}
#endif

void RenderInterface() {
#if TMNEXT
    if (!hasPermissions) return;
#endif
    mxMenu.Render();
}

void Render() {
#if TMNEXT
    if (!hasPermissions) return;
#endif
    Renderables::Render();
}

void OnDestroyed() {
#if DEPENDENCY_BETTERCHAT
    BetterChat::UnregisterCommand("mx");
    BetterChat::UnregisterCommand("maniaexchange");
#if SIG_DEVELOPER
    BetterChat::UnregisterCommand("mx-json");
#endif
    BetterChat::UnregisterCommand("mx-awards");
    BetterChat::UnregisterCommand("mx-tell-awards");
    BetterChat::UnregisterCommand("mx-page");
    BetterChat::UnregisterCommand("mx-tell-page");
    BetterChat::UnregisterCommand("mx-tell-plugin");
#endif
}