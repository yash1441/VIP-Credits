#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Simon"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <store>

#pragma newdecls required

#define CHAT_PREFIX "[VIP]"

Handle g_hCreditsTime;
Handle g_hCreditsBronze;
Handle g_hCreditsSilver;
Handle g_hCreditsGold;

float g_fCreditsTime;
int g_CreditsBronze;
int g_CreditsSilver;
int g_CreditsGold;

int isVIP[MAXPLAYERS + 1] =  { 0, ... };

Handle clientTimers[MAXPLAYERS + 1];

char g_CfgPath[PLATFORM_MAX_PATH];

EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "VIP Credits",
	author = PLUGIN_AUTHOR,
	description = "VIP Credits for Zephyrus Store",
	version = PLUGIN_VERSION,
	url = "yash1441@yahoo.com"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	CreateConVar("vc_version", PLUGIN_VERSION, "VIP Credits Version", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_hCreditsTime = CreateConVar("vc_time", "60", "After how many seconds to award credits.");
	g_hCreditsBronze = CreateConVar("vc_bronze", "200", "Credits to award to Bronze VIP.");
	g_hCreditsSilver = CreateConVar("vc_silver", "200", "Credits to award to Silver VIP.");
	g_hCreditsGold = CreateConVar("vc_gold", "300", "Credits to award to Gold VIP.");
	
	g_fCreditsTime = GetConVarFloat(g_hCreditsTime);
	g_CreditsBronze = GetConVarInt(g_hCreditsBronze);
	g_CreditsSilver = GetConVarInt(g_hCreditsSilver);
	g_CreditsGold = GetConVarInt(g_hCreditsGold);
	
	HookConVarChange(g_hCreditsTime, OnConVarChanged);
	HookConVarChange(g_hCreditsBronze, OnConVarChanged);
	HookConVarChange(g_hCreditsSilver, OnConVarChanged);
	HookConVarChange(g_hCreditsGold, OnConVarChanged);
	
	BuildPath(Path_SM, g_CfgPath, sizeof(g_CfgPath), "configs/viplist.txt");
}

public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hCreditsTime)
	{
		g_fCreditsTime = GetConVarFloat(g_hCreditsTime);
	}
	
	else if (convar == g_hCreditsBronze)
	{
		g_CreditsBronze = GetConVarInt(g_hCreditsBronze);
	}
	
	else if (convar == g_hCreditsSilver)
	{
		g_CreditsSilver = GetConVarInt(g_hCreditsSilver);
	}
	
	else if (convar == g_hCreditsGold)
	{
		g_CreditsGold = GetConVarInt(g_hCreditsGold);
	}
}

public void OnClientPostAdminCheck(int client)
{
	CheckVIP(client);
}

public void OnClientDisconnect(int client)
{
	if (isVIP[client] != 0) isVIP[client] = 0;
	ClearTimer(clientTimers[client]);
}

public void CheckVIP(int client)
{
	if(!FileExists(g_CfgPath))
	{
		SetFailState("%s Configuration text file %s not found.", CHAT_PREFIX, g_CfgPath);
	}
	
	Handle rFile = OpenFile(g_CfgPath, "r");
	char buffer[150];
	char steamid[MAX_NAME_LENGTH];
	char bufferparts[2][50];

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	PrintToChatAll("[DEBUG] STEAM ID of %N is %s", client, steamid);
	
	while (ReadFileLine(rFile, buffer, sizeof(buffer)))
	{
		ReplaceString(buffer, sizeof(buffer), "\n", "", false);
		if (!buffer[0] || buffer[0] == ';' || buffer[0] == '/' && buffer[1] == '/') continue;
		ExplodeString(buffer, "-", bufferparts, 2, sizeof(bufferparts[]));
		if(StrContains(bufferparts[0], "STEAM_", true) != -1)
		{
			if(StrEqual(bufferparts[0], steamid, true))
			{
				isVIP[client] = StringToInt(bufferparts[1]);
				PrintToChatAll("[DEBUG] VIP Level of %N is %i", client, isVIP[client]);
				break;
			}
		}
		PrintToChatAll("[DEBUG] %N (%s) not found.", client, steamid);
	}
	CloseHandle(rFile);
	if (isVIP[client] > 0) StartTimers(client);
}

public void StartTimers(int client)
{
	clientTimers[client] = CreateTimer(g_fCreditsTime, GiveCredits, client, TIMER_REPEAT);
}

public Action GiveCredits(Handle timer, int client)
{
	int bonus;
	if (isVIP[client] == 1) bonus = g_CreditsBronze;
	else if (isVIP[client] == 2) bonus = g_CreditsSilver;
	else if (isVIP[client] == 3) bonus = g_CreditsGold;
	bonus = bonus + Store_GetClientCredits(client);
	Store_SetClientCredits(client, bonus);
	PrintToChatAll("%s %N just got %i credits for being a VIP.", CHAT_PREFIX, client, bonus);
}

public void ClearTimer(Handle Timer)
{
    if(Timer != INVALID_HANDLE)
	{
		CloseHandle(Timer);
		Timer = INVALID_HANDLE;
	}
}