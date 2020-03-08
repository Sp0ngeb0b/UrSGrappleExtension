class URSGrappleClient extends NexgenClientController;

// Serverside
var URSGrappleExtension xControl;

// Bothsided
var int    countDown[2];
var string flagCarrier[2];

// Clientside
var float lastKillTime;       // Last time this player killed another player.
var int multiLevel;           // Number of kills on a short time.
var URSGrappleConfig conf;    // Plugin configuration.

var URSChatLog ChatLog;

var ChallengeHUD HUD, HUDWrapper;

var bool bStatsRestored;
var URSGrappleHud xHUD;

var bool playerWelcomed;
var bool bRunningLC;

var URSGrappleClientConfig ursSettingsPanel;

var int LCtries;
var XC_CompensatorChannel LCChan;
var NexgenPanel LCConfigPanel;
var bool bUpdateLCSettings;

// Special log / Insame combo detection
var bool bStatsJustRestored;
var int insaneComboAmount;
var SmartCTFPlayerReplicationInfo SCTFPRI;
var NexgenTextFile specialLogFile;                

// Spawn Protection
var float spawnProtectionTimeX;                   // Spawn protection time remaining (server only).
var NXPClient NPClient;
var bool bPlayerOverlayResetted;
 
// Client side settings.
const SSTR_bFirstTime           = "AlreadyVisitedUrS";   // Whether the client has already visited the server
const SSTR_bCTFAnnouncer        = "enableCTFAnnouncer";
const SSTR_bPlayernameHUD       = "enablePlayernameHUD";
const SSTR_bHitSounds           = "enableHitSounds";
const SSTR_bAutoLogSpecialEvent = "autoLogSpecialEvent";

// Constants
const delayTime = 4.0;                // Delay before the welcome message

/***************************************************************************************************
 *
 *  $DESCRIPTION  Replication block.
 *
 **************************************************************************************************/
replication {

	reliable if (role == ROLE_Authority) // Replicate to client...
		// Variables.
		conf,bStatsRestored,bRunningLC,countDown,flagCarrier,playCTFSound,playHitSound,enableHitSounds,
		
		// Functions
		updateLCSettings,ACELogin,showLCPanel,showGrapple,specialLog,insaneComboAutoLog;
		
  reliable if (role != ROLE_Authority) // Replicate to server...
		setGeneralSettings;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Initializes the client controller. This function is automatically called after
 *                the critical variables have been set, such as the client variable.
 *  $PARAM        creator  The Actor that has added the controller to the client.
 *
 **************************************************************************************************/
function initialize(optional Actor creator) {
  
	xControl = URSGrappleExtension(creator);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Serverside tick.
 *  $OVERRIDE
 *
 **************************************************************************************************/
 function tick(float deltaTime) {
  local byte desiredState;
 
	countDown[0]    = xControl.countDown[0];
  countDown[1]    = xControl.countDown[1];
  flagCarrier[0]  = xControl.flagCarrier[0];
  flagCarrier[1]  = xControl.flagCarrier[1];
  
  // Spawn protection.
  if (spawnProtectionTimeX > 0) {
    // Disable spawn protection?
    if ((client.control.timeSeconds - client.lastRespawnTime >= client.cancelSpawnProtectDelay) &&
        (client.player.playerReplicationInfo.hasFlag != none || !client.ignoreWeaponFire()) ||
        (client.player.health <= 0) || (client.gInf.gameState == client.gInf.GS_Ended)) {
      // Yes.
      spawnProtectionTimeX = 0;
      client.spawnProtectionTime = 0;  
    } else {
      // No, update timer.
      spawnProtectionTimeX -= deltaTime / level.timeDilation;
      if (spawnProtectionTimeX <= 0) {
        client.spawnProtectionTime = 0;
      } else {
        client.spawnProtectionTime = byte(spawnProtectionTimeX) + 1;
      }
    }
  }
  
  // Support for NexgenPlus spawn protection overlay
  if(NPClient != None && NPClient.playerOverlay != None) {
    if(!bPlayerOverlayResetted && spawnProtectionTimeX > 0) {
      NPClient.playerOverlay.disable('tick');
      NPClient.playerOverlay.mesh = owner.mesh;
      NPClient.playerOverlay.drawScale = owner.drawscale;
      bPlayerOverlayResetted = true;
    }
    if(NXPConfig(NPClient.xControl.xConf).showDamageProtectionShield && spawnProtectionTimeX > 0) desiredState = NPClient.playerOverlay.STATE_SHIELD;
    else desiredState = NPClient.playerOverlay.STATE_HIDDEN;
        
    if(desiredState != NPClient.playerOverlay.currentState) NPClient.playerOverlay.setState(desiredState);
  } else bPlayerOverlayResetted = false;
  
  // Insane Combo Detection
  if(SCTFPRI != None && SCTFPRI.insaneCombos != insaneComboAmount) {
    if(!bStatsJustRestored) insaneCombo();
    else bStatsJustRestored = false;
    insaneComboAmount = SCTFPRI.insaneCombos;
  } 
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Initializes the client controller.
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated event postNetBeginPlay() {
	super.postNetBeginPlay();
  
  // Use new CountryFlags package
  class'NexgenUtil'.default.countryFlagsPkg = "CountryFlags3UrS";
  
  // Make space for our additional settings
  class'NexgenRCPClientConfig'.default.PanelHeight = 252;

	if (!bNetOwner) {
		destroy();
	} else if(Role != ROLE_Authority) {
		// Enable timer.
		setTimer(1.0, true);
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the NexgenClient has received its initial replication info is has
 *                been initialized. At this point it's safe to use all functions of the client.
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function clientInitialized() {
  local NexgenPanel settingsPanel;

  // Add control panel tabs.
	if (client.hasRight(client.R_ServerAdmin)) {
		client.addPluginConfigPanel(class'URSGrappleSettings');
  }
  
  // Add sexy scoreboard HUD
  client.addHUDExtension(spawn(class'URSScoreBoardHud', self));
  
  // Hack in our additional client settings
  settingsPanel = client.mainWindow.mainPanel.getPanel(class'NexgenRCPClientConfig'.default.panelIdentifier);
  ursSettingsPanel = URSGrappleClientConfig(settingsPanel.addComponent(class'URSGrappleClientConfig'));
	ursSettingsPanel.createPanelRootRegion();
	ursSettingsPanel.parentCP = settingsPanel;
  ursSettingsPanel.xClient = self;
  ursSettingsPanel.setContent();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a general event has occurred in the system.
 *  $PARAM        type      The type of event that has occurred.
 *  $PARAM        argument  Optional arguments providing details about the event.
 *
 **************************************************************************************************/
simulated function ACELogin() {
  local ChallengeHud Huds;
  
  foreach AllActors(class'ChallengeHUD', Huds) {
    if(InStr(Huds.Class, "NexgenHUDWrapper") == -1) {
      HUD = Huds;
    } else HUDWrapper = Huds;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called by NexgenHUD.addChatMsg()
 *
 **************************************************************************************************/
simulated function addChatMsg(int col1, string text1,
                          optional int col2, optional string text2,
                          optional int col3, optional string text3,
                          optional int col4, optional string text4,
                          optional int col5, optional string text5) {

   if(ChatLog != none) ChatLog.addChatMsg(text1@text2@text3@text4@text5);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Modifies the setup of the Nexgen remote control panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function setupControlPanel() {
	ChatLog = URSChatLog(client.mainWindow.mainPanel.addPanel("Chat Log", class'URSChatLog', , "client"));
  client.addPluginClientConfigPanel(class'URSGrappleClientLogConfig');
}
	
/***************************************************************************************************
 *
 *  $DESCRIPTION  Client side timer.
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function timer() {
  local int Seconds;
  local string keyName;
	local string keyBinding;
	local int i;
  local bool bOffhand;
  local bool bfirstTime;

  if(client == none || client.player == none) return;

  Seconds = client.Level.TimeSeconds;
  
  if(xHUD == None) {
    xHUD = spawn(class'URSGrappleHud', self);
    xHUD.bRenderPlayernameHUD = bool(client.gc.get(SSTR_bPlayernameHUD, "true"));
  }

  if (Seconds > delaytime) {
    if(!playerWelcomed) {
      playerWelcomed = true;
    
      // initialize keys
      for (i=0; i<255; i++)	{
        keyName = client.player.consoleCommand("Keyname"@i);
        if ((InStr( Caps(client.player.consoleCommand("Keybinding"@keyName)), "FIRE") != -1)
            && (InStr( Caps(client.player.consoleCommand("Keybinding"@keyName)), "HOOKFIRE")) == -1 && (InStr( Caps(client.player.consoleCommand("Keybinding"@keyName)), "HOOKOFFHANDFIRE")) == -1)
        {
          keyBinding = client.player.consoleCommand("Keybinding"@keyName);
          client.player.consoleCommand("SET INPUT"@keyName@"HookFire|"$keyBinding);
        }
        if ((InStr( Caps(client.player.consoleCommand("Keybinding"@keyName)), "JUMP") != -1)
            && (InStr( Caps(client.player.ConsoleCommand("Keybinding"@keyName)), "JUMPREL")) == -1)
        {
          keyBinding = client.player.consoleCommand("Keybinding"@keyName);
          client.player.consoleCommand("SET INPUT"@keyName@"JumpRel|"$keyBinding);
        }
        if ((InStr( Caps(client.player.consoleCommand("Keybinding"@keyName)), "TRANSLOCATOR") != -1)
            && (InStr( Caps(client.player.consoleCommand("Keybinding"@keyName)), "GRAPPLING")) == -1)
        {
          keyBinding = client.player.consoleCommand("Keybinding"@keyName);
          client.player.consoleCommand("SET INPUT"@keyName@"getweapon Grappling|"$keyBinding);
        }
        if (InStr( Caps(client.player.consoleCommand("Keybinding"@keyName)), "HOOKOFFHANDFIRE") != -1)
        {
          bOffhand = true;
        }
      }

      // First time check
      if (client.gc.get(SSTR_bFirstTime, "false") ~= "false") {
        bfirstTime = true;
        client.gc.set(SSTR_bFirstTime, "True");
        client.showPopup(string(class'URSInfo'));
      }

      if (!bfirstTime) {
        if(!bOffhand) {
          if (bStatsRestored && !client.bSpectator) client.showMsg("<C02>Your stats have been restored!");
          client.showMsg("<C04>**Welcome back**");
          client.showMsg("<C04>Say '!Grapple' to bind the GrapplingHook to a key.");
        } else {
          if (bStatsRestored && !client.bSpectator) client.showMsg("<C02>Your stats have been restored!");
          client.showMsg("<C04>**Welcome HOME**");
        }
      }
    }
    if(bRunningLC && LCChan == none && LCtries < 20) {
      if(client.bInitialized && client.gInf.gameState == client.gInf.GS_Playing) locateLC(); 
    } else setTimer(0.0, false);

  }
  
  if(bUpdateLCSettings) {
    bUpdateLCSettings = false;
    URSGrappleClientLCConfig(LCConfigPanel).setValues();
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Locates this client's Lag Compensator settings
 *
 **************************************************************************************************/
simulated function locateLC() {
    local XC_CompensatorChannel CC;
  
    LCtries++;
    
    // Locate 
    foreach AllActors(class'XC_CompensatorChannel', CC) {
      if(CC.LocalPlayer == client.player) { 
        LCChan = CC;
        client.showMsg("<C08>This server is running lag compensation. Say !lc to configure.");
        client.addPluginClientConfigPanel(class'URSGrappleClientLCConfig');
        LCConfigPanel = client.mainWindow.mainPanel.getPanel(class'URSGrappleClientLCConfig'.default.panelIdentifier);
        break;
      }
    }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Reload the Lag Compensator settings
 *
 **************************************************************************************************/
simulated function updateLCSettings() {
  if(LCChan != none) {
    bUpdateLCSettings = true;
    setTimer(0.1, false);
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Opens the Grapple window.
 *
 **************************************************************************************************/
simulated function showGrapple() {
	local URSRCPGrapple grappleTab;

	// Get grapple tab.
	grappleTab = URSRCPGrapple(client.mainWindow.mainPanel.getPanel(class'URSRCPGrapple'.default.panelIdentifier));
	if (grappleTab == none) {
	 grappleTab = URSRCPGrapple(client.mainWindow.mainPanel.addPanel("Info", class'URSRCPGrapple', , "server"));
	}

	// Show the grapple tab.
	client.showPanel(class'URSRCPGrapple'.default.panelIdentifier);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Opens the LC Settings Panel.
 *
 **************************************************************************************************/
simulated function showLCPanel() {
	if (LCConfigPanel != none) {
    client.showPanel(class'URSGrappleClientLCConfig'.default.panelIdentifier);
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Plays the corresponding CTF sound on the client if desired.
 *
 **************************************************************************************************/
simulated function playCTFSound(Sound ctfSound) {
  if(client.gc.get(SSTR_bCTFAnnouncer, "true")  ~= "true") client.player.clientPlaySound(ctfSound, , true);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Plays a Hitsound like in UTPure.
 *
 **************************************************************************************************/
simulated function playHitSound() {
	local actor SoundPlayer;
  
  if(client.gc.get(SSTR_bHitSounds, "false")  ~= "false") return;

	client.player.LastPlaySound = Level.TimeSeconds;	// so voice messages won't overlap
	if (client.player.ViewTarget != None) SoundPlayer = client.player.ViewTarget;
	else                                  SoundPlayer = client.player;

	SoundPlayer.PlaySound(Sound'UnrealShare.StingerFire', SLOT_None, 16.0, True);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Update settings.
 *
 **************************************************************************************************/
function setGeneralSettings(float newSpawnProtectionTime, string text, color textcolor) {

	// Check rights.
	if (!client.hasRight(client.R_ServerAdmin)) {
		return;
	}

	// Safe settings.
  conf.spawnProtectionTime = newSpawnProtectionTime;
	conf.InfoText = text;
	conf.textColor= textcolor;
	conf.saveConfig();

	// Log action.
  client.showMsg("<C07>Settings have been saved.");
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Enables or disables hitsounds client side.
 *
 **************************************************************************************************/
simulated function enableHitSounds(bool enable) {
  client.gc.set(SSTR_bHitSounds, string(enable));
  client.gc.saveConfig();
  if(ursSettingsPanel != None) ursSettingsPanel.setValues();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the client has respawned.
 *
 **************************************************************************************************/
function respawned() {
	
	// Actions that require the login to be completed.
	if (client.loginComplete) {
		if (!client.bSpectator) {
			spawnProtectionTimeX = conf.spawnProtectionTime;
		}
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Writes the current timestamp to a special client log file.
 *
 **************************************************************************************************/
simulated function specialLog(optional bool bAuto) {
  local string timeStamp, FileName, secondsElapsedStr, secondsRemainingStr, autoStr;
  local int minutesElapsed, secondsElapsed, minutesRemaining, secondsRemaining;

  // Construct FileName
  timeStamp = Class'NexgenUtil'.static.serializeDate(level.year, level.month, level.day, level.hour, level.minute);
  FileName = "./"$left(string(client), instr(string(client), "."))$"-"$level.year$"-"$level.month$"-"$level.day$"-"$level.hour$"-"$level.minute$"-"$level.second;

  // Create file actor
  if(specialLogFile == none) {
    specialLogFile = spawn(class'NexgenTextFile');

    if(!specialLogFile.openFile(FileName$".txt", FileName$".txt")) {
      return;
    }
  }

  // Write Data to file
  minutesElapsed   = client.player.gameReplicationInfo.ElapsedTime   / 60;
	secondsElapsed   = client.player.gameReplicationInfo.ElapsedTime   % 60;
  minutesRemaining = client.player.gameReplicationInfo.RemainingTime / 60;
	secondsRemaining = client.player.gameReplicationInfo.RemainingTime % 60;
  if(len(secondsElapsed) == 1)   secondsElapsedStr   = "0"$secondsElapsed;
  else                           secondsElapsedStr   = String(secondsElapsed);
  if(len(secondsRemaining) == 1) secondsRemainingStr = "0"$secondsRemaining;
  else                           secondsRemainingStr = String(secondsRemaining);
  
  if(bAuto) autoStr = "AUTO";
  else      autoStr = "MAN";
    
  specialLogFile.println(autoStr$Chr(9)$minutesElapsed$":"$secondsElapsedStr$Chr(9)$minutesRemaining$":"$secondsRemainingStr, true);
  specialLogFile.flushLog();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when this client had kill(s) from an insane combo.
 *
 **************************************************************************************************/
function insaneCombo() {
  if(insaneComboAmount%5 >= SCTFPRI.insaneCombos%5) level.game.broadcastLocalizedMessage(class'UrSGrappleMultiKillMessage', 999, client.player.playerReplicationInfo);
  else                                              level.game.broadcastLocalizedMessage(class'UrSGrappleMultiKillMessage', 998, client.player.playerReplicationInfo);
  
  insaneComboAutoLog();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Replicated function to auto log an insane combo kill.
 *
 **************************************************************************************************/
simulated function insaneComboAutoLog() {
  if(client.gc.get(SSTR_bAutoLogSpecialEvent, "false")  ~= "true") specialLog(true);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     ctrlID="URSGrappleClient"
}
