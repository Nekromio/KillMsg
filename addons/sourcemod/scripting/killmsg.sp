#pragma semicolon 1
#pragma newdecls required

#include <sdktools_stringtables>
#include <smartdm>

ConVar
	cvKnife,
	cvTimeOverlay,
	cvOrdinary,
	cvMaxKills,
	cvHead,
	cvHe;

Handle
	hTimerOverlay[MAXPLAYERS+1];
	
int
	iCountKill[MAXPLAYERS+1];

char
	sKnife[512],
	sOrdinary[20][515],
	sHead[512],
	sHe[512];

public Plugin myinfo = 
{
	name = "Kill Message Overlays",
	author = "Nek.a 2x2",
	description = "Kill Message Overlays",
	version = "1.0.1",
	url = "https://ggwp.site/"
}

public void OnPluginStart()
{
	cvTimeOverlay = CreateConVar("sm_killmsg_timeoverlay", "3.0", "Время отображения оверлея");
	
	cvKnife = CreateConVar("sm_killmsg_knife", "killmessages/ggwp/2v/killsilver_knife", "Убийство с ножом");

	cvOrdinary = CreateConVar("sm_killmsg_ordinary", "killmessages/ggwp/2v/killsilver_", "Обычное убийство");
	
	cvHead = CreateConVar("sm_killmsg_head", "killmessages/ggwp/2v/killsilver_headshot", "Убийство в голову");
	
	cvHe = CreateConVar("sm_killmsg_he", "killmessages/ggwp/2v/killsilver_grenade", "Убийство гранатой");
	
	cvMaxKills = CreateConVar("sm_killmsg_maxkills",	"8", "Максимальное количество убийств в серии (максимум 20)");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("round_end", Event_RoundReset, EventHookMode_Post);
	HookEvent("round_start", Event_RoundReset, EventHookMode_Pre);

	AutoExecConfig(true, "KillMsg");
}

public void OnMapStart()
{
	char sBuffer[512];
	
	cvKnife.GetString(sBuffer, sizeof(sBuffer));
	
	if(sBuffer[0])
	{
		Format(sBuffer, sizeof(sBuffer), "materials/%s.vmt", sBuffer);
		PrecacheModel(sBuffer, true);
		Downloader_AddFileToDownloadsTable(sBuffer);
		sKnife = sBuffer;
		ReplaceString(sKnife, sizeof(sKnife), "materials/", "");
	}
	
	cvOrdinary.GetString(sBuffer, sizeof(sBuffer));
	
	if(sBuffer[0])
	{
		char sFormat[512];
		for(int i; i <= cvMaxKills.IntValue -1; i++)
		{
			int d = i;
			Format(sFormat, sizeof(sFormat), "materials/%s%d.vmt", sBuffer, d+1);
			sOrdinary[i] = sFormat;
			PrecacheModel(sFormat, true);
			Downloader_AddFileToDownloadsTable(sFormat);
			ReplaceString(sOrdinary[i], sizeof(sOrdinary[]), "materials/", "");
		}
	}
	
	cvHead.GetString(sBuffer, sizeof(sBuffer));
	
	if(sBuffer[0])
	{
		Format(sBuffer, sizeof(sBuffer), "materials/%s.vmt", sBuffer);
		PrecacheModel(sBuffer, true);
		Downloader_AddFileToDownloadsTable(sBuffer);
		sHead = sBuffer;
		ReplaceString(sHead, sizeof(sHead), "materials/", "");
	}
	
	cvHe.GetString(sBuffer, sizeof(sBuffer));
	
	if(sBuffer[0])
	{
		Format(sBuffer, sizeof(sBuffer), "materials/%s.vmt", sBuffer);
		PrecacheModel(sBuffer, true);
		Downloader_AddFileToDownloadsTable(sBuffer);
		sHe = sBuffer;
		ReplaceString(sHe, sizeof(sHe), "materials/", "");
	}
}

public void OnClientConnected(int client)
{
	if(hTimerOverlay[client])
		delete hTimerOverlay[client];
}

Action OverlayEndTimer(Handle timer, any UserID)
{
	int client = GetClientOfUserId(UserID);
	
	if(!IsValidClient(client))
		return Plugin_Continue;
		
	OverlayEnd(client);
	hTimerOverlay[client] = null;
	return Plugin_Continue;
}

void OverlayEnd(int client)
{
	ClientCommand(client, "r_screenoverlay \"\"");
}

Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!(IsValidClient(client) || IsValidClient(attacker)))
		return Plugin_Continue;

	char sWeapon[11];
	GetEventString(event, "weapon", sWeapon, 11);
	
	if(GetEventBool(event, "headshot"))
	{
		OnOverlay(attacker, sHead);
	}
	else if(!strcmp(sWeapon, "hegrenade"))
	{
		OnOverlay(attacker, sHe);
	}
	else if(!strncmp(sWeapon, "knife", 5) || !strcmp(sWeapon, "bayonet"))
	{				
		OnOverlay(attacker, sKnife);
	}
	else
	{
		OnOverlay(attacker, sOrdinary[iCountKill[attacker]]);
	}
	
	iCountKill[attacker]++;
	
	if(iCountKill[attacker] >= cvMaxKills.IntValue)
		iCountKill[attacker] = 0;
		
	iCountKill[client] = 0;
	
	return Plugin_Continue;
}

void Event_RoundReset(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
		iCountKill[i] = 0;
}

void OnOverlay(int client, char[] sOverlay)
{
	ClientCommand(client, "r_screenoverlay \"%s\"", sOverlay);

	if(hTimerOverlay[client])
		delete hTimerOverlay[client];
	hTimerOverlay[client] = CreateTimer(cvTimeOverlay.FloatValue, OverlayEndTimer, GetClientUserId(client));
}

bool IsValidClient(int client)
{
	if(0 < client <= MaxClients)
		return true;
	else
		return false;
}