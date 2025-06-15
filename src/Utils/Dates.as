namespace Date
{
    // check if date complies with ISO 8601
    bool IsValid(const string &in date) {
        try {
            return Time::ParseFormatString("%F", date) > 0;
        } catch {
            return false;
        }
    }
}
