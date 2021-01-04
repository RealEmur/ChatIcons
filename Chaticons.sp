#include <sourcemod>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Chat Icons", 
	author = "Emur", 
	description = "Players can use icons in the game chat", 
	version = "1.0", 
	url = "www.pluginmerkezi.com"
};

//Keep Icons And Triggers size same or it will cause problems.
char Icons[][256] = 
{
	"☻︎", 
	"☹︎", 
	"☘", 
	"❤︎", 
	"♫︎", 
	"✌︎", 
	"★", 
	"♨︎", 
	"☀︎", 
	"❄️", 
};
char Trigger[][256] = 
{
	":)", 
	":(", 
	":lucky:", 
	":heart:", 
	":music:", 
	":cool:", 
	":star:", 
	":hot:", 
	":sun:", 
	":snow:"
};

Cookie g_Enabled = null;
ConVar onlyAdmins = null;
bool messagesent[MAXPLAYERS] =  { false, ... };
public void OnPluginStart()
{
	RegConsoleCmd("sm_icons", command_icons);	
	g_Enabled = new Cookie("sm_chaticons_enabled", "With this option players can disable chat icons.", CookieAccess_Private);
	
	CreateDirectory("cfg/sourcemod/Emur", 3);
	onlyAdmins = CreateConVar("sm_onlyadmins", "", "If you want to only admins use this feature write here the flag otherwise leave it blank.", 0, true, 1.0, true, 3.0);
	AutoExecConfig(true, "chaticons", "sourcemod/Emur");

	LoadTranslations("chaticons.phrases.txt");
}

public Action command_icons(int client, int args)
{
	bool cookie = !GetCookie(client);
	SetCookie(client, cookie);
	
	char message[255];
	Format(message, sizeof(message), "[SM] %t", cookie ? "icons_disabled" : "icons_enabled");
	//This needed color fix. I dont want to use any color plugins.
	ReplaceString(message, sizeof(message), "{default}", "\x01");
	ReplaceString(message, sizeof(message), "{red}", "\x02");
	ReplaceString(message, sizeof(message), "{green}", "\x04");
	
	PrintToChat(client, message);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(!client)
		return Plugin_Continue;
	
	if (!messagesent[client] && !GetCookie(client) && CheckFlag(client))
	{
		//I thought checking the situation with a bool is a good idea. We don't need to waste a good sentence.
		bool contains = false;
		
		//Because of OnClientSayCommand paramatres we cant replace sArgs so I had to copy it
		char message[255];
		strcopy(message, sizeof(message), sArgs);
		
		for (int i = 0; i < sizeof(Icons); i++)
		{
			if (StrContains(sArgs, Trigger[i]) != -1)
			{
				if (!contains)contains = true;
				ReplaceString(message, sizeof(message), Trigger[i], Icons[i], false);
			}
		}
		if(contains){
			messagesent[client] = true;
			FakeClientCommand(client, "%s %s", command, message);
			return Plugin_Handled;
		}
	}
	else if (messagesent[client])
		messagesent[client] = false;
	return Plugin_Continue;
}

public bool CheckFlag(int client)
{
	char Flag[32];
	onlyAdmins.GetString(Flag, sizeof(Flag));
	if(!StrEqual(Flag, "")) return CheckAdminFlag(client, Flag);		
	return true;
}

public int GetCookie(int client)
{
	if (AreClientCookiesCached(client))
	{
		char buffer[16];
		g_Enabled.Get(client, buffer, sizeof(buffer));
		return StringToInt(buffer);
	}
	else
		return 0;
}

public void SetCookie(int client, int value)
{
	char buffer[16];
	IntToString(value, buffer, sizeof(buffer));
	g_Enabled.Set(client, buffer);
}

public bool CheckAdminFlag(int client, const char[] flags)
{
	int iCount = 0;
	char sflagNeed[22][8], sflagFormat[64];
	bool bEntitled = false;
	Format(sflagFormat, sizeof(sflagFormat), flags);
	ReplaceString(sflagFormat, sizeof(sflagFormat), " ", "");
	iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[]));
	for (int i = 0; i < iCount; i++)
	{
		if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i])) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			bEntitled = true;
			break;
		}
	}
	return bEntitled;
}