class CachedImage
{
    string m_url;
    UI::Texture@ m_texture;
    int m_responseCode;
    bool m_error = false;

    void DownloadFromURLAsync()
    {
        trace("Loading texture: " + m_url);
        auto req = API::Get(m_url);
        while (!req.Finished()) {
            yield();
        }
        m_responseCode = req.ResponseCode();
        if (m_responseCode == 200) {
            @m_texture = UI::LoadTexture(req.Buffer());
            if (m_texture.GetSize().x == 0) {
                @m_texture = null;
            }
        } else {
            m_error = true;
        }
    }
}

namespace Images
{
    dictionary g_cachedImages;

    CachedImage@ FindExisting(const string &in url)
    {
        CachedImage@ ret = null;
        g_cachedImages.Get(url, @ret);
        return ret;
    }

    CachedImage@ CachedFromURL(const string &in url)
    {
        // Return existing image if it already exists
        auto existing = FindExisting(url);
        if (existing !is null) {
            return existing;
        }

        // Create a new cached image object and remember it for future reference
        auto ret = CachedImage();
        ret.m_url = url;
        g_cachedImages.Set(url, @ret);

        // Begin downloading
        startnew(CoroutineFunc(ret.DownloadFromURLAsync));
        return ret;
    }
}