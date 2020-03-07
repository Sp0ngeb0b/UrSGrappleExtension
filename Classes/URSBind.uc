class URSBind extends NexgenPanel;

#exec TEXTURE IMPORT NAME=FB1    FILE=Resources\FacebookIcon1.pcx  GROUP="GFX" FLAGS=2 MIPS=OFF
#exec TEXTURE IMPORT NAME=FB2    FILE=Resources\FacebookIcon2.pcx  GROUP="GFX" FLAGS=2 MIPS=OFF
#exec TEXTURE IMPORT NAME=FB3    FILE=Resources\FacebookIcon3.pcx  GROUP="GFX" FLAGS=2 MIPS=OFF
#exec TEXTURE IMPORT NAME=UrS1   FILE=Resources\UrSIcon1.pcx       GROUP="GFX" FLAGS=2 MIPS=OFF
#exec TEXTURE IMPORT NAME=UrS2   FILE=Resources\UrSIcon2.pcx       GROUP="GFX" FLAGS=2 MIPS=OFF
#exec TEXTURE IMPORT NAME=UrS3   FILE=Resources\UrSIcon3.pcx       GROUP="GFX" FLAGS=2 MIPS=OFF

var URSGrappleClient xclient;

var UMenuRaisedButton bindButton;       // Keybind button.
var UWindowSmallButton InfoButton;
var UWindowSmallButton FBButton;
var UWindowSmallButton UrSButton;

var string bindCommand;                 // Console commands for the key bind.
var int selectedBind;                   // Currently selected key.
var bool bPolling;                      // Waiting for a new key assignment.

const bindSeparator = "|";              // Token used to seperate commands in an action string.
const getKeyNameCommand = "keyname";    // Console command to retrieve a key name.
const getKeyBindCommand = "keybinding"; // Console command to retrieve the action bound to a key.
const setKeyBindCommand = "set input";  // Console command to change a key binding.

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {

	xClient = URSGrappleClient(client.getController(class'URSGrappleClient'.default.ctrlID));

	// Create layout & add components.
	setAcceptsFocus();
	createPanelRootRegion();

  splitRegionH(16);
	addLabel("Settings", true, TA_Center);
	splitRegionH(18);
 	addLabel("Bind the GrapplingHook to a key:", false, TA_Center);
	splitRegionH(18);
  divideRegionV(2);
  
 	splitRegionH(10);
  
  bindButton = addRaisedButton();
  InfoButton = addButton("Info", 64);
  
 	skipRegion();
 	divideRegionV(2);

 	FBButton  = UWindowSmallButton(addComponent(class'UWindowSmallButton', 56, 56,  AL_Center,  AL_Center));
 	UrSButton = UWindowSmallButton(addComponent(class'UWindowSmallButton', 56, 56,  AL_Center,  AL_Center));

  InfoButton.register(self);

  FBButton.UpTexture=Texture'FB1';
  FBButton.OverTexture=Texture'FB2';
  FBButton.DownTexture=Texture'FB3';
  FBButton.bStretched = True;
  FBButton.WinWidth = 56;
  FBButton.WinHeight = 56;
	FBButton.register(self);
	
	UrSButton.UpTexture=Texture'UrS1';
  UrSButton.OverTexture=Texture'UrS2';
  UrSButton.DownTexture=Texture'UrS3';
	UrSButton.bStretched = True;
  UrSButton.WinWidth = 56;
  UrSButton.WinHeight = 56;
	UrSButton.register(self);

	bindButton.align = TA_Center;
	bindButton.bAcceptsFocus = false;
	bindButton.bIgnoreLDoubleClick = true;
	bindButton.bIgnoreMDoubleClick = false;
	bindButton.bIgnoreRDoubleClick = true;
	bindButton.register(self);
	
	loadKeyBinds();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Loads the keybind settings and displays them on the config panel.
 *
 **************************************************************************************************/
function loadKeyBinds() {
	local int keyNum;
	local string keyName;
	local string keyAction;
	local int index;

	// Iterate over all keys.
	for (keyNum = 0; keyNum < 255; keyNum++) {
		keyName = client.player.consoleCommand(getKeyNameCommand @ keyNum);
		if (keyName != "") {
			// Get action assigned to key.
			keyAction = client.player.consoleCommand(getKeyBindCommand @ keyName);

			// Check action string with the keybind commands.
			if (containsCommand(keyAction, bindCommand)) {
			  bindButton.text = keyName;
			}
		}
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Checks whether a keybind action contains one of the specified commands. Commands
 *                are separated by the 'separator' token (comma).
 *  $PARAM        action    Keybind action string.
 *  $PARAM        commands  List of commands to check for.
 *  $REQUIRE      commands != ""
 *  $RETURN       True if the action string contains one of the specified commands.
 *
 **************************************************************************************************/
function bool containsCommand(string action, string commands) {
	local string cmd;
	local string remaining;
	local int index;
	local bool bFound;

	action = caps(action);

	// For each command in the command string (separated by commas).
	remaining = caps(commands);
	while (remaining != "" && !bFound) {

		// Get next command.
		index = instr(remaining, separator);
		if (index < 0) {
			cmd = remaining;
			remaining = "";
		} else {
			cmd = left(remaining, index);
			remaining = mid(remaining, index + len(separator));
		}

		// Compare command.
		bFound = instr(action, cmd) >= 0;
	}

	return bFound;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Notifies the dialog of an event (caused by user interaction with the interface).
 *  $PARAM        control    The control object where the event was triggered.
 *  $PARAM        eventType  Identifier for the type of event that has occurred.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function notify(UWindowDialogControl control, byte eventType) {

	super.notify(control, eventType);

	if (eventType == DE_Click) {

		// Keybind button clicked?
		if (control != none && control.isA('UMenuRaisedButton')) {
			if (bPolling) {
				// Clicked on same button, cancel polling.
				bindButton.bDisabled = false;
				bPolling = false;

			} else {
				// No key bind button selected yet.
				bindButton.bDisabled = true;
				bPolling = true;
			}

		} else if (bPolling) {
  		// Clicked elsewhere, but still polling, cancel action.
		  bindButton.bDisabled = false;
	  	bPolling = false;
		}
    
    // Info button clicked?
		if (control != none && control == InfoButton) {
      client.showPopup(string(class'URSInfo'));
    }
		
		// Facebook button clicked?
		if (control != none && control == FBButton) {
      client.player.consoleCommand("start http://www.facebook.com/UnrealRiderS");
    }
    
    // Homepage button clicked?
		if (control != none && control == UrSButton) {
      client.player.consoleCommand("start http://www.unrealriders.eu");
    }
	}

}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Notifies the dialog of a key press event.
 *  $PARAM        key  The number of the key that was pressed.
 *  $PARAM        x    Unknown, x location of mouse cursor?
 *  $PARAM        y    Unknown, x location of mouse cursor?
 *  $OVERRIDE
 *
 **************************************************************************************************/
function keyDown(int key, float x, float y) {
	local string keyName;

  keyName = client.player.consoleCommand(getKeyNameCommand @ key);

	// Assign new key binding?
	if (bPolling && keyName != "") {

		// Remove old binding.
		removeKeybind(bindButton.text, bindCommand);

		// Add new binding.
		addKeybind(keyName, bindCommand);

		// Update buttons.
		bindButton.bDisabled = false;
		bindButton.text = keyName;
		bPolling = false;
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Removes the specified commands from the action bound to the given key.
 *  $PARAM        keyName   Name of the key for which the bindings should be updated.
 *  $PARAM        commands  List of commands to remove from the action string.
 *  $REQUIRE      keyName != ""
 *
 **************************************************************************************************/
function removeKeybind(String keyName, string commands) {
	local string actionStr;
	local string remaining;
	local string cmd;
	local int index;

	// Get action string.
	actionStr = client.player.consoleCommand(getKeyBindCommand @ keyName);

	// Update action string.
	remaining = caps(commands);
	while (remaining != "") {

		// Get next command.
		index = instr(remaining, separator);
		if (index < 0) {
			cmd = remaining;
			remaining = "";
		} else {
			cmd = left(remaining, index);
			remaining = mid(remaining, index + len(separator));
		}

		// Remove command from action string.
		index = instr(caps(actionStr), cmd);
		if (index >= 0) {
			actionStr = left(actionStr, index) $ mid(actionStr, index + len(cmd));
			if (mid(actionStr, index, len(bindSeparator)) == bindSeparator) {
				// Remove | token after command.
				actionStr = left(actionStr, index) $ mid(actionStr, index + len(bindSeparator));
			}
		}

	}

	// Store action string.
	client.player.consoleCommand(setKeyBindCommand @ keyName @ actionStr);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Adds the specified command from to the action bound to the given key.
 *  $PARAM        keyName   Name of the key for which the bindings should be updated.
 *  $PARAM        command   Commands to add to the action string.
 *  $REQUIRE      keyName != ""
 *
 **************************************************************************************************/
function addKeybind(String keyName, string command) {
	local string actionStr;
	local string cmd;

	// Get action string.
	actionStr = client.player.consoleCommand(getKeyBindCommand @ keyName);

	// Update action string.
	if (instr(command, separator) >= 0) {
		cmd = left(command, instr(command, separator));
	} else {
		cmd = command;
	}

	if (class'NexgenUtil'.static.trim(actionStr) == "") {
		// No action bound yet.
		actionStr = cmd;
	} else {
		// Some actions already bound.
		actionStr = actionStr $ bindSeparator $ cmd;
	}

	// Store action string.
	client.player.consoleCommand(setKeyBindCommand @ keyName @ actionStr);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     bindCommand="HOOKOFFHANDFIRE"
}
