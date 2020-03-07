class URSRCPArea1 extends NexgenPanel;

var URSGrappleClient xclient;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {
	local GameReplicationInfo GRI;
	local int region;

  GRI = client.player.gameReplicationInfo;
	xClient = URSGrappleClient(client.getController(class'URSGrappleClient'.default.ctrlID));

	// Create layout & add components.
	setAcceptsFocus();
	createPanelRootRegion();

	splitRegionH(52);
  region = currRegion;
	skipRegion();


  divideRegionH(5);
  addLabel("Message of the Day", true, TA_Center);
  addLabel(fixStr(GRI.MOTDLine1), false, TA_Center);
  addLabel(fixStr(GRI.MOTDLine2), false, TA_Center);
  addLabel(fixStr(GRI.MOTDLine3), false, TA_Center);
  addLabel(fixStr(GRI.MOTDLine4), false, TA_Center);

  selectRegion(region);
	selectRegion(splitRegionH(16));
	addLabel("Contact", true, TA_Center);
	
	divideRegionH(3);
  addLabel(fixStr(GRI.adminName), false, TA_Center);
  addLabel(fixStr(GRI.adminEmail), false, TA_Center);
  skipRegion();

}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Makes sure a non empty string is returned.
 *
 **************************************************************************************************/
static function string fixStr(coerce string str) {
	if (class'NexgenUtil'.static.trim(str) == "") {
		return "-";
	} else {
		return str;
	}
}

defaultproperties
{
}
