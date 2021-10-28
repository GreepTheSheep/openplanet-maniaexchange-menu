void RenderMenu()
{
    if(UI::MenuItem(nameMenu, "", mxMenu.isOpened)) {
        if (!Permissions::PlayLocalMap()) {
            vec4 color = UI::HSV(0.0, 0.5, 1.0);
            error("You don't have permission to play local maps");
            return;
        }
		mxMenu.isOpened = !mxMenu.isOpened;
	}
}

void RenderMenuMain(){
    if(Permissions::PlayLocalMap() && UI::BeginMenu(nameMenu)) {
        if(UI::MenuItem(pluginColor + Icons::WindowMaximize+"\\$z Open "+shortMXName+" menu", "", mxMenu.isOpened)) {
            if (!Permissions::PlayLocalMap()) {
                vec4 color = UI::HSV(0.0, 0.5, 1.0);
                error("You don't have permission to play local maps");
                return;
            }
            mxMenu.isOpened = !mxMenu.isOpened;
        }
        UI::EndMenu();
	}
}

void Main(){
    startnew(MX::GetAllMapTags);
    // Json::Value data = httpGet("https://trackmania.exchange/mapsearch2/search?api=on&format=json&mode=2");
    // print(data["results"][0]["Name"]);
}

void RenderInterface(){
    mxMenu.Render();
}