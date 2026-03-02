namespace Icons {
    string get_AnimatedHourglass() {
        int index = Time::Stamp % 3;

        switch (index) {
            case 0:
                return Icons::HourglassStart;
            case 1:
                return Icons::HourglassHalf;
            default:
                return Icons::HourglassEnd;
        }
    }

    string get_APIStatus() {
        if (MX::APIDown) {
            return " \\$f00" + Icons::Server + "\\$z";
        } 
        
        if (MX::APIRefresh || TM::APIRefresh) {
            return " \\$666" + Icons::Refresh + "\\$z";
        } 
        
        return "";
    }
}
