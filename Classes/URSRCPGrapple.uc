class URSRCPGrapple extends NexgenPanel;

#exec TEXTURE IMPORT NAME=graplogo FILE=Resources\grapLogo512.pcx GROUP="GFX" FLAGS=1 MIPS=On

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
	local NexgenContentPanel p;
	local int index;
	local int region;
	local int region2;

  GRI = client.player.gameReplicationInfo;
	TGRI = TournamentGameReplicationInfo(GRI);
	xClient = URSGrappleClient(client.getController(class'URSGrappleClient'.default.ctrlID));

	// Create layout & add components.
	setAcceptsFocus();
	createPanelRootRegion();
	splitRegionH(156, defaultComponentDist);
	p = addContentPanel();
	p.addImageBox(Texture'grapLogo');
  // p.skipRegion();

  divideRegionV(3);

  addSubPanel(class'URSRCPArea1');
  
  addSubPanel(class'URSBind');
  
  addSubPanel(class'URSRCPArea3');

}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     panelIdentifier="Grapple"
}
