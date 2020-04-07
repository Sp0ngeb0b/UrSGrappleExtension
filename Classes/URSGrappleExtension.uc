/*
 *  ChangeLog:
 *
 *  *Version _6*  [Added]   Further insane combo messages
 *                [Fixed]   Accessed nones with bots
 *                [Fixed]   Color tags with disabled NexgenHUD
 *                [Misc]    Compiled for Nexgen112
 *
 *  *Version _5m* [Removed] Features now taken care of by NexgenATB
 *
 *  *Version _5l* [Changed] Timestamp format for special event logs
 *                [Added]   Special event log entry AUTO or MAN
 *
 *  *Version _5k* [Added]   Broadcasted message for insane combos
 *                [Added]   Log feature with auto logging for insane combos
 *
 *  *Version _5j2 [Fixed]   NXP spawn protection overlay not working properly
 *
 *  *Version _5j* [Added]   Custom spawn protection which excludes flag carrier kills
 *
 *  *Version _5i* [Misc]    Compiled for SmartCTF_4E_UrSg
 * 
 *  *Version _5h* [Misc]    Compiled for SmartCTF_4E_UrSe
 *
 *  *Version _5g* [Fixed]   CTF announcer now listens to volume control (like other announcer sounds)
 *                [Added]   UTPure style hitsounds (+enable/disable clientside option)
 * 
 *  *Version _5f* [Fixed]   Non-human clients allowed as spectators.
 *                [Added]   Included functionality of UrSGrappleS (+ "You have the flag" sound)
 *                [Added]   Added client config for CTF sounds and playername HUD
 *                [Added]   "Play" sound on gamestart + "You are on the X team" on join
 *                
 *  *Version _5e* [Changed] Renamed CountryFlags3 package to CountryFlags3UrS since 
 *                          someone though it would be a good idea to name his package
 *                          CountryFlags3 without publically releasing it (missmatch)
 *                [Added]   RextendedCTF HUD (flag countdown and carrier names)
 *
 *  *Version _5d* [Added]   Let Nexgen use new CountryFlags3 package (for our serbian guys)
 *                [Fixed]   Advanced TeamSay when carrying flag
 *
 *  *Version _5c* [Added]   UTPure style advanced TeamSay
 *                [Added]   Bots automatically added when only 1 player is online
 *                [Added]   Only human skins are allowed
 *
 *  *Version _5b* [Added]   Lag Compensation notification and ingame client settings panel
 *                [Added]   Info button to bring up first time popup window again
 *  
 *  *Version_5*   [Misc]    Compiled for SmartCTF_4E_UrSd2 
 *                [Misc]    Adjusted to 2019 server. 
 *                [Added]   SpawnActors can be configured.
 *  
 *  *Version _4c* [Misc]    Compiled for SmartCTF_4E_UrSd
 *
 *  *Version _2f* [Added]   Hack fix to make ACE crosshair scaling work with Nexgen
 *
 *  *Version _2e* [Misc]    Adjusted to new Germany server
 *
 *  *Version _2d* [Misc]    Compatible with SmartCTF_4E_UrSc
 *
 *  *Version _2c* [Misc]    Compatible with SmartCTF_4E_UrS
 *
 *  *Version _2*  [Added]   Facebook logo on login HUD
 *                [Added]   FB and UrS logo on Scoreboard
 *                [Added]   FB and UrS button on ServerInfo panel (link to websites)
 *
 *
 *  *Version 2h*  [Added]   Control panel for the settings
 *                [Added]   Text at Intro can now be specified
 *                [Changed] Intro logo will come up after 1 second
 *                [Fixed]   Message will only come up on players
 *
 *  *Version 2f*  [Added]   Message to inform when stats are restored.
 *
 *  *Version 2e*  [Fixed]   Stats-Restoring finally working probably.
 *                [Removed] Log entries
 *                [Changed] Hud appearence
 *
 *  *Version 2d*  [Fixed]   HUD compatibility with Pure
 *                [Added]   Log entries to understand why stats are not restoring
 *
 *  *Version 2b*  [Fixed]   Compatibility issues with AutoTeamBalancer
 *
 *  *Version 2*   [Fixed]   UTPure overwriting welcome messages
 *                [Changed] Welcome Dialog
 *
 **************************************************************************************************/
class URSGrappleExtension extends NexgenPlugin;

var URSGrappleConfig conf;                     // Plugin configuration.

var int playerCount;

var bool bRunningLC;

var SmartCTFGameReplicationInfo SCTFGame;

// Flag info
var int    countDown[2];
var float  flagDropTime[2];
var string flagCarrier[2];

// CTF Sounds
var Sound CTFSoundCap[2];
var Sound CTFSoundDrop[2];
var Sound CTFSoundReturn[2];
var Sound CTFSoundTaken[2];
var Sound CTFSoundTeam[2];
var Sound CTFSoundReturnExtra;
var Sound CTFSoundTakenYou;

// Messages
var localized string multiKillMessage[5];         // Multi kill message strings.
var localized string cheaterMessage;              // Message for extreme players.
var localized string insaneComboMessage;          // Message for an insane combo.
var localized string insaneComboMessageWicked[5]; // Messages for a wicked insane combo.

// Extra player attributes.
const PA_Captures = "captures";
const PA_Assists = "assists";
const PA_Grabs = "grabs";
const PA_Covers = "covers";
const PA_Seals = "seals";
const PA_FlagKills = "flagKills";
const PA_DefKills = "defKills";
const PA_Frags = "frags";
const PA_Combos = "combos";
const PA_InsaneCombos = "insaneCombos";
const PA_HeadShots = "headShots";

// Misc settings.
const maxMultiScoreInterval = 3.0;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Initializes the plugin. Note that if this function returns false the plugin will
 *                be destroyed and is not to be used anywhere.
 *  $RETURN       True if the initialization succeeded, false if it failed.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool initialize() {
  local byte i;
  local FlagBase fb;
  local CTFFlag flg;
	local int indexActor;
  local class<Actor> ActorClass;
  local XC_LagCompensation LC;
  
	// Load settings.
	if (control.bUseExternalConfig) {
		conf = spawn(class'URSGrappleConfigExt', self);
	} else {
		conf = spawn(class'URSGrappleConfigSys', self);
	}
	
	control.sConf.serverInfoPanelClass = class'URSRCPGrapple';

  getSCTFGame();

  for(indexActor=0; indexActor<ArrayCount(conf.spawnActors); indexActor++) {
    if(conf.spawnActors[indexActor] == "") break;
    
    Log(pluginName$": Spawning "$conf.spawnActors[indexActor]$" ...");
    
    ActorClass = class<Actor>(DynamicLoadObject(conf.spawnActors[indexActor],class'Class'));
    
    spawn(ActorClass);
  }
  
  // Locate Lag Compensator
  foreach AllActors(class'XC_LagCompensation', LC) {
    bRunningLC = true;
    break;
  }
  
  // Init flag variables
  flagDropTime[0] = -999;
  flagDropTime[1] = -999;
  
  // Load CTF sounds
  for(i=0; i<2; i++) {
    CTFSoundCap[i]    = Sound(dynamicLoadObject(conf.CTFSoundCap[i], class'Sound'));
    CTFSoundDrop[i]   = Sound(dynamicLoadObject(conf.CTFSoundDrop[i], class'Sound'));
    CTFSoundReturn[i] = Sound(dynamicLoadObject(conf.CTFSoundReturn[i], class'Sound'));
    CTFSoundTaken[i]  = Sound(dynamicLoadObject(conf.CTFSoundTaken[i], class'Sound'));
    CTFSoundTeam[i]   = Sound(dynamicLoadObject(conf.CTFSoundTeam[i], class'Sound'));
  }
  CTFSoundReturnExtra = Sound(dynamicLoadObject(conf.CTFSoundReturnExtra, class'Sound'));
  CTFSoundTakenYou    = Sound(dynamicLoadObject(conf.CTFSoundTakenYou, class'Sound'));
  
  // Set non-announcer CTF sounds already
  if (Level.Game.IsA('CTFGame')) {
      if (CTFSoundCap[0] != None)      CTFGame(Level.Game).CaptureSound[0] = CTFSoundCap[0];
      if (CTFSoundCap[1] != None)      CTFGame(Level.Game).CaptureSound[1] = CTFSoundCap[1];
      if (CTFSoundReturnExtra != None) CTFGame(Level.Game).ReturnSound     = CTFSoundReturnExtra;
  }

  setTimer(0.1, true);
  
	return true;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Timer to compute CTF Flags countdown
 *
 **************************************************************************************************/
function timer() {
  countDown[0] = fclamp(26.0 - (Level.TimeSeconds - flagDropTime[0]), -1, 26);
  countDown[1] = fclamp(26.0 - (Level.TimeSeconds - flagDropTime[1]), -1, 26);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a player attempts to login to the server. Allows mutators to modify
 *                some of the login parameters.
 *  $PARAM        spawnClass  The PlayerPawn class to use for the player.
 *  $PARAM        portal      Name of the portal where the player wishes to spawn.
 *  $PARAM        option      Login option parameters.
 *
 **************************************************************************************************/
function modifyLogin(out class<playerpawn> spawnClass, out string portal, out string options) {
  
	if(!classIsChildOf(spawnClass, class'Spectator') && 
     (InStr(CAPS(options), "TBOSS") != -1 || InStr(CAPS(options), "SKELETALCHARS") != -1)) spawnClass = Level.Game.DefaultPlayerClass; 
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Fixes Stats-restoring bug.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function getSCTFGame() {

  foreach allActors(class'SmartCTFGameReplicationInfo', SCTFGame) {
		break;
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a new client has been created. Use this function to setup the new
 *                client with your own extensions (in order to support the plugin).
 *  $PARAM        client  The client that was just created.
 *  $REQUIRE      client != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function clientCreated(NexgenClient client) {
  local URSGrappleClient xClient;
  
	xClient = URSGrappleClient(client.addController(class'URSGrappleClient', self));
	
	xClient.conf = conf;
  xClient.bRunningLC = bRunningLC;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called whenever a client has finished its initialisation process. During this
 *                process things such as the remote control window are created. So only after the
 *                client is fully initialized all functions can be safely called.
 *  $PARAM        client  The client that has finished initializing.
 *  $REQUIRE      client != none
 *
 **************************************************************************************************/
function clientInitialized(NexgenClient client) {
  local URSGrappleClient xClient;
  local NXPClient NexgenPlusClient;
  
  // Locate this client's NXPClient instance
  xClient = URSGrappleClient(client.getController(class'URSGrappleClient'.default.ctrlID));
  if(xClient != None) {
    foreach AllActors(class'NXPClient', NexgenPlusClient) {
      if(NexgenPlusClient.Owner == client.player) {
        xClient.NPClient = NexgenPlusClient;
        break;
      }
    }
    if(xClient.NPClient == None) {
      log("NPClient not located!!! NexgenPlusClient is "$NexgenPlusClient);
    }
  } else log("xClient = None!");
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Locates the URSGrappleClient instance for the given actor.
 *  $PARAM        a  The actor for which the extended client handler instance is to be found.
 *  $REQUIRE      a != none
 *  $RETURN       The client handler for the given actor.
 *  $ENSURE       (!a.isA('PlayerPawn') ? result == none : true) &&
 *                imply(result != none, result.client.owner == a)
 *
 **************************************************************************************************/
function URSGrappleClient getXClient(Actor a) {
	local NexgenClient client;

	client = control.getClient(a);

	if (client == none) {
		return none;
	} else {
		return URSGrappleClient(client.getController(class'URSGrappleClient'.default.ctrlID));
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Forces Bots to respawn and thereby disappear according to minPlayers. 
 *
 **************************************************************************************************/
function removeBots() {
  local int i;
  local Bot botToRemove;
  
  if(DeathMatchPlus(Level.Game).NumBots > 0) {
    for(i=0; i<DeathMatchPlus(Level.Game).NumBots; i++) DeathMatchPlus(Level.Game).BotConfig.ConfigUsed[i] = 0; 
    foreach AllActors(class'Bot', botToRemove) {
      if(botToRemove != none) botToRemove.PlayerTimeOut();
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called whenever a player has joined the game (after its login has been accepted).
 *  $PARAM        client  The player that has joined the game.
 *  $REQUIRE      client != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function playerJoined(NexgenClient client) {
	local SmartCTFPlayerReplicationInfo pri;
	local URSGrappleClient xClient;
  
  // Bots
	if(!client.bSpectator && conf.botCountForSinglePlayer > 0 && DeathMatchPlus(Level.Game) != none) {
    playerCount++;
    if(playerCount == 1) DeathMatchPlus(Level.Game).MinPlayers = conf.botCountForSinglePlayer+1; 
    else {
      DeathMatchPlus(Level.Game).MinPlayers = 0;
      removeBots();
    }
  }
  
  xClient = URSGrappleClient(client.getController(class'URSGrappleClient'.default.ctrlID));
  
  // Spawn Protection.
  if (xClient != None && control.gInf.gameState == control.gInf.GS_Playing && !client.bSpectator) {
		xClient.spawnProtectionTimeX = conf.spawnProtectionTime;
	}

	if (SCTFGame == none) getSCTFGame();

	// Restore saved player data.
	if (SCTFGame != none) {
		pri = SCTFGame.getStats(client.player);
		if (pri != none && xClient != none) {
      xClient.SCTFPRI = pri;

      if (pri.captures     != client.pDat.getInt(PA_Captures,  pri.captures)  ||
          pri.assists      != client.pDat.getInt(PA_Assists,   pri.assists)   ||
          pri.grabs        != client.pDat.getInt(PA_Grabs,     pri.grabs)     ||
          pri.covers       != client.pDat.getInt(PA_Covers,    pri.covers)    ||
          pri.seals        != client.pDat.getInt(PA_Seals,     pri.seals)     ||
          pri.flagKills    != client.pDat.getInt(PA_FlagKills, pri.flagKills) ||
          pri.defKills     != client.pDat.getInt(PA_DefKills,  pri.defKills)  ||
          pri.frags        != client.pDat.getInt(PA_Frags,     pri.frags)     ||
          pri.combos       != client.pDat.getInt(PA_Combos,    pri.combos)    ||
          pri.insaneCombos != client.pDat.getInt(PA_InsaneCombos, pri.insaneCombos)   ||
          pri.headShots    != client.pDat.getInt(PA_HeadShots, pri.headShots)) {
			  xClient.bStatsRestored     = true;
        xClient.bStatsJustRestored = true;
      }
			pri.captures     = client.pDat.getInt(PA_Captures,  pri.captures);
			pri.assists      = client.pDat.getInt(PA_Assists,   pri.assists);
			pri.grabs        = client.pDat.getInt(PA_Grabs,     pri.grabs);
			pri.covers       = client.pDat.getInt(PA_Covers,    pri.covers);
			pri.seals        = client.pDat.getInt(PA_Seals,     pri.seals);
			pri.flagKills    = client.pDat.getInt(PA_FlagKills, pri.flagKills);
			pri.defKills     = client.pDat.getInt(PA_DefKills,  pri.defKills);
			pri.frags        = client.pDat.getInt(PA_Frags,     pri.frags);
      pri.combos       = client.pDat.getInt(PA_Combos,    pri.combos);
      pri.insaneCombos = client.pDat.getInt(PA_InsaneCombos, pri.insaneCombos);
			pri.headShots    = client.pDat.getInt(PA_HeadShots, pri.headShots);
		}
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called if a player has left the server.
 *  $PARAM        client  The player that has left the game.
 *  $REQUIRE      client != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function playerLeft(NexgenClient client) {
	local SmartCTFPlayerReplicationInfo pri, cPRI;
  
  // Check if he had the flag
  if(flagCarrier[0] == client.playerName) {
    flagCarrier[0] = "";
    playCTFSoundOnClients(CTFSoundReturn[0]);
  } else if(flagCarrier[1] == client.playerName) {
    flagCarrier[1] = "";
    playCTFSoundOnClients(CTFSoundReturn[1]);
  }
  
  // Bots
  if(!client.bSpectator && conf.botCountForSinglePlayer > 0 && DeathMatchPlus(Level.Game) != none) {
    playerCount--;
    if(playerCount == 1) DeathMatchPlus(Level.Game).MinPlayers = conf.botCountForSinglePlayer+1; 
    else {
      DeathMatchPlus(Level.Game).MinPlayers = 0;
      removeBots();
    }
  }
  
	if (SCTFGame == none) getSCTFGame();
	
	// Store saved player data.
	if (SCTFGame != none) {
		//pri = SCTFGame.getStats(client.player);
		foreach allActors(class'SmartCTFPlayerReplicationInfo', cPRI) {
			if (cPRI.owner == none) {
				if (pri == none) {
					pri = cPRI;
				} else {
					// Multiple pri's without owner, can't find player relations.
					pri = none;
					break;
				}
			}
		}
		
		if (pri != none) {
			client.pDat.set(PA_Captures,  pri.captures);
			client.pDat.set(PA_Assists,   pri.assists);
			client.pDat.set(PA_Grabs,     pri.grabs);
			client.pDat.set(PA_Covers,    pri.covers);
			client.pDat.set(PA_Seals,     pri.seals);
			client.pDat.set(PA_FlagKills, pri.flagKills);
			client.pDat.set(PA_DefKills,  pri.defKills);
			client.pDat.set(PA_Frags,     pri.frags);
      client.pDat.set(PA_Combos,    pri.combos);
      client.pDat.set(PA_InsaneCombos, pri.insaneCombos);
			client.pDat.set(PA_HeadShots, pri.headShots);
		}
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a player was killed by another player.
 *  $PARAM        killer  The pawn that killed the other pawn. Might be none.
 *  $PARAM        victim  Pawn that was the victim.
 *
 **************************************************************************************************/
function scoreKill(Pawn killer, Pawn victim) {
	local NexgenClient client;
	local URSGrappleClient xClient;
	
	if (killer != none && victim != none && killer != victim) {
		// Get extended client controller.
		client = control.getClient(killer);
		if (client != none) {
			xClient = URSGrappleClient(client.getController(class'URSGrappleClient'.default.ctrlID));
		}
		
		if (xClient != none) {
			// Check for double, multi, ultra and monsterrrrrrrr kills.
			if (level.timeSeconds - xClient.lastKillTime < maxMultiScoreInterval) {
				xClient.multiLevel++;
        broadcastMultiKill(xClient.multiLevel, client.playerName);
			} else {
				xClient.multiLevel = 0;
			}
			
			// Update last kill time.
			xClient.lastKillTime = level.timeSeconds;
		}
		
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks if the input string contains a parameter which is to be substituted
 *
 **************************************************************************************************/
function bool containsParameter(string s, NexgenClient client) {
  if(InStr(s, "%H") > -1 ||
       InStr(s, "%h") > -1 ||
       InStr(s, "%W") > -1 ||
       InStr(s, "%w") > -1 ||
       InStr(s, "%A") > -1 ||
       InStr(s, "%a") > -1 ||
       InStr(s, "%A") > -1 ||
       ((InStr(s, "%P") > -1 || InStr(s, "%p") > -1) && client.player.GameReplicationInfo.IsA('CTFReplicationInfo'))) return true;
       
  else return false;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Hooked into the message mutator chain so commands can be detected. This function
 *                is called if a message is send to player.
 *  $PARAM        sender    The actor that has send the message.
 *  $PARAM        receiver  Pawn receiving the message.
 *  $PARAM        pri       Player replication info of the sending player.
 *  $PARAM        s         The message that is to be send.
 *  $PARAM        type      Type of the message that is to be send.
 *  $PARAM        bBeep     Whether or not to make a beep sound once received.
 *  $RETURN       True if the message should be send, false if it should be suppressed.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool mutatorTeamMessage(Actor sender, Pawn receiver, PlayerReplicationInfo pri,
                                 coerce string s, name type, optional bool bBeep) {
	local NexgenClient client;
	local int pos, i, x, ArmorAmount, zzi;
  local string OutMsg, cmd;
  local inventory inv;
  local int zone;  // 0=Offense, 1 = Defense, 2= float
	local flagbase Red_FB, Blue_FB;
	local CTFFlag F,Red_F, Blue_F;
	local float dRed_b, dBlue_b, dRed_f, dBlue_f;

	// Check for commands.
	if (sender != none && sender.isA('PlayerPawn') && !sender.isA('Spectator') && type == 'TeamSay') {
    client = control.getClient(sender);
    
    if(client == none) return true;
          
    if(containsParameter(s, client)) {
       
      if(sender == receiver) {
        // Substitute all parameters (shamelessly borrowed from UTPure)
        pos = InStr(s,"%");
        
        for (i=0; i<100; i=1) {
          if (pos > 0) {
            OutMsg = OutMsg$Left(s,pos);
            s = Mid(s,pos);
            pos = 0;
          }
          
          x = len(s);
          cmd = Mid(s,pos,2);
          if (x-2 > 0) s = Right(s,x-2);
          else s = "";         
          
          if (cmd == "%H")                                      OutMsg = OutMsg$client.player.Health$" Health";
          else if (cmd == "%h")                                 OutMsg = OutMsg$client.player.Health$"%";
          else if (cmd ~= "%W" && client.player.Weapon != none) OutMsg = OutMsg$client.player.Weapon.GetHumanName();
          else if (cmd == "%A") {
            ArmorAmount = 0;
            for(Inv=client.player.Inventory; Inv!=None; Inv=Inv.Inventory) { 
              if (Inv.bIsAnArmor) {
                if(Inv.IsA('UT_Shieldbelt')) OutMsg = OutMsg$"ShieldBelt ("$Inv.Charge$") and ";
                else  ArmorAmount += Inv.Charge;
              }
            }
            OutMsg = OutMsg$ArmorAmount$" Armor";
          } else if (cmd == "%a") {
            ArmorAmount = 0;
            for(Inv=client.player.Inventory; Inv!=None; Inv=Inv.Inventory) { 
              if (Inv.bIsAnArmor) {
                if(Inv.IsA('UT_Shieldbelt')) OutMsg = OutMsg$Inv.Charge$"SB ";
                else ArmorAmount += Inv.Charge;
              }
            }
            OutMsg = OutMsg$ArmorAmount$"A";
          } else if (cmd ~= "%P" && client.player.GameReplicationInfo.IsA('CTFReplicationInfo')) {
            // Figure out Posture.
            
            for(zzi=0; zzi<4; zzi++) {
              F = CTFReplicationInfo(client.player.GameReplicationInfo).FlagList[zzi];
              if(F == None) break;
              if(F.HomeBase.Team == 0)      Red_FB = F.HomeBase;
              else if(F.HomeBase.Team == 1) Blue_FB = F.HomeBase;
              if(F.Team == 0)      Red_F = F;
              else if(F.Team == 1) Blue_F = F;
            }

            dRed_b  = VSize(client.player.Location - Red_FB.Location);
            dBlue_b = VSize(client.player.Location - Blue_FB.Location);
            dRed_f  = VSize(client.player.Location - Red_F.Position().Location);
            dBlue_f = VSize(client.player.Location - Blue_F.Position().Location);

            if(client.team == 0) {
              if (dRed_f < 2048 && Red_F.Holder != None && (Blue_f.Holder == None || dRed_f < dBlue_f))       zone = 0;
              else if (dBlue_f < 2048 && Blue_F.Holder != None && (Red_f.Holder == None || dRed_f > dBlue_f)) zone = 1;
              else if (dBlue_b < 2048)                                                                        zone = 2;
              else if (dRed_b < 2048)                                                                         zone = 3;
              else                                                                                            zone = 4;
            } else if(client.team == 1) {
              if (dBlue_f < 2048 && Blue_f.Holder != None && (Red_f.Holder == None || dRed_f >= dBlue_f))     zone = 0;
              else if (dRed_f < 2048 && Red_f.Holder != None && (Blue_f.Holder == None || dRed_f < dBlue_f))  zone = 1;
              else if (dRed_b < 2048)                                                                         zone = 2;
              else if (dBlue_b < 2048)                                                                        zone = 3;
              else                                                                                            zone = 4;
            }

            if((Blue_f.Holder == client.player) || (Red_f.Holder == client.player)) zone = 5;

            switch(zone) {
              case 0:	OutMsg = OutMsg$"Attacking Enemy Flag Carrier";
                break;
              case 1: OutMsg = OutMsg$"Supporting Our Flag Carrier";
                break;
              case 2: OutMsg = OutMsg$"Attacking";
                break;
              case 3: OutMsg = OutMsg$"Defending";
                break;
              case 4: OutMsg = OutMsg$"Floating";
                break;
              case 5: OutMsg = OutMsg$"Carrying Flag";
                break;        
            }     
          } else if (cmd == "%%") OutMsg = OutMsg$"%";
          else OutMsg = OutMsg$cmd;
          
          Pos = InStr(s,"%");

          if (Pos == -1) break;
        }  
        if (Len(s) > 0) OutMsg = OutMsg$s;
        
        if(containsParameter(OutMsg, client)) return true; // Security check to prevent runaway loops
        
        client.player.consoleCommand("TeamSay "$OutMsg);
      }
      return false;
    }
	}
  return true;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called to check if the given localized message should be send to the specified
 *                receiver.
 *  $PARAM        sender          The actor that has send the message.
 *  $PARAM        receiver        Pawn receiving the message.
 *  $PARAM        message         The class of the localized message that is to be send.
 *  $PARAM        switch          Optional message switch argument.
 *  $PARAM        relatedPRI_1    PlayerReplicationInfo of a player that is related to the message.
 *  $PARAM        relatedPRI_2    PlayerReplicationInfo of a player that is related to the message.
 *  $PARAM        optionalObject  Optional object used to construct the message string.
 *  $REQUIRE      message != none
 *  $RETURN       True if the message should be send, false if it should be suppressed.
 *
 **************************************************************************************************/
function bool mutatorBroadcastLocalizedMessage(Actor sender, Pawn receiver,
                                               out class<LocalMessage> message,
                                               out optional int switch,
                                               out optional PlayerReplicationInfo relatedPRI_1,
                                               out optional PlayerReplicationInfo relatedPRI_2,
                                               out optional Object optionalObject) {
	local CTFFlag Flagger;

	if(Message == class'Botpack.CTFMessage') {
		switch(switch) {
			case 0: // Capped CTFFlag(OptionalObject) by RelatedPRI_1
        flagCarrier [CTFFlag(OptionalObject).Team] = "";
			break;

			case 1: // Returned CTFFlag(OptionalObject) by RelatedPRI_1
        flagDropTime[CTFFlag(OptionalObject).Team] = -999;
        playCTFSoundOnClients(CTFSoundReturn[CTFFlag(OptionalObject).Team]);
			break;
		
			case 2: // Dropped by RelatedPRI_1, TeamInfo(OptionalObject)
        flagDropTime[TeamInfo(OptionalObject).TeamIndex] = Level.TimeSeconds;
			  flagCarrier [TeamInfo(OptionalObject).TeamIndex] = "";
        playCTFSoundOnClients(CTFSoundDrop[TeamInfo(OptionalObject).TeamIndex]);
			break;

			case 3: // Was returned (e.g. lava?), TeamInfo(OptionalObject)
        flagDropTime[TeamInfo(OptionalObject).TeamIndex] = -999;
        playCTFSoundOnClients(CTFSoundReturn[TeamInfo(OptionalObject).TeamIndex]);
			break;

			case 4: // Flag was dropped and picked up by RelatedPRI_1, TeamInfo(OptionalObject)
				flagDropTime[TeamInfo(OptionalObject).TeamIndex] = -999;
        flagCarrier [TeamInfo(OptionalObject).TeamIndex] = RelatedPRI_1.playerName;
        playCTFSoundOnClients(CTFSoundTaken[TeamInfo(OptionalObject).TeamIndex], relatedPRI_1, CTFSoundTakenYou);
			break;

			case 5: // Auto return (after 25 secs?), TeamInfo(OptionalObject)
				flagDropTime[TeamInfo(OptionalObject).TeamIndex] = -999;
        playCTFSoundOnClients(CTFSoundReturn[TeamInfo(OptionalObject).TeamIndex]);
			break;

			case 6: // Flag was home and picked up by RelatedPRI_1, TeamInfo(OptionalObject)
        flagCarrier [TeamInfo(OptionalObject).TeamIndex] = RelatedPRI_1.playerName;
        playCTFSoundOnClients(CTFSoundTaken[TeamInfo(OptionalObject).TeamIndex], relatedPRI_1, CTFSoundTakenYou);
			break;
		}

	}
  
  return true;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a pawn takes damage.
 *  $PARAM        actualDamage  The amount of damage sustained by the pawn.
 *  $PARAM        victim        Pawn that has become victim of the damage.
 *  $PARAM        instigatedBy  The pawn that has instigated the damage to the victim.
 *  $PARAM        hitLocation   Location where the damage was dealt.
 *  $PARAM        momentum      Momentum of the damage that has been dealt.
 *  $PARAM        damageType    Type of damage dealt to the victim.
 *  $REQUIRE      victim != none
 *
 **************************************************************************************************/
function mutatorTakeDamage(out int actualDamage, Pawn victim, Pawn instigatedBy,
                           out vector hitLocation, out vector momentum, name damageType) {
	local URSGrappleClient xClient;
  local TeamGamePlus TGP;
	local bool bTeam;
  local byte bPreventDamage;
  
  if(victim == None) return;
  
  xClient = getXClient(victim);
 
	// Check if damage should be prevented.
	if(xClient != none && xClient.client != none && damageType != control.suicideDamageType) {
		checkSpawnProtection(xClient, instigatedBy, damageType, actualDamage, bPreventDamage); 
    
    if (bool(bPreventDamage)) actualDamage = 0;
  }
  
  // Play Hitsound.
  if(instigatedBy == None) return;
  
  xClient = getXClient(instigatedBy);
  
  TGP = TeamGamePlus(Level.Game);
	bTeam = TGP != None && TGP.bTeamGame && victim.PlayerReplicationInfo != None && instigatedBy.PlayerReplicationInfo != None &&
          victim.PlayerReplicationInfo.Team == instigatedBy.PlayerReplicationInfo.Team && TGP.FriendlyFireScale == 0.0;
  
  if(victim != instigatedBy && xClient != None && !bTeam) {
    xClient.playHitSound();
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the server wants to check if a players death should be prevented.
 *  $PARAM        victim       The pawn that was killed.
 *  $PARAM        killer       The pawn that has killed the victim.
 *  $PARAM        damageType   Type of damage dealt to the victim.
 *  $PARAM        hitLocation  Location where the damage was dealt.
 *  $RETURN       True if the players death should be prevented, false if not.
 *
 **************************************************************************************************/
function bool preventDeath(Pawn victim, Pawn killer, name damageType, vector hitLocation) {
  local URSGrappleClient xClient;
  local byte bPreventDamage;
  
  if(victim == None) return false;
  
  xClient = getXClient(victim);
	
	// Check if damage should be prevented.
	if (xClient != none && xClient.client != None && damageType != control.suicideDamageType) {
		checkSpawnProtection(xClient, killer, damageType, 99999, bPreventDamage);
    
    // Prevent the damage.
		if (bool(bPreventDamage)) {
			xClient.client.player.health = 100; 
      return true;
    }
  }
  
  return false;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Handles a potential command message.
 *  $PARAM        sender  PlayerPawn that has send the message in question.
 *  $PARAM        msg     Message send by the player, which could be a command.
 *  $REQUIRE      sender != none
 *  $RETURN       True if the specified message is a command, false if not.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool handleMsgCommand(PlayerPawn sender, string msg) {
	local string cmd;
	local bool bIsCommand;
	local URSGrappleClient xClient;

	cmd = class'NexgenUtil'.static.trim(msg);
	bIsCommand = true;
	switch (cmd) {
		case "!grapple":
			xClient = getXClient(sender);
			if (xClient != none) {
        if(xClient.client.bInitialized) {
          xClient.showGrapple();
          return true;
        } else xClient.client.showMsg("<C00>Command requires initialisation...");
      }
		break;
    case "!LC":
    case "!lc":
    case "!ZP":
    case "!zp":
    	xClient = getXClient(sender);
			if (xClient != none) {
        if(xClient.client.bInitialized) {
          xClient.showLCPanel();
          return true;
        } else xClient.client.showMsg("<C00>Command requires initialisation...");
      }
    break;

		// Not a command.
		default: bIsCommand = false;
	}

	return bIsCommand;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Hooked into the mutator chain to detect Nexgen actions issued by the clients. If
 *                a Nexgen command is detected it will be parsed and send to the execCommand()
 *                function.
 *  $PARAM        mutateString  Mutator specific string (indicates the action to perform).
 *  $PARAM        sender        Player that has send the message.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function mutate(string mutateString, PlayerPawn sender) {
	local NexgenClient client;
  local URSGrappleClient xClient;
  
  client = control.getClient(sender); 
  if(client != None) xClient = URSGrappleClient(client.getController(class'URSGrappleClient'.default.ctrlID));
  if(xClient == None) return;

  if(mutateString ~= "zp_on" || mutateString ~= "zp_off" || Left(mutateString, 11) ~= "Prediction ") {
    // Get client handler for the sender.

    xClient.updateLCSettings();
  } else if (mutateString ~= "EnableHitSounds")	{
    Sender.ClientMessage("Enabling Hit Sounds for you!");
    xClient.enableHitSounds(true);
	} else if (mutateString ~= "DisableHitSounds") {
    Sender.ClientMessage("Disabling HitSounds for you!");
    xClient.enableHitSounds(false);
	}	else if (mutateString ~= "specialLog") {
    xClient.specialLog();
	}
  
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a general event has occurred in the system.
 *  $PARAM        type      The type of event that has occurred.
 *  $PARAM        argument  Optional arguments providing details about the event.
 *
 **************************************************************************************************/
function notifyEvent(string type, optional string arguments) {
  local NexgenClient client;
  local URSGrappleClient xClient;
  local ChallengeHud Huds;

  // ACE info available?
  if(type == "ace_login") {
    client = control.getClientByNum(int(class'NexgenUtil'.static.getProperty(arguments, "client")));
    xClient = URSGrappleClient(client.getController(class'URSGrappleClient'.default.ctrlID));
    if(xClient != none) xClient.ACELogin();
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Plays the corresponding CTF Sound on all clients
 *
 **************************************************************************************************/
function playCTFSoundOnClients(Sound soundForAll, optional PlayerReplicationInfo special, optional Sound specialSound) {
  local NexgenClient c;
  local URSGrappleClient xClient;
  
  for(c=control.clientList;c!=none;c=c.nextClient) {
    xClient = URSGrappleClient(c.getController(class'URSGrappleClient'.default.ctrlID));

    if(xClient != none) {
      if(special != none && c.playerName == special.PlayerName && specialSound != none) xClient.playCTFSound(specialSound);
      else if(soundForAll != none)                                                      xClient.playCTFSound(soundForAll);
    }
  }
} 

/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks whether the specified damage to the client should be prevented.
 *  $PARAM        client          The client for which the damage prevention check should be executed.
 *  $PARAM        instigator      The pawn that has instigated the damage to the victim.
 *  $PARAM        damageType      Type of damage the player has sustained.
 *  $PARAM        damage          The amount of damage sustained by the client.
 *  $PARAM        bPreventDamage  Whether the damage should be prevented or not.
 *  $REQUIRE      client != none
 *
 **************************************************************************************************/
function checkSpawnProtection(URSGrappleClient xClient, Pawn instigator, name damageType, int damage,
                              out byte bPreventDamage) {
                            
	// Check if player has switched to another team.
	if (xClient.client.team != xClient.client.player.playerReplicationInfo.team) {
		// Yes, don't prevent the damage.
		bPreventDamage = byte(false);
		return;
	}
	
	// Spawn protection.
	if (xClient.spawnProtectionTimeX > 0) {
    if(PlayerPawn(instigator) != None && PlayerPawn(instigator).playerReplicationInfo != None && PlayerPawn(instigator).playerReplicationInfo.hasFlag == none) {
      bPreventDamage = byte(true);
    }
	}	
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a player (re)spawns and allows us to modify the player.
 *  $PARAM        client  The client of the player that was respawned.
 *  $REQUIRE      client != none
 *
 **************************************************************************************************/
function playerRespawned(NexgenClient client) {
	local URSGrappleClient xClient;
  
  xClient = URSGrappleClient(client.getController(class'URSGrappleClient'.default.ctrlID));
  
  if(xClient != None) xClient.respawned();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Broadcasts a multi kill to all players.
 *
 **************************************************************************************************/
function broadcastMultiKill(int type, string playerName) {
  local string msg;
  
  if(type < 1) return;

  if (type == 10) {
		msg = class'NexgenUtil'.static.format(cheaterMessage, playerName);
  } else if (type > arrayCount(multiKillMessage)) {
    msg = class'NexgenUtil'.static.format(multiKillMessage[arrayCount(multiKillMessage) - 1], playerName);
  } else {
    msg = class'NexgenUtil'.static.format(multiKillMessage[type - 1], playerName);
  }
  
  if(msg != "") control.broadcastMsg(msg);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Broadcasts an insane combo to all players.
 *
 **************************************************************************************************/
function broadcastInsaneCombo(int type, string playerName) {
  local string msg;
  
  if (type == 0) {
    msg = class'NexgenUtil'.static.format(insaneComboMessage, playerName);
  } else if(type >= 5  && type < 10) {
    msg = class'NexgenUtil'.static.format(insaneComboMessageWicked[0], playerName);
  } else if(type >= 10 && type < 15) {
    msg = class'NexgenUtil'.static.format(insaneComboMessageWicked[1], playerName);
  } else if(type >= 15 && type < 20) {
    msg = class'NexgenUtil'.static.format(insaneComboMessageWicked[2], playerName);
  } else if(type >= 20 && type < 25) {
    msg = class'NexgenUtil'.static.format(insaneComboMessageWicked[3], playerName);
  } else if(type >= 20 && type < 30) {
    msg = class'NexgenUtil'.static.format(insaneComboMessageWicked[4], playerName);
  }
  
  if(msg != "") control.broadcastMsg(msg);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     pluginName="UrS Grapple Extension"
     pluginAuthor="Sp0ngeb0b"
     pluginVersion="5"
     MultiKillMessage(0)="<C03>%1 had a Double Kill."
     MultiKillMessage(1)="<C02>%1 had a Multi Kill!"
     MultiKillMessage(2)="<C06>%1 had an ULTRA KILL!!"
     MultiKillMessage(3)="<C10>%1 had a  M O N S T E R  KILL!!!"
     MultiKillMessage(4)="<C10>%1 had another  M O N S T E R  KILL!!!"
     cheaterMessage="<C10>%1 should get a life! :D"
     insaneComboMessage="<C06>%1 had an insane combo!"
     insaneComboMessageWicked(0)="<C06>%1 had another insane combo - WICKED SICK!"
     insaneComboMessageWicked(1)="<C06>%1 had another insane combo - IMPRESSIVE!"
     insaneComboMessageWicked(2)="<C06>%1 had another insane combo - EXCELLENT!"
     insaneComboMessageWicked(3)="<C06>%1 had another insane combo - OUTSTANDING!"
     insaneComboMessageWicked(4)="<C06>%1 had another insane combo - UNREAL!"
}
