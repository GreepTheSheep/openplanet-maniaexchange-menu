class PlayMapOnNadeoRoomInfos : ModalDialog
{
    int m_stage = 0;
    int m_prevStage = 0;
    UI::Texture@ clubIdTex;
    UI::Texture@ roomIdTex;

    PlayMapOnNadeoRoomInfos() {
        super(Icons::InfoCircle + " \\$zPlay Map On a Nadeo-hosted Room###PlayMapOnNadeoRoomInfos");
        m_size = vec2(1200, 800);
        @clubIdTex = UI::LoadTexture("src/Interface/Assets/help_clubId.png");
        @roomIdTex = UI::LoadTexture("src/Interface/Assets/help_roomId.png");
    }

    bool CanClose() override {return false;}

    void RenderIdHelp()
    {
        UI::Text("\\$f60Finding your Club and Room ID");
        UI::NewLine();
        UI::Markdown(
            "To find your club and room ID, go to [Trackmania.io](https://trackmania.io/#/clubs) and search for your club.\n\n" +
            "Once on it, look up for the club ID, and paste this value on its appropriate input.\n\n" +
            "In the club page on Trackmania.io, go to Activities and find your room.\n\n" +
            "Once on it, look up for the room ID, and paste this value on its appropriate input."
        );

        vec2 imgSize = clubIdTex.GetSize();
        UI::Image(clubIdTex, vec2(
            m_size.x-20,
            imgSize.y / (imgSize.x / (m_size.x-20))
        ));
        UI::Image(roomIdTex, vec2(
            m_size.x-20,
            imgSize.y / (imgSize.x / (m_size.x-20))
        ));
    }

    void RenderStep1()
    {
        UI::TextWrapped("If you want to play a specific map on a room, you'll need to provide some informations.");
        UI::NewLine();
        UI::TextWrapped("You'll need to have the admin role of the club where the room is hosted, then provide the identifier of the club and the room.");
        UI::TextWrapped(Icons::LightbulbO + " \\$fb5To see how to get the club and the room identifier, click here");
        if (UI::IsItemClicked()) {
            m_prevStage = m_stage;
            m_stage = 10;
        }

        UI::NewLine();
        UI::NewLine();

        UI::Text("Club ID:");
        UI::SameLine();
        TMNext::AddMapToServer_ClubId = Text::ParseInt(UI::InputText("##PlayMapOnNadeoRoomInfosClubID", tostring(TMNext::AddMapToServer_ClubId), false, UI::InputTextFlags::CharsDecimal));

        UI::Text("Room ID:");
        UI::SameLine();
        TMNext::AddMapToServer_RoomId = Text::ParseInt(UI::InputText("##PlayMapOnNadeoRoomInfosRoomID", tostring(TMNext::AddMapToServer_RoomId), false, UI::InputTextFlags::CharsDecimal));
    }

    void RenderStep2()
    {
        if (TMNext::isCheckingRoom) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass);
            UI::SameLine();
            UI::Text("Please Wait... Checking in progress");
            return;
        }

        if (TMNext::roomCheckErrorCode.Length > 0) {
            UI::Text("Error: " + TMNext::roomCheckErrorCode);
            UI::NewLine();
            UI::Text(TMNext::roomCheckError);
            return;
        }

        if (TMNext::foundRoom !is null) {
            UI::Text("Room found:");
            UI::Text("'"+TMNext::foundRoom.name+"', in club '"+StripFormatCodes(TMNext::foundRoom.clubName)+"'");

            if (!TMNext::foundRoom.nadeo) {
                UI::Text("\\$f20" + Icons::ExclamationTriangle + " this server is NOT hosted by Nadeo, so you can't add maps from this plugin");
                UI::Text("\\$f20Refer with your server/club masteradmin.");
            } else {
                UI::Text("\\$fb5Are you sure to play this map on your server?");
            }
        }
    }

    void RenderDialog() override
    {
        UI::BeginChild("Content", vec2(0, -35));
        switch (m_stage) {
            case 0: RenderStep1(); break;
            case 1: RenderStep2(); break;
            case 10: RenderIdHelp(); break;
        }
        UI::EndChild();
        if (m_stage > 0) {
            if (UI::Button(Icons::ArrowLeft + " Back")) {
                int thisStage = m_stage;
                m_stage = m_prevStage;
                m_prevStage = thisStage;
            }
        } else {
            if (UI::Button(Icons::Times + " Cancel")) {
                Close();
            }
        }
        UI::SameLine();
        if (m_stage != 1) {
            UI::SetCursorPos(vec2(UI::GetWindowSize().x - 85, UI::GetCursorPos().y));
            UI::BeginDisabled(TMNext::AddMapToServer_ClubId == 0 || TMNext::AddMapToServer_RoomId == 0);
            if (m_stage == 0 && UI::GreenButton("Next " + Icons::ArrowRight)) {
                m_prevStage = m_stage;
                m_stage++;
                startnew(TMNext::CheckNadeoRoomAsync);
            }
            UI::EndDisabled();
        } else {
            UI::SetCursorPos(vec2(UI::GetWindowSize().x - (TMNext::isCheckingRoom ? 40 : 320), UI::GetCursorPos().y));
            if (TMNext::isCheckingRoom) {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass);
            } else {
                if (TMNext::foundRoom !is null && TMNext::foundRoom.nadeo) {
                    if (UI::GreenButton(Icons::Plus + "Add to room map list")) {
                        Close();
                        startnew(TMNext::PlayMapInRoom);
                    }
                    UI::SameLine();
                    if (UI::GreenButton("Play map now!" + Icons::Play)) {
                        Close();
                        TMNext::AddMapToServer_PlayMapNow = true;
                        startnew(TMNext::PlayMapInRoom);
                    }
                }
            }
        }
    }
}