namespace MX
{
    void GetAllMapTags()
    {
        Json::Value resNet = API::GetAsync("https://"+MXURL+"/api/tags/gettags");
        
        for (int i = 0; i < resNet.get_Length(); i++)
        {
            MapTag tag;
            tag.ID = resNet[i]["ID"];
            tag.Name = resNet[i]["Name"];
            tag.Color = resNet[i]["Color"];

            if (IsDevMode()) log("Loading tag #"+tag.ID+" - "+tag.Name);

            m_mapTags.InsertLast(tag);
        }

        if (IsDevMode()) log(m_mapTags.get_Length() + " tags loaded");
    }
}