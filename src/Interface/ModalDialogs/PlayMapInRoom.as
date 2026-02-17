class PlayMapInRoom : ModalDialog
{
    bool m_showHelp;
    UI::Texture@ clubIdTex;
    UI::Texture@ roomIdTex;
    MX::MapInfo@ m_newMap;

    PlayMapInRoom(MX::MapInfo@ map) {
        super(Icons::Map + " \\$zAdd Map to Room###PlayMapInRoom");
        m_size = vec2(900, 500);

        @clubIdTex = UI::LoadTexture("src/Interface/Assets/help_clubId.png");
        @roomIdTex = UI::LoadTexture("src/Interface/Assets/help_roomId.png");
        @m_newMap = map;
    }

    void RenderHelp() {
        UI::BeginChild("Content", vec2(0, -35));

        UI::PaddedHeaderSeparator("Finding your Club and Room ID");

        UI::Markdown(
            "To find your club ID, go to [Trackmania.io](https://trackmania.io/#/clubs) and search for your club. " +
            "Once there, copy the ID number and paste it in the \"Club ID\" field."
        );

        vec2 imgSize = clubIdTex.GetSize();
        UI::Image(clubIdTex, vec2(
            m_size.x-20,
            imgSize.y / (imgSize.x / (m_size.x-20))
        ));

        UI::NewLine();

        UI::Markdown(
            "In the club page on Trackmania.io, go to Activities and find your room. There, copy the room ID" +
            " and paste it in the \"Room ID\" field."
        );

        UI::NewLine();

        UI::Image(roomIdTex, vec2(
            m_size.x-20,
            imgSize.y / (imgSize.x / (m_size.x-20))
        ));

        UI::EndChild();

        if (UI::Button(Icons::ArrowLeft + " Back")) {
            m_showHelp = false;
        }
    }

    void RenderSteps() {
        UI::BeginChild("Content", vec2(0, -35));

        UI::TextWrapped("If you want to play a specific map on a room, you'll have to provide the IDs of the club and room.");

        UI::TextWrapped("You also need to be an admin in the club, and the room needs to be hosted by Nadeo.");

        UI::NewLine();

        UI::SetItemText("Club ID:");
        TM::AddMapToServer_ClubId = UI::InputInt("##ClubID", TM::AddMapToServer_ClubId, 0);

        UI::SetItemText("Room ID:");
        TM::AddMapToServer_RoomId = UI::InputInt("##RoomID", TM::AddMapToServer_RoomId, 0);

        UI::BeginDisabled(TM::IsCheckingRoom || TM::AddMapToServer_ClubId == 0 || TM::AddMapToServer_RoomId == 0);

        if (UI::GreenButton(Icons::Search + " Check room")) {
            startnew(TM::CheckNadeoRoomAsync);
        }

        UI::EndDisabled();

        UI::SameLine();

        if (UI::GreyButton(Icons::QuestionCircle + " Help")) {
            m_showHelp = true;
        }

        if (TM::IsCheckingRoom) {
            UI::SameLine();
            UI::Text(Icons::AnimatedHourglass + " Checking room...");
        } else if (TM::roomCheckError.Length > 0) {
            UI::Text("\\$f90" + Icons::ExclamationTriangle + "\\$An error occurred while getting the room: " + TM::roomCheckError);
        } else if (TM::foundRoom !is null) {
            UI::PaddedHeaderSeparator("Room");

            UI::Text("Room: " + Text::StripFormatCodes(TM::foundRoom.name));
            UI::Text("Club: " + Text::StripFormatCodes(TM::foundRoom.clubName));

            if (TM::foundRoom.room !is null) {
                UI::Text("Players: " + TM::foundRoom.room.playerCount);
            }

            if (!TM::foundRoom.nadeo) {
                UI::NewLine();
                UI::Text("\\$f90" + Icons::ExclamationTriangle + "\\$ this server is NOT hosted by Nadeo, so you can't add maps from this plugin");
                UI::Text("Refer to your server/club masteradmin.");
            }
        }

        UI::EndChild();

        float buttonsWidth = UI::MeasureButton(Icons::Plus + " Add to room map list").x;
        buttonsWidth += UI::MeasureButton(Icons::Play + " Play map now!").x;

        UI::RightAlignButtons(buttonsWidth, 2);

        UI::BeginDisabled(TM::IsCheckingRoom || TM::foundRoom is null || !TM::foundRoom.nadeo);

        if (UI::GreenButton(Icons::Plus + " Add to room map list")) {
            Close();
            startnew(TM::AddMapToRoom, m_newMap);
        }

        UI::SameLine();

        if (UI::GreenButton(Icons::Play + " Play map now!")) {
            Close();
            startnew(TM::PlayMapInRoom, m_newMap);
        }

        UI::EndDisabled();
    }

    void RenderDialog() override
    {
        if (m_showHelp) {
            RenderHelp();
        } else {
            RenderSteps();
        }
    }
}