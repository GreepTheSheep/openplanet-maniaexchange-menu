namespace UI
{
    void MapIdCallback(UI::InputTextCallbackData@ data) {
        if (data.EventFlag == UI::InputTextFlags::CallbackAlways) {
            if (data.TextLength > 6) {
                data.DeleteChars(6, data.TextLength - 6);
            }
        } else if (data.EventFlag == UI::InputTextFlags::CallbackCharFilter) {
            if (data.EventChar < 48 || data.EventChar > 57) {
                // character is not a number
                data.EventChar = 0;
            }
        }
    }
}
