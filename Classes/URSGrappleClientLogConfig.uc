class URSGrappleClientLogConfig extends NexgenPanel;

var URSGrappleClient xClient;                            // Client controller interface.

var UWindowCheckbox enableAutoICLogInp;
var UMenuRaisedButton bindButton;                        // Keybind button.

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
	local NexgenContentPanel p;
  local int region;
  
	// Retrieve client controller interface.
	xClient = URSGrappleClient(client.getController(class'URSGrappleClient'.default.ctrlID));
	
	// Create layout & add components.
  setAcceptsFocus();
	createPanelRootRegion();
	splitRegionH(12);
	addLabel("Special Event Client Logger", true, TA_Center);
	splitRegionH(1, defaultComponentDist);
	addComponent(class'NexgenDummyComponent');
	
  splitRegionH(16, defaultComponentDist);
  addLabel("You can output the current game timestamp (remaining and elapsed time) to a special log file in order to find it", false, TA_Left);
  splitRegionH(16, defaultComponentDist);
  addLabel("again in demoplayback. This can be done automatically for insane combo kills or manually using a keybind.", false, TA_Left);
  splitRegionH(8, defaultComponentDist);
  skipRegion();

  splitRegionH(48, defaultComponentDist);
  divideRegionV(2, defaultComponentDist);
  skipRegion();
  
  splitRegionV(16, defaultComponentDist, , true);
  
  // For whatever reasons, keyDown wont be called if the keybind is in the same content panel as the checkbox ...
  p = addContentPanel();
  p.divideRegionH(2, defaultComponentDist);
  p.addLabel("Special Event log keybind", true, TA_Center);
  p.divideRegionV(3);
  p.skipRegion();
  bindButton = p.addRaisedButton();
  p.skipRegion();

 	addLabel("Auto log insane combo kills", true, TA_Left);
  enableAutoICLogInp = addCheckBox(TA_Left);

	// Configure components.
	enableAutoICLogInp.register(self);
  bindButton.align = TA_Center;
	bindButton.bAcceptsFocus = false;
	bindButton.bIgnoreLDoubleClick = true;
	bindButton.bIgnoreMDoubleClick = false;
	bindButton.bIgnoreRDoubleClick = true;
	bindButton.register(self);

  setValues();
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
 *  $DESCRIPTION  Notifies the dialog of an event (caused by user interaction with the interface).
 *  $PARAM        control    The control object where the event was triggered.
 *  $PARAM        eventType  Identifier for the type of event that has occurred.
 *  $REQUIRE      control != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function notify(UWindowDialogControl control, byte eventType) {
	super.notify(control, eventType);
  
  // Keybind button clicked?
  if (eventType == DE_Click) {
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
    
    if (control == enableAutoICLogInp) {
      // Save setting.
      xClient.client.gc.set(xClient.SSTR_bAutoLogSpecialEvent, string(enableAutoICLogInp.bChecked));
      xClient.client.gc.saveConfig();
    }
  }
}

function setValues() {
	enableAutoICLogInp.bChecked = xClient.client.gc.get(xClient.SSTR_bAutoLogSpecialEvent, "false")  ~= "true";
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     bindCommand="mutate specialLog"
     panelIdentifier="ursgrappleextensionclientlogconfig"
     PanelHeight=124.000000
}

