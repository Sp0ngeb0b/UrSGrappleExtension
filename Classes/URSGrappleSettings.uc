class URSGrappleSettings extends NexgenPanel;

var URSGrappleClient xClient;

var UWindowSmallButton saveButton;
var UWindowSmallButton resetButton;

var UWindowEditControl textInp;
var UWindowEditControl colorRInp;
var UWindowEditControl colorGInp;
var UWindowEditControl colorBInp;

var UWindowEditControl spawnProtectTimeInp;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {
	local int region;
	local int index;

  xClient = URSGrappleClient(client.getController(class'URSGrappleClient'.default.ctrlID));

  // Create layout & add components.
	createPanelRootRegion();
	splitRegionH(12, defaultComponentDist);
	addLabel("UrS Grapple Extension", true, TA_Center);

	splitRegionH(1, defaultComponentDist);
	addComponent(class'NexgenDummyComponent');

	splitRegionH(20, defaultComponentDist, , true);
	region = currRegion;
	skipRegion();
	splitRegionV(196, , , true);
	skipRegion();
	divideRegionV(2, defaultComponentDist);
	saveButton = addButton(client.lng.saveTxt);
	resetButton = addButton(client.lng.resetTxt);

	selectRegion(region);
	selectRegion(divideRegionH(3, defaultComponentDist));

  divideRegionV(2, defaultComponentDist);
  divideRegionV(2, defaultComponentDist);
  divideRegionV(2, defaultComponentDist);
  
  addLabel("Spawn Protection Time", true, TA_Left);
  spawnProtectTimeInp = addEditBox();

  addLabel("Welcome Text", true, TA_Left);
  textInp = addEditBox();

  addLabel("Text Color", true, TA_Left);
  divideRegionV(6, defaultComponentDist);
  
  addLabel("R", true, TA_Right);
  colorRInp = addEditBox();
  
  addLabel("G", true, TA_Right);
  colorGInp = addEditBox();
  
  addLabel("B", true, TA_Right);
  colorBInp = addEditBox();
 
  // Config components.
  spawnProtectTimeInp.setMaxLength(3);
  spawnProtectTimeInp.setNumericOnly(true);
  spawnProtectTimeInp.setNumericFloat(true);
  colorRInp.setNumericOnly(true);
  colorGInp.setNumericOnly(true);
  colorBInp.setNumericOnly(true);

  setValues();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Sets the values of all input components to the current settings.
 *
 **************************************************************************************************/
function setValues() {
  spawnProtectTimeInp.setValue(Left(string(xClient.conf.spawnProtectionTime), InStr(string(xClient.conf.spawnProtectionTime), ".")+3));
  textInp.setValue(xClient.conf.InfoText);
  colorRInp.setValue(string(xClient.conf.textColor.R));
  colorGInp.setValue(string(xClient.conf.textColor.G));
  colorbInp.setValue(string(xClient.conf.textColor.B));
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Saves the current settings.
 *
 **************************************************************************************************/
function saveSettings() {
  local color newColor;
  
  
  if(int(colorRInp.getValue()) > 255) colorRInp.setValue("255");
  if(int(colorRInp.getValue()) < 1) colorRInp.setValue("0");
  
  if(int(colorGInp.getValue()) > 255) colorGInp.setValue("255");
  if(int(colorGInp.getValue()) < 1) colorGInp.setValue("0");
  
  if(int(colorBInp.getValue()) > 255) colorBInp.setValue("255");
  if(int(colorBInp.getValue()) < 1) colorBInp.setValue("0");
  
  newColor.R = int(colorRInp.getValue());
  newColor.G = int(colorGInp.getValue());
  newColor.B = int(colorBInp.getValue());

  xClient.setGeneralSettings(float(spawnProtectTimeInp.getValue()), textInp.getValue(), newColor);
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
			case resetButton: setValues(); break;
			case saveButton: saveSettings(); break;
		}
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     panelIdentifier="nexgenIntroSettings"
     PanelHeight=108.000000
}
