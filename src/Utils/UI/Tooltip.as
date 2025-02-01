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
            auto img = Images::CachedFromURL("https://"+MXURL+"/mapimage/"+mapId+"/1?hq=true");
            float width = Draw::GetWidth() * resize;

            if (img.m_texture !is null){
                vec2 thumbSize = img.m_texture.GetSize();
                UI::Image(img.m_texture, vec2(
                    width,
                    thumbSize.y / (thumbSize.x / width)
                ));
            } else {
                if (!img.m_error) {
                    int HourGlassValue = Time::Stamp % 3;
                    string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                    UI::Text(Hourglass + " Loading Thumbnail...");
                } else if (img.m_unsupportedFormat) {
                    UI::Text(Icons::FileImageO + " \\$zUnsupported file format WEBP");
                } else if (img.m_notFound) {
                    UI::Text("\\$fc0"+Icons::ExclamationTriangle+" \\$zThumbnail not found");
                } else {
                    UI::Text(Icons::Times+" \\$zError while loading thumbnail");
                }
            }
            UI::EndTooltip();
        }
    }

    void MXMapPackThumbnailTooltip(const int &in mapPackID, float resize = 0.5)
    {
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
            auto img = Images::CachedFromURL("https://"+MXURL+"/mappackthumb/"+mapPackID);
            float width = Draw::GetWidth() * resize;

            if (img.m_texture !is null){
                vec2 thumbSize = img.m_texture.GetSize();
                UI::Image(img.m_texture, vec2(
                    width,
                    thumbSize.y / (thumbSize.x / width)
                ));
            } else {
                if (!img.m_error) {
                    int HourGlassValue = Time::Stamp % 3;
                    string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                    UI::Text(Hourglass + " Loading Thumbnail...");
                } else if (img.m_unsupportedFormat) {
                    UI::Text(Icons::FileImageO + " \\$zUnsupported file format WEBP");
                } else if (img.m_notFound) {
                    UI::Text("\\$fc0"+Icons::ExclamationTriangle+" \\$zThumbnail not found");
                } else {
                    UI::Text("\\$f00"+Icons::Times+" \\$zError while loading thumbnail");
                }
            }
            UI::EndTooltip();
        }
    }
}