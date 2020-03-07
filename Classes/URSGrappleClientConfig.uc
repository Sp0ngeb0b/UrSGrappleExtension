class URSGrappleClientConfig extends NexgenContentPanel;

var URSGrappleClient xClient;                            // Client controller interface.

var UWindowCheckbox enableCTFSoundsInp;
var UWindowCheckbox enableBeaconHUDInp;
var UWindowCheckbox enableHitSoundsInp;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {
	
	// Add components.
	splitRegionH(12);
	addLabel("Additional UrS settings", true, TA_Center);
	divideRegionH(3);
	enableCTFSoundsInp = addCheckBox(TA_Left, "Enable CTF announcer");
	enableBeaconHUDInp = addCheckBox(TA_Left, "Display playername HUD");
  enableHitSoundsInp = addCheckBox(TA_Left, "Enable hitsounds");

	// Configure components.
	enableCTFSoundsInp.register(self);
	enableBeaconHUDInp.register(self);
  enableHitSoundsInp.register(self);
  setValues();
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
  
  if (control == enableCTFSoundsInp && eventType == DE_Click) {
		// Save setting.
		xClient.client.gc.set(xClient.SSTR_bCTFAnnouncer, string(enableCTFSoundsInp.bChecked));
		xClient.client.gc.saveConfig();
	}
  
  if (control == enableBeaconHUDInp && eventType == DE_Click) {
		// Save setting.
		xClient.client.gc.set(xClient.SSTR_bPlayernameHUD, string(enableBeaconHUDInp.bChecked));
		xClient.client.gc.saveConfig();
    
    if(xClient.xHUD != none) xClient.xHUD.bRenderPlayernameHUD = enableBeaconHUDInp.bChecked; 
	}
  
  if (control == enableHitSoundsInp && eventType == DE_Click) {
		// Save setting.
		xClient.client.gc.set(xClient.SSTR_bHitSounds, string(enableHitSoundsInp.bChecked));
		xClient.client.gc.saveConfig();
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Sets the values of the input components.
 *
 **************************************************************************************************/
function setValues() {
	enableCTFSoundsInp.bChecked = xClient.client.gc.get(xClient.SSTR_bCTFAnnouncer, "true")  ~= "true";
	enableBeaconHUDInp.bChecked = xClient.client.gc.get(xClient.SSTR_bPlayernameHUD, "true") ~= "true";
  enableHitSoundsInp.bChecked = xClient.client.gc.get(xClient.SSTR_bHitSounds, "false")    ~= "true";
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
}
