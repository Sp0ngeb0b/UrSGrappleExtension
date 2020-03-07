class URSGrappleClientLCConfig extends NexgenPanel;

var URSGrappleClient xClient;                            // Client controller interface.

var UWindowCheckbox enableLCInp;
var UWindowCheckbox enableFidelityInp;
var UWindowCheckbox forcePredictionCapInp;
var NexgenEditControl predictionCapInp;

var UWindowSmallButton resetButton;
var UWindowSmallButton saveButton;
var UWindowSmallButton statusButton;

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
	createPanelRootRegion();
	splitRegionH(12);
	addLabel("Lag Compensator Settings", true, TA_Center);
	splitRegionH(1, defaultComponentDist);
	addComponent(class'NexgenDummyComponent');
	
  splitRegionH(20, defaultComponentDist, , true);
	region = currRegion;
	skipRegion();
	splitRegionV(294, , , true);
  addLabel("Thanks to Higor", true, TA_Left);
	divideRegionV(3, defaultComponentDist);
	saveButton   = addButton(client.lng.saveTxt);
	resetButton  = addButton(client.lng.resetTxt);
  statusButton = addButton("Status");

	selectRegion(region);
  selectRegion(splitRegionV(192));
  region = currRegion;
	p = addContentPanel();
  p.divideRegionH(2);
  p.addLabel("Powered by", true, TA_Center);
  p.addLabel("LCWeapons", true, TA_Center);
  splitRegionV(16);
  skipRegion();
	splitRegionV(80, , true);
	divideRegionH(4);
	divideRegionH(4);
	addLabel("Enable lag compensation", true, TA_Left);
	addLabel("High fidelity mode", true, TA_Left);
  addLabel("Override server prediction cap", true, TA_Left);
  addLabel("New prediction cap", true, TA_Left);
	enableLCInp           = addCheckBox(TA_Right);
	enableFidelityInp     = addCheckBox(TA_Right);
  forcePredictionCapInp = addCheckBox(TA_Right);
  predictionCapInp      = addEditBox();
  
	// Configure components.
	enableLCInp.register(self);
  enableFidelityInp.register(self);
	forcePredictionCapInp.register(self);
  predictionCapInp.setNumericOnly(true);
	predictionCapInp.setMaxLength(3);

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
  
  // Button pressed?
	if (control != none && eventType == DE_Click && control.isA('UWindowSmallButton') &&
	    !UWindowSmallButton(control).bDisabled) {

		switch (control) {
			case resetButton:  setValues();    break;
			case saveButton:   saveSettings(); break;
      case statusButton: 
        xClient.client.player.consoleCommand("mutate zp_status");
        xClient.client.player.consoleCommand("mutate GetPrediction");
      break;
		}
	}
  
  if ((control == enableLCInp || (control == forcePredictionCapInp && !forcePredictionCapInp.bDisabled)) && eventType == DE_Click) {
    disEnable();
	}
}

function disEnable() {
  if(enableLCInp.bChecked) {
    enableFidelityInp.bDisabled     = false;
    forcePredictionCapInp.bDisabled = false;
    if(forcePredictionCapInp.bChecked) predictionCapInp.setDisabled(false);
    else                               predictionCapInp.setDisabled(true);
  } else {
    enableFidelityInp.bDisabled     = true;
    forcePredictionCapInp.bDisabled = true;
    predictionCapInp.setDisabled(true);
  }
}

function setValues() {
	enableLCInp.bChecked           = xClient.LCChan.ClientSettings.bUseLagCompensation;
  enableFidelityInp.bChecked     = xClient.LCChan.ClientSettings.bHighFidelityMode;
	forcePredictionCapInp.bChecked = xClient.LCChan.ClientSettings.ForcePredictionCap > -1;
  if(forcePredictionCapInp.bChecked) predictionCapInp.setValue(string(xClient.LCChan.ClientSettings.ForcePredictionCap));
  else                               predictionCapInp.setValue("");
  
  disEnable();
}

function saveSettings() {
   local int forcePredictionCap;
   
   xClient.LCChan.ClientChangeLC(enableLCInp.bChecked);
   xClient.LCChan.ClientChangeHiFi(enableFidelityInp.bChecked);
   
   if(!forcePredictionCapInp.bChecked) forcePredictionCap = -1;
   else forcePredictionCap = clamp(int(predictionCapInp.getValue()), 0, 999);
   if(forcePredictionCap != xClient.LCChan.ClientSettings.ForcePredictionCap) xClient.client.player.consoleCommand("mutate Prediction "$forcePredictionCap); 
   
   xClient.client.showMsg("<C07>Settings have been saved.");
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     panelIdentifier="ursgrappleextensionclientlcconfig"
     PanelHeight=128.000000
}
