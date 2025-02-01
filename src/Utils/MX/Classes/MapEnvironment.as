namespace MX
{
    class MapEnvironment
    {
        int ID;
        string Name;

        MapEnvironment(const int &in id, const string &in name)
        {
            if (isDevMode) trace("Loading Environment #"+id+" - "+name);
            ID = id;
            Name = name;
        }
    }
}
