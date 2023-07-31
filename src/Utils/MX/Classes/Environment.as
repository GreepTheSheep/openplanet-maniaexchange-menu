namespace MX
{
    class Environment
    {
        int ID;
        string Name;

        Environment(const int &in id, const string &in name)
        {
            if (isDevMode) trace("Loading Environment #"+id+" - "+name);
            ID = id;
            Name = name;
        }
    }
}