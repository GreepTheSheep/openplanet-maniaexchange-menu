# ManiaExchange for Openplanet

![Midnight Metropolis by Htimh & Neon_1990 & Hotrod](https://i.imgur.com/Vh0c3S3.png)

[![Version](https://img.shields.io/badge/dynamic/json?color=pink&label=Version&query=version&url=https%3A%2F%2Fopenplanet.dev%2Fapi%2Fplugin%2F154)](https://openplanet.dev/plugin/maniaexchange)
[![Total Downloads](https://img.shields.io/badge/dynamic/json?color=green&label=Downloads&query=downloads&url=https%3A%2F%2Fopenplanet.dev%2Fapi%2Fplugin%2F154)](https://openplanet.dev/plugin/maniaexchange)
![Tags 1](https://img.shields.io/badge/dynamic/json?color=darkgreen&label=Game&query=tags%5B0%5D.name&url=https%3A%2F%2Fopenplanet.dev%2Fapi%2Fplugin%2F154)
![Tags 2](https://img.shields.io/badge/dynamic/json?color=blue&label=Game&query=tags%5B1%5D.name&url=https%3A%2F%2Fopenplanet.dev%2Fapi%2Fplugin%2F154)
![Signed](https://img.shields.io/badge/dynamic/json?color=green&label=Signed&query=signed&url=https%3A%2F%2Fopenplanet.dev%2Fapi%2Fplugin%2F154)

**Access your favorite maps directly from ManiaExchange, including packs and more!**

---

## Features:
- A full list of all the maps
- Play directly without downloading to your disk!
- Customizable: enable or disable tabs you want.
- Access to map packs
- Online leaderboard included (for Trackmania 2020, from trackmania.io)
- A play later playlist. Save all your maps and access them in 2 clicks anytime!
- Possibility to download maps to your maps folder, so you can create club campaigns or rooms easily without alt-tabing
- And many more!

## Better Chat Commands:
Those commands are available in the game chat thanks to [Better Chat](https://openplanet.dev/plugin/betterchat).

`/mx` | `/maniaexchange` - Will open the tab to the current map

`/mx-page` - Will open the ManiaExchange web page to the current map

`/mx-tell-page` - Will send a link to the ManiaExchange web page to the current map in the chat

`/mx-awards` - Will show the number of awards for the current map

`/mx-tell-awards` - Will send the number of awards for the current map in the chat

`/mx-tell-plugin` - Will send the ManiaExchange plugin info and download link in the chat

`/mx-json` - Dev Mode Only: Will show the raw JSON for the current map

## Exports:
- `ManiaExchange::ShowMapInfo(int MapID)` - Will open the tab to the corresponding map with its ID
- `ManiaExchange::ShowMapInfo(string MapUID)` - Will open the tab to the corresponding map with its UID
- `ManiaExchange::ShowMapPackInfo(int MapPackID)` - Will open the tab to the corresponding map pack with its ID
- `ManiaExchange::ShowUserInfo(int userID)` - Will open the tab to the corresponding user info with its ID
- `ManiaExchange::GetCurrentMapID()` - Will return the current map ID. Possible return values in [the table below](#getcurrentmapid-possible-return-values)
- `ManiaExchange::GetCurrentMapInfo()` - Will return a `Json::Value` containing most information from ManiaExchange for the current playing map
- `ManiaExchange::GetMapInfoAsync(int MapID)` - Will return a `Json::Value` containing most information from ManiaExchange for the map with its ID
- `ManiaExchange::GetMapInfoAsync(string MapUID)` - Will return a `Json::Value` containing most information from ManiaExchange for the map with its UID

### `GetCurrentMapID()` possible return values

| Return value      | Reason                         |
|-------------------|--------------------------------|
| >0 (Upper than 0) | The map ID                     |
| -1                | Map not found                  |
| -2                | Error while fetching           |
| -3                | Fetch in progress              |
| -4                | Not in a map (Game Main menus) |
| -5                | In map Editor                  |
