/***************************************************************************************

	Copyright (C) 2012 BCServ (plugins@bcserv.eu)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
***************************************************************************************/

/***************************************************************************************


	C O M P I L E   O P T I O N S


***************************************************************************************/
// enforce semicolons after each code statement
#pragma semicolon 1

/***************************************************************************************


	P L U G I N   I N C L U D E S


***************************************************************************************/
#include <sourcemod>
#include <sdktools>
#include <smlib>
#include <smlib/pluginmanager>


/***************************************************************************************


	P L U G I N   I N F O


***************************************************************************************/
public Plugin:myinfo = {
	name 						= "Spec Poke",
	author 						= "BCServ",
	description 				= "Pokes spectators with a hud menu, when they are afk for a given time",
	version 					= "1.0",
	url 						= "http://bcserv.eu/"
}

/***************************************************************************************


	P L U G I N   D E F I N E S


***************************************************************************************/


/***************************************************************************************


	G L O B A L   V A R S


***************************************************************************************/
// Server Variables


// Plugin Internal Variables


// Console Variables
new Handle:g_cvarEnable = INVALID_HANDLE;
new Handle:g_cvarTimeout = INVALID_HANDLE;
new Handle:g_cvarNextTimeout = INVALID_HANDLE;
new Handle:g_cvarCountDown = INVALID_HANDLE;
new Handle:g_cvarDetect_Mouse = INVALID_HANDLE;
new Handle:g_cvarDetect_Buttons = INVALID_HANDLE;

// Console Variables: Runtime Optimizers
new g_iPlugin_Enable = 1;
new g_iPlugin_Timeout = 60;
new g_iPlugin_NextTimeout = 300;
new g_iPlugin_CountDown = 30;
new bool:g_bPlugin_Detect_Mouse = true;
new bool:g_bPlugin_Detect_Buttons = true;

// Timers


// Library Load Checks


// Game Variables


// Map Variables


// Client Variables
new g_iClient_Timeout[MAXPLAYERS+1];

// M i s c


/***************************************************************************************


	F O R W A R D   P U B L I C S


***************************************************************************************/
public OnPluginStart()
{
	// Initialization for SMLib
	PluginManager_Initialize("spec-poke", "[SM] ");
	
	// Translations
	// LoadTranslations("common.phrases");
	
	
	// Command Hooks (AddCommandListener) (If the command already exists, like the command kill, then hook it!)
	
	
	// Register New Commands (PluginManager_RegConsoleCmd) (If the command doesn't exist, hook it here)
	
	
	// Register Admin Commands (PluginManager_RegAdminCmd)
	
	
	// Cvars: Create a global handle variable.
	g_cvarEnable = PluginManager_CreateConVar("enable", "1", "Enables or disables this plugin.");
	g_cvarTimeout = PluginManager_CreateConVar("timeout", "60", "How many seconds must pass, until a player is poked.");
	g_cvarNextTimeout = PluginManager_CreateConVar("next_timeout", "300", "After a player has showen that he is there, how many seconds must pass, until a player is poked AGAIN.");
	g_cvarCountDown = PluginManager_CreateConVar("countdown", "30", "How long should the player be poked until he is kicked.");
	g_cvarDetect_Mouse = PluginManager_CreateConVar("detect_mouse", "1", "Detect mouse movement and accept this as sign that the player is still behind the screen.");
	g_cvarDetect_Buttons = PluginManager_CreateConVar("detect_buttons", "1", "Detect button presses and accept this as sign that the player is still behind the screen.");
	
	// Hook ConVar Change
	HookConVarChange(g_cvarEnable, ConVarChange_Enable);
	HookConVarChange(g_cvarTimeout, ConVarChange_Timeout);
	HookConVarChange(g_cvarNextTimeout, ConVarChange_NextTimeout);
	HookConVarChange(g_cvarCountDown, ConVarChange_CountDown);
	HookConVarChange(g_cvarDetect_Mouse, ConVarChange_Detect_Mouse);
	HookConVarChange(g_cvarDetect_Buttons, ConVarChange_Detect_Buttons);
	
	
	// Event Hooks
	
	
	// Library
	
	
	/* Features
	if(CanTestFeatures()){
		
	}
	*/
	
	// Create ADT Arrays
	
	
	// Timers
	CreateTimer(1.0, Timer_Think, INVALID_HANDLE, TIMER_REPEAT);
	
}

public OnMapStart()
{
	
}

public OnConfigsExecuted()
{
	// Set your ConVar runtime optimizers here
	g_iPlugin_Enable = GetConVarInt(g_cvarEnable);
	g_iPlugin_Timeout = GetConVarInt(g_cvarTimeout);
	g_iPlugin_NextTimeout = GetConVarInt(g_cvarNextTimeout);
	g_iPlugin_CountDown = GetConVarInt(g_cvarCountDown);
	g_bPlugin_Detect_Mouse = GetConVarBool(g_cvarDetect_Mouse);
	g_bPlugin_Detect_Buttons = GetConVarBool(g_cvarDetect_Buttons);
	
	// Mind: this is only here for late load, since on map change or server start, there isn't any client.
	// Remove it if you don't need it.
	Client_InitializeAll();
}

public OnClientPutInServer(client)
{
	Client_Initialize(client);
}

public OnClientPostAdminCheck(client)
{
	Client_Initialize(client);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	if (g_iPlugin_Enable == 0) {
		return Plugin_Continue;
	}

	if (g_iClient_Timeout[client] >= g_iPlugin_Timeout) {
		return Plugin_Continue;
	}

	if (g_bPlugin_Detect_Mouse && (mouse[0] != 0 || mouse[1] != 0)) {

		g_iClient_Timeout[client] = g_iPlugin_Timeout;
		return Plugin_Continue;
	}

	if (g_bPlugin_Detect_Buttons && buttons != 0) {

		g_iClient_Timeout[client] = g_iPlugin_Timeout;
		return Plugin_Continue;
	}

	return Plugin_Continue;
}

/**************************************************************************************


	C A L L B A C K   F U N C T I O N S


**************************************************************************************/
public Action:Timer_Think(Handle:timer)
{
	if (g_iPlugin_Enable == 0) {
		return Plugin_Continue;
	}

	LOOP_CLIENTS(client, CLIENTFILTER_INGAMEAUTH) {

		new team = GetClientTeam(client);
		if (team == TEAM_ONE || team == TEAM_TWO) {

			g_iClient_Timeout[client] = g_iPlugin_Timeout;
			continue;
		}

		if (g_iClient_Timeout[client] <= 0) {
			ShowPokeMenu(client);
		}

		if (g_iPlugin_CountDown + g_iClient_Timeout[client] <= 0) {
			//PrintToServer("like to kick player %N",client);
			LogAction(client, -1, "Has been auto kicked for being afk as spectator");
			KickClient(client, "Auto kick for being idle as spectator");
		}

		//PrintToChat(client, "g_iClient_Timeout[client]: %d", g_iClient_Timeout[client]);
		//PrintToChat(client, "g_iPlugin_CountDown + g_iClient_Timeout[client]: %d", g_iPlugin_CountDown + g_iClient_Timeout[client]);

		g_iClient_Timeout[client] -= 1;
	}


	return Plugin_Continue;
}

/**************************************************************************************

	C O N  V A R  C H A N G E

**************************************************************************************/
/* Example Callback Con Var Change */
public ConVarChange_Enable(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iPlugin_Enable = StringToInt(newVal);
}
public ConVarChange_Timeout(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iPlugin_Timeout = StringToInt(newVal);
}
public ConVarChange_NextTimeout(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iPlugin_NextTimeout = StringToInt(newVal);
}
public ConVarChange_CountDown(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_iPlugin_CountDown = StringToInt(newVal);
}
public ConVarChange_Detect_Mouse(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bPlugin_Detect_Mouse = bool:StringToInt(newVal);
}
public ConVarChange_Detect_Buttons(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_bPlugin_Detect_Buttons = bool:StringToInt(newVal);
}

/**************************************************************************************

	C O M M A N D S

**************************************************************************************/
/* Example Command Callback
public Action:Command_(client, args)
{
	
	return Plugin_Handled;
}
*/


/**************************************************************************************

	E V E N T S

**************************************************************************************/
/* Example Callback Event
public Action:Event_Example(Handle:event, const String:name[], bool:dontBroadcast)
{

}
*/


/***************************************************************************************


	P L U G I N   F U N C T I O N S


***************************************************************************************/
stock ShowPokeMenu(client){

	new Handle:menu = CreateMenu(MenuHandler_ShowPokeMenu);
	
	new String:title[128];
	Format(title, sizeof(title), "Hey are you still there?\n \nPress the following key\nor you'll be kicked\nin %d seconds!\n ", g_iPlugin_CountDown + g_iClient_Timeout[client]);
	SetMenuTitle(menu, title);
	
	AddMenuItem(menu,"1","Yes I'm still alive!");
	//AddMenuItem(menu,"-2","--------------------------------",ITEMDRAW_DISABLED);
	
	DisplayMenu(menu, client, 1);
}

public MenuHandler_ShowPokeMenu(Handle:menu, MenuAction:action, param1, param2){
	
	new client = param1;
	if (action == MenuAction_Select) {
		
		new String:preference[11];
		if(GetMenuItem(menu, param2, preference, sizeof(preference))){

			g_iClient_Timeout[client] = g_iPlugin_NextTimeout;
		}
	}
	else if (action == MenuAction_End) {

		CloseHandle(menu);
	}
}

/***************************************************************************************

	S T O C K

***************************************************************************************/
stock Client_InitializeAll()
{
	LOOP_CLIENTS (client, CLIENTFILTER_ALL) {
		
		Client_Initialize(client);
	}
}

stock Client_Initialize(client)
{
	// Variables
	Client_InitializeVariables(client);
	
	
	// Functions
	
	
	/* Functions where the player needs to be in game 
	if(!IsClientInGame(client)){
		return;
	}
	*/
}

stock Client_InitializeVariables(client)
{
	// Client Variables
	g_iClient_Timeout[client] = g_iPlugin_Timeout;
}


