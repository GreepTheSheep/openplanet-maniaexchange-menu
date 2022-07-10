namespace UI
{
    void SetPreviousTooltip(const string &in text)
    {
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::Text(text);
            UI::EndTooltip();
        }
    }

    void MXMapThumbnailTooltip(const int &in mapId, float resize = 0.5)
    {
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
            auto img = Images::CachedFromURL("https://"+MXURL+"/maps/"+mapId+"/image/1");
            auto thumb = Images::CachedFromURL("https://"+MXURL+"/maps/thumbnail/"+mapId);
            float width = Draw::GetWidth() * resize;

            if (img.m_texture !is null){
                vec2 thumbSize = img.m_texture.GetSize();
                UI::Image(img.m_texture, vec2(
                    width,
                    thumbSize.y / (thumbSize.x / width)
                ));
            } else {
                width = Draw::GetWidth() * (resize - 0.2);
                if (thumb.m_texture !is null){
                    vec2 thumbSize = thumb.m_texture.GetSize();
                    UI::Image(thumb.m_texture, vec2(
                        width,
                        thumbSize.y / (thumbSize.x / width)
                    ));
                } else {
                    int HourGlassValue = Time::Stamp % 3;
                    string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                    UI::Text(Hourglass + " Loading Thumbnail...");
                }
            }
            UI::EndTooltip();
        }
    }

    void MXMapPackThumbnailTooltip(const int &in mapPackID, float resize = 0.5)
    {
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
            auto img = Images::CachedFromURL("https://"+MXURL+"/mappack/thumbnail/"+mapPackID);
            float width = Draw::GetWidth() * resize;

            if (img.m_texture !is null){
                vec2 thumbSize = img.m_texture.GetSize();
                UI::Image(img.m_texture, vec2(
                    width,
                    thumbSize.y / (thumbSize.x / width)
                ));
            } else {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Loading Thumbnail...");
            }
            UI::EndTooltip();
        }
    }
}