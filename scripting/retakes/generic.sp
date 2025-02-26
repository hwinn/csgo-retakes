#tryinclude "manual_version.sp"
#if !defined PLUGIN_VERSION
#define PLUGIN_VERSION "0.3.0-dev"
#endif

#define INTEGER_STRING_LENGTH 20 // max number of digits a 64-bit integer can use up as a string
                                 // this is for converting ints to strings when setting menu values/cookies

#include <cstrike>
#include <smlib>

char g_ColorNames[][] = {"{NORMAL}", "{DARK_RED}", "{PURPLE}", "{GREEN}", "{MOSS_GREEN}", "{LIGHT_GREEN}", "{LIGHT_RED}", "{GRAY}", "{ORANGE}", "{LIGHT_BLUE}", "{DARK_BLUE}", "{PURPLE}"};
char g_ColorCodes[][] =    {"\x01",     "\x02",      "\x03",   "\x04",         "\x05",     "\x06",          "\x07",        "\x08",   "\x09",     "\x0B",         "\x0C",        "\x0E"};

/**
 * Switches a player to a new team.
 */
stock void SwitchPlayerTeam(int client, int team) {
    if (GetClientTeam(client) == team)
        return;

    g_PluginTeamSwitch[client] = true;
    if (team > CS_TEAM_SPECTATOR) {
        CS_SwitchTeam(client, team);
        CS_UpdateClientModel(client);
    } else {
        ChangeClientTeam(client, team);
    }
    g_PluginTeamSwitch[client] = false;
}

/**
 * Returns if the 2 players should be fighting each other.
 * Returns false on friendly fire/suicides.
 */
stock bool HelpfulAttack(int attacker, int victim) {
    if (!IsValidClient(attacker) || !IsValidClient(victim)) {
        return false;
    }
    int ateam = GetClientTeam(attacker); // Get attacker's team
    int vteam = GetClientTeam(victim);   // Get the victim's team
    return ateam != vteam && attacker != victim;
}

/**
 * Returns the Human counts of the T & CT Teams.
 * Use this function for optimization if you have to get the counts of both teams,
 */
stock void GetTeamsClientCounts(int &tHumanCount, int &ctHumanCount) {
    for (int client = 1; client <= MaxClients; client++) {
        if (IsClientConnected(client) && IsClientInGame(client)) {
            if (GetClientTeam(client) == CS_TEAM_T)
                tHumanCount++;

            else if (GetClientTeam(client) == CS_TEAM_CT)
                ctHumanCount++;
        }
    }
}

/**
 * Returns the number of players currently on an active team (T/CT).
 */
stock int GetActivePlayerCount() {
    int count = 0;
    for (int client = 1; client <= MaxClients; client++) {
        if (IsClientConnected(client) && IsClientInGame(client)) {
            if (GetClientTeam(client) == CS_TEAM_T)
                count++;
            else if (GetClientTeam(client) == CS_TEAM_CT)
                count++;
        }
    }
    return count;
}


/**
 * Returns if a player is on an active/player team.
 */
stock bool IsOnTeam(int client) {
    int team = GetClientTeam(client);
    return (team == CS_TEAM_CT) || (team == CS_TEAM_T);
}

stock bool IsConnected(int client) {
    return client > 0 && client <= MaxClients && IsClientConnected(client) && !IsFakeClient(client);
}

/**
 * Function to identify if a client is valid and in game.
 */
stock bool IsValidClient(int client) {
    if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
        return true;
    return false;
}

/**
 * Function to identify if a client is valid and in game.
 */
stock bool IsPlayer(int client) {
    return IsValidClient(client) && !IsFakeClient(client);
}

/**
 * Adds an integer to a menu as a string choice.
 */
stock void AddMenuInt(Handle menu, int value, const char[] display) {
    char buffer[INTEGER_STRING_LENGTH];
    IntToString(value, buffer, sizeof(buffer));
    AddMenuItem(menu, buffer, display);
}

/**
 * Adds an integer to a menu as a string choice with the integer as the display.
 */
stock void AddMenuInt2(Handle menu, int value) {
    char buffer[INTEGER_STRING_LENGTH];
    IntToString(value, buffer, sizeof(buffer));
    AddMenuItem(menu, buffer, buffer);
}

/**
 * Gets an integer to a menu from a string choice.
 */
stock int GetMenuInt(Handle menu, int param2) {
    char choice[INTEGER_STRING_LENGTH];
    GetMenuItem(menu, param2, choice, sizeof(choice));
    return StringToInt(choice);
}

/**
 * Adds a boolean to a menu as a string choice.
 */
stock void AddMenuBool(Handle menu, bool value, const char[] display) {
    int convertedInt = value ? 1 : 0;
    AddMenuInt(menu, convertedInt, display);
}

/**
 * Gets a boolean to a menu from a string choice.
 */
stock bool GetMenuBool(Handle menu, int param2) {
    return GetMenuInt(menu, param2) != 0;
}

/**
 * Returns a random index from an array.
 */
stock int RandomIndex(Handle array) {
    int len = GetArraySize(array);
    if (len == 0)
        ThrowError("Can't get random index from empty array");
    return GetRandomInt(0, len - 1);
}

/**
 * Returns a random element from an array.
 */
stock int RandomElement(Handle array) {
    return GetArrayCell(array, RandomIndex(array));
}

/**
 * Returns a randomly-created boolean.
 */
stock bool GetRandomBool() {
    return GetRandomInt(0, 1) == 0;
}

/**
 * Sets a cookie to an integer value by converting it to a string.
 */
stock void SetCookieInt(int client, Handle cookie, int value) {
    char buffer[INTEGER_STRING_LENGTH];
    IntToString(value, buffer, sizeof(buffer));
    SetClientCookie(client, cookie, buffer);
}

/**
 * Fetches the value of a cookie that is an integer.
 */
stock int GetCookieInt(int client, Handle cookie) {
    char buffer[INTEGER_STRING_LENGTH];
    GetClientCookie(client, cookie, buffer, sizeof(buffer));
    return StringToInt(buffer);
}

/**
 * Sets a cookie to a boolean value.
 */
stock void SetCookieBool(int client, Handle cookie, bool value) {
    new convertedInt = value ? 1 : 0;
    SetCookieInt(client, cookie, convertedInt);
}

/**
 * Gets a cookie that represents a boolean.
 */
stock bool GetCookieBool(int client, Handle cookie) {
    return GetCookieInt(client, cookie) != 0;
}

stock bool Chance(float p) {
    float f = GetRandomFloat();
    return f < p;
}
/**
 * Creates a table given an array of table arguments.
 */
stock void SQL_CreateTable(Handle db_connection, const char[] table_name, const char[][] fields, int num_fields) {
    char buffer[1024];
    Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS %s (", table_name);
    for (int i = 0; i < num_fields; i++) {
        StrCat(buffer, sizeof(buffer), fields[i]);
        if (i != num_fields - 1)
            StrCat(buffer, sizeof(buffer), ", ");
    }
    StrCat(buffer, sizeof(buffer), ")");

    if (!SQL_FastQuery(db_connection, buffer)) {
        char err[255];
        SQL_GetError(db_connection, err, sizeof(err));
        LogError(err);
    }
}

/**
 * Adds a new field to a table.
 */
stock void SQL_AddColumn(Handle db_connection, const char[] table_name, const char[] column_info) {
    char buffer[1024];
    Format(buffer, sizeof(buffer), "ALTER TABLE %s ADD COLUMN %s", table_name, column_info);
    if (!SQL_FastQuery(db_connection, buffer)) {
        char err[255];
        SQL_GetError(db_connection, err, sizeof(err));
        if (StrContains(err, "Duplicate column name", false) == -1) {
            LogError(err);
        }
    }
}

/**
 * Sets the primary key for a table.
 */
stock void SQL_UpdatePrimaryKey(Handle db_connection, const char[] table_name, const char[] primary_key) {
    char buffer[1024];
    Format(buffer, sizeof(buffer), "ALTER TABLE %s DROP PRIMARY KEY, ADD PRIMARY KEY (%s)", table_name, primary_key);
    if (!SQL_FastQuery(db_connection, buffer)) {
        char err[255];
        SQL_GetError(db_connection, err, sizeof(err));
        LogError(err);
    }
}

/**
 * Fills a buffer with the current map name,
 * with any directory information removed.
 * Example: de_dust2 instead of workshop/125351616/de_dust2
 */
stock void GetCleanMapName(char[] buffer, int size) {
    char mapName[128];
    GetCurrentMap(mapName, sizeof(mapName));
    int last_slash = 0;
    int len = strlen(mapName);
    for (int i = 0;  i < len; i++) {
        if (mapName[i] == '/')
            last_slash = i + 1;
    }
    strcopy(buffer, size, mapName[last_slash]);
}

/**
 * Applies colorized characters across a string to replace color tags.
 */
stock void Colorize(char[] msg, int size) {
    for (int i = 0; i < sizeof(g_ColorNames); i ++) {
        ReplaceString(msg, size, g_ColorNames[i], g_ColorCodes[i]);
    }
}

stock void StripColors(char[] msg, int size) {
    for (int i = 0; i < sizeof(g_ColorNames); i ++) {
        ReplaceString(msg, size, g_ColorNames[i], "");
    }
}
