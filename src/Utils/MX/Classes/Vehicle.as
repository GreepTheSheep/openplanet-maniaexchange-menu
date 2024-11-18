namespace MX
{
    class Vehicle
    {
        int ID;
        string Name;

        Vehicle(const int &in id, const string &in name)
        {
            if (isDevMode) trace("Loading Vehicle #"+id+" - "+name);
            ID = id;
            Name = name;
        }
    }
}
