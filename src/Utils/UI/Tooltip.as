namespace UI
{
    void MXThumbnailTooltip(CachedImage@ img, float resize = 0.25)
    {
        if (UI::BeginItemTooltip()) {
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

    void MXMapThumbnailTooltip(const int &in mapId, const int &in position = 1, float resize = 0.25)
    {
        if (UI::IsItemHovered(UI::HoveredFlags::DelayShort | UI::HoveredFlags::NoSharedDelay)) {
            auto mapThumb = Images::CachedFromURL("https://" + MXURL + "/mapimage/" + mapId + "/" + position + "?hq=true");
            MXThumbnailTooltip(mapThumb, resize);
        }
    }

    void MXMapPackThumbnailTooltip(const int &in mapPackID, float resize = 0.25)
    {
        if (UI::IsItemHovered(UI::HoveredFlags::DelayShort | UI::HoveredFlags::NoSharedDelay)) {
            auto mappackThumb = Images::CachedFromURL("https://" + MXURL + "/mappackthumb/" + mapPackID);
            MXThumbnailTooltip(mappackThumb, resize);
        }
    }
}