bool IsDevMode(){
    return Meta::ExecutingPlugin().get_Type() == Meta::PluginType::Folder;
}