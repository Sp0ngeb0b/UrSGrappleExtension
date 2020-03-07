class URSScoreBoardHud extends NexgenHUDExtension;

var URSGrappleClient xClient;
var int orgCrosshairCount;

var color BeaconColor[2];

const logoTextureWidth = 256;           // Width of the logo texture.
const logoTextureHeight = 128;           // Height of the logo texture.

/***************************************************************************************************
 *
 *  $DESCRIPTION  Renders the HUD. Called before anything of the game HUD has been drawn. This
 *                function is only called if the Nexgen HUD is enabled.
 *  $PARAM        c  Canvas object that provides the drawing capabilities.
 *  $REQUIRE      c != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function preRender(Canvas c) {

  if(xClient  == none) xClient = URSGrappleClient(client.getController(class'URSGrappleClient'.default.ctrlID));
	
  if(client != none) {
  
    // Fix ACE crosshair scaling
    if(xClient != none && xClient.HUD != none && xClient.HUDWrapper != none) {
      if (!client.player.bBehindView && client.player.Weapon != None && Level.LevelAction == LEVACT_None) {
        C.DrawColor = xClient.HUD.WhiteColor;
		    client.player.Weapon.PostRender(C);
		    if(!client.player.Weapon.bOwnsCrossHair) {
          orgCrosshairCount = xClient.HUD.CrosshairCount;
          xClient.HUDWrapper.DrawCrossHair(C, 0,0);
          xClient.HUD.CrosshairCount = -1;
        }
      }
    }
    
    // Render Scoreboard logos
    if(client.player.bShowScores) {

      // Render Facebook icon
      c.drawColor = Class'URSGrappleHud'.default.logoBaseColor;
      c.style = ERenderStyle.STY_Normal;
      c.setPos(16, c.ClipY - 108);
	    c.DrawIcon (Texture'Facebook', 0.5);

      // Render UrS Logo
      c.setPos(c.ClipX -logoTextureWidth / 2 - 16, c.ClipY - logoTextureHeight / 2 - 18);
      c.DrawIcon(Texture'urslogoP1', 0.5);
	    c.setPos(c.ClipX - logoTextureWidth / 4 - 16, c.ClipY - logoTextureHeight / 2 - 18);
	    c.DrawIcon(Texture'urslogoP2', 0.5);
	    
	    // Render website
	    c.setPos(c.ClipX - logoTextureWidth / 1.5 - 4, c.ClipY - 16);
      c.DrawIcon(Texture'helpbar', 0.75);
	  }
  }
}

defaultproperties
{
     bAlwaysTick=True
     BeaconColor(0)=(R=255)
     BeaconColor(1)=(R=32,G=64,B=255)
     RemoteRole=ROLE_None
}
