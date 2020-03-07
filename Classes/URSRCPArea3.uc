class URSRCPArea3 extends NexgenPanel;

var URSGrappleClient xclient;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {
	local GameReplicationInfo GRI;
	local TournamentGameReplicationInfo TGRI;
	local int region;

  GRI = client.player.gameReplicationInfo;
 	TGRI = TournamentGameReplicationInfo(GRI);
	xClient = URSGrappleClient(client.getController(class'URSGrappleClient'.default.ctrlID));

	// Create layout & add components.
	setAcceptsFocus();
	createPanelRootRegion();

	splitRegionH(64);
  region = currRegion;
	skipRegion();
	
	divideRegionH(3);
	skipRegion();
	addLabel("Website & Stats:", false, TA_Left);
  addLabel("www.unrealriders.eu", true, TA_Left);
	
	selectRegion(region);
	selectRegion(splitRegionH(16));
  addLabel("Server information", true, TA_Center);
  splitRegionV(80);
  divideRegionH(3);
  divideRegionH(3);
  addLabel("Adress");
  addLabel("Matches");
  addLabel("Location");

  addLabel("50.3.71.234:7777");
  if (TGRI != none) { addLabel(TGRI.totalGames); } else  { skipRegion(); }
  addLabel("Germany");

}

defaultproperties
{
}
