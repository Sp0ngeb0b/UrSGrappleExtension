class URSGrappleHud extends Mutator;

#exec TEXTURE IMPORT NAME=urslogoP1   FILE=Resources\URSLogo1.pcx            GROUP="GFX" FLAGS=1 MIPS=OFF
#exec TEXTURE IMPORT NAME=urslogoP2   FILE=Resources\URSLogo2.pcx            GROUP="GFX" FLAGS=1 MIPS=OFF
#exec TEXTURE IMPORT NAME=loadingbar  FILE=Resources\ProgressBar.pcx         GROUP="GFX" FLAGS=2 MIPS=OFF
#exec TEXTURE IMPORT NAME=readybar    FILE=Resources\ProgressBar2.pcx        GROUP="GFX" FLAGS=2 MIPS=OFF
#exec TEXTURE IMPORT NAME=blankbar    FILE=Resources\ProgressBar3.pcx        GROUP="GFX" FLAGS=2 MIPS=OFF
#exec TEXTURE IMPORT NAME=segment     FILE=Resources\ProgressBarSegment.pcx  GROUP="GFX" FLAGS=2 MIPS=OFF
#exec TEXTURE IMPORT NAME=helpbar     FILE=Resources\ProgressBar5.pcx        GROUP="GFX" FLAGS=2 MIPS=OFF
#exec TEXTURE IMPORT NAME=Facebook    FILE=Resources\facebookLogo.pcx        GROUP="GFX" FLAGS=2 MIPS=OFF

var URSGrappleClient xClient;           // The extended client controller.

var color BeaconColor[2];
var bool bRenderPlayernameHUD;

var bool bLoadingComplete;              // Whether Nexgen has been loaded.
var bool bDone;                         // Set to true if the loading / ready animation is done.
var float finishAnimTimeStamp;          // Time at which the finish animation is started.

var float timeSeconds;                  // Game speed independent level.timeSeconds.

var color logoBaseColor;                // The base server logo color.
var color loadingColor;                 // Loading progress bar animation color.
var color readyColor;                   // Ready progress bar animation color.

const minimumLoadingTime = 5.0;         // Minimum time loading state is active.

const logoTextureWidth = 256;           // Width of the logo texture.
const logoTextureHeight = 128;          // Height of the logo texture.
const progressbarTextureWidth = 256;    // Width of the progress bar texture.
const progressbarTextureHeight = 16;    // Height of the progress bar texture.
const blankbarTextureWidth = 256;       // Width of the progress bar texture.
const blankbarTextureHeight = 32;
const segmentTextureWidth = 16;         // Width of the progress bar segment texture.
const segmentTextureHeight = 16;        // Height of the progress bar segment texture.

const progressBarHOffset = 104;         // Horizontal progress bar offset relative to logo.
const progressBarVOffset = 142;         // Vertical progress bar offset relative to logo.
const blankbarHOffset = -32;            // Horizontal progress BlankBar offset relative to logo.
const blankbarVOffset = 174;            // Vertical progress BlankBar offset relative to logo.
const helpbarHOffset = 0;               // Horizontal progress helpBar offset relative to logo.
const helpbarVOffset = -32;             // Vertical progress helpBar offset relative to logo.

const segmentHOffset = 36;              // First segment horizontal offset relative to logo.
const segmentVOffset = 176;                // First segment vertikal offset relative to logo.
const segmentDistance = 16;             // Distance between segments.

const numSegments = 11;                 // Number of progress bar segments.
const animCycleTime = 1;                // Progress indicator animation cycle time.
const trailsize = 5;                    // Length of the progress indicator.

const finishAnimationTime = 0.5;        // Amount of time required for the finish animation to complete.



/***************************************************************************************************
 *
 *  $DESCRIPTION  Initializes the HUD extension.
 *  $REQUIRE      owner != none && owner.isA('URSGrappleClient')
 *  $ENSURE       client != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function postBeginPlay() {
	super.postBeginPlay();
	xClient = URSGrappleClient(owner);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Game tick. Enabled support for game speed independent timing. Also attemps to
 *                register this URSGrappleHud instance as a HUD mutator.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function tick(float deltaTime) {
	// Game speed independent timing support.
	timeSeconds += deltaTime / level.timeDilation;

	// Register as HUD mutator if not already done. Note this may fail several times.
	if (!bHUDMutator) registerHUDMutator();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Renders the extended Nexgen HUD.
 *  $PARAM        c  Canvas object that provides the drawing capabilities.
 *  $REQUIRE      c != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function postRender(Canvas c) {
	local int baseX, baseY;
	local float animIndex;
	local int position;
	local int nextPosition;
	local int index;
	local float phase;
	local color segmentColor;
	local Texture progressBarTexture;
	local float textWidth;
	local float textHeigh;

	// Let other HUD mutators do their job first.
	if (nextHUDMutator != none) {
		nextHUDMutator.postRender(c);
  }
  
  renderRexCTF(c);
  c.reset();
  if(bRenderPlayernameHUD) {
    renderPlayernameHUD(c);
    c.reset();
  }
  
	// Don't render anything if animation is complete or the game has ended.
	if (bDone || xClient.client != none && xClient.client.gInf.gameState == xClient.client.gInf.GS_Ended) return;

	// Check if the loading animation is completed.
	if (!bLoadingComplete && xClient.client != none && !xClient.client.bNetWait && timeSeconds > minimumLoadingTime) {
		bLoadingComplete = true;
	}

	// Check whether the finish animation is to be started.
	if (finishAnimTimeStamp <= 0 && bLoadingComplete && xClient.client.gInf.gameState > xClient.client.gInf.GS_Ready) {
		finishAnimTimeStamp = timeSeconds;
	}

	// Render logo.
	baseX = (c.clipX - logoTextureWidth) / 2;
	baseY = c.clipY * 0.7 - logoTextureHeight /2;

	if (finishAnimTimeStamp > 0) {
		animIndex = (timeSeconds - finishAnimTimeStamp) / finishAnimationTime;
		if (animIndex > 1) {
			bDone = true;
			return;
		}
		baseX += (animIndex * animIndex) * (c.clipX - baseX);
	}

	c.style = ERenderStyle.STY_Normal;
	c.drawColor = logoBaseColor;

	c.setPos(baseX, baseY);
	c.drawTile(Texture'urslogoP1', logoTextureWidth / 2, logoTextureHeight, 0.0, 0.0, logoTextureWidth / 2, logoTextureHeight);
	c.setPos(baseX + logoTextureWidth / 2, baseY);
	c.drawTile(Texture'urslogoP2', logoTextureWidth / 2, logoTextureHeight, 0.0, 0.0, logoTextureWidth / 2, logoTextureHeight);

  // Render Facebook icon
  c.style = ERenderStyle.STY_Translucent;
  if (finishAnimTimeStamp > 0) {
    c.setPos(c.ClipX - 256 * (0.5-animIndex/2) - 16, baseY - c.ClipY/3);
    c.DrawIcon (Texture'Facebook', 0.5-animIndex/2);
	} else {
    c.setPos(c.ClipX - 128 - 16, baseY - c.ClipY/3);
    c.DrawIcon (Texture'Facebook', 0.5);
  }

  c.style = ERenderStyle.STY_Normal;
  
  // Render progress bar.
	if (finishAnimTimeStamp > 0) return;
	if (bLoadingComplete) {
		segmentColor = readyColor;
		progressBarTexture = Texture'readybar';
	} else {
		segmentColor = loadingColor;
		progressBarTexture = Texture'loadingbar';
	}

	c.setPos(baseX + progressBarHOffset, baseY + progressBarVOffset);
	c.drawTile(progressBarTexture, progressbarTextureWidth, progressbarTextureHeight, 0.0, 0.0, progressbarTextureWidth, progressbarTextureHeight);

  // Render text
  if(xClient != none && xClient.conf != none && xClient.conf.InfoText != "") {

  	C.Font = ChallengeHUD(xClient.client.player.MyHUD).MyFonts.GetMediumFont(c.clipX);
  	c.StrLen(xClient.conf.InfoText, textWidth, textHeigh);
  	C.drawColor = xClient.conf.textColor;

    c.SetPos( (c.clipX - textWidth) / 2, baseY + helpbarVOffset);
    c.DrawText(xClient.conf.InfoText, false);
    C.drawColor = logoBaseColor;
  } else {
    c.setPos(baseX, baseY - 24);
    c.drawTile(Texture'helpbar', progressbarTextureWidth, progressbarTextureHeight, 0.0, 0.0, progressbarTextureWidth, progressbarTextureHeight);
  }
  
  // Render blankbar
  if (finishAnimTimeStamp > 0) return;

  c.setPos(baseX + blankbarHOffset + position * segmentDistance, baseY + blankbarVOffset);
  c.drawTile(Texture'blankbar', blankbarTextureWidth, blankbarTextureHeight, 0.0, 0.0, blankbarTextureWidth, blankbarTextureHeight);


	// Render progress bar animation.
	animIndex = (timeSeconds % animCycleTime) / animCycleTime;
	nextPosition = int(animIndex * numSegments);
	phase = (animIndex * numSegments) % 1.0;
	for (index = 0; index <= trailsize; index++) {
		position = nextPosition - index;
		if (position < 0) position += numSegments;

		if (index == 0) {
			c.drawColor = segmentColor * phase;
		} else {
			c.drawColor = segmentColor * fClamp(((trailsize - index + 1) / trailsize) - phase / trailsize, 0.0, 1.0);
		}
		c.setPos(baseX + segmentHOffset + position * segmentDistance, baseY + segmentVOffset);
		c.drawTile(Texture'segment', segmentTextureWidth, segmentTextureHeight, 0.0, 0.0, segmentTextureWidth, segmentTextureHeight);
	}

}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Renders flag countdown and carrier name. Copied from RextendedCTF.
 *
 **************************************************************************************************/
function renderRexCTF(Canvas c) {
	local float Scale;
	local int X,Y;
  local int NameLength[2];
  
  // Setup Canvas
	c.bCenter = True;
	Scale = ChallengeHUD(c.Viewport.Actor.myHUD).Scale;
	X = c.ClipX - 63 * Scale;
	Y = c.ClipY - 322 * Scale;
	c.Font = c.MedFont;
	c.Style = ERenderStyle.STY_Masked;
	c.DrawColor.R = 255;
	c.DrawColor.G = 255;
	c.DrawColor.B = 255;
  
  // Flag countdowns
  if(xClient.countDown[0] > 0 && xClient.countDown[0] < 26) { // Red flag is dropped
		c.SetPos(X,Y);
		c.DrawText(xClient.countDown[0]);
	}
	if(xClient.countDown[1] > 0 && xClient.countDown[1] < 26) { // Blue flag is dropped
		c.SetPos(X,Y - 150 * Scale);
		c.DrawText(xClient.countDown[1]);
	}
  
  c.Style = ERenderStyle.STY_Translucent;
	c.Font = c.BigFont;
	c.bCenter = False;
  c.Font = ChallengeHUD(c.Viewport.Actor.myHUD).MyFonts.GetBigFont(c.ClipX-500);

  // Carrier names
	if(xClient.flagCarrier[0] != "" ) {        // Someone is holding the red flag
    NameLength[0] = len(xClient.flagCarrier[0]);
		c.SetPos(X + 10 - (NameLength[0]*10) * Scale,Y + 35 * Scale);
		c.DrawColor.R = 0;
		c.DrawColor.G = 128;
		c.DrawColor.B = 255;
		c.DrawText(xClient.flagCarrier[0]);
	}
	if(xClient.flagCarrier[1] != "") { // Someone is holding the blue flag
		NameLength[1] = len(xClient.flagCarrier[1]);
		c.SetPos(X + 10 - (NameLength[1]*10) * Scale,Y - 120 * Scale);
		c.DrawColor.R = 255;
		c.DrawColor.G = 0;
		c.DrawColor.B = 0;
		c.DrawText(xClient.flagCarrier[1]);
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Renders playername HUD.
 *
 **************************************************************************************************/
function renderPlayernameHUD(Canvas C)
{
	local Pawn thisPawn;
	local vector X, Y, Z, CamLoc, TargetDir, Dir, XY;
	local rotator CamRot;
	local Actor Camera;
	local float BaseBeaconScale, BeaconScale, Dist, DistScale;
	local float TanFOVx, TanFOVy;
	local float TanX, TanY;
	local float dx, dy, FontY, Scale, XL, YL;
	local string BeaconText;

	C.Style = ERenderStyle.STY_Masked;
	if (C.ClipX > 1024)
	C.Font =  Font( DynamicLoadObject( "LadderFonts.UTLadder22", class'Font' ) );
	else
	C.Font =  Font( DynamicLoadObject( "LadderFonts.UTLadder18", class'Font' ) );

	C.SetPos(0, 0);
	C.TextSize("X", dx, FontY);
	BaseBeaconScale = 1.5 * FontY;

	C.ViewPort.Actor.PlayerCalcView(Camera, CamLoc, CamRot);

	TanFOVx = Tan(C.ViewPort.Actor.FOVAngle / 114.591559);
	TanFOVy = (C.ClipY / C.ClipX) * TanFOVx;
	GetAxes(CamRot, X, Y, Z);

	C.bNoSmooth = False;
	C.Style = ERenderStyle.STY_Masked;
	foreach AllActors(class'Pawn', thisPawn) {
		if (thisPawn != Camera && thisPawn.Health > 0 && !thisPawn.bHidden && thisPawn.PlayerReplicationInfo != None && thisPawn.PlayerReplicationInfo.Team < 2 && (C.Viewport.Actor.PlayerReplicationInfo.bIsSpectator || !C.Viewport.Actor.PlayerReplicationInfo.bIsSpectator && thisPawn.PlayerReplicationInfo.Team == C.Viewport.Actor.PlayerReplicationInfo.Team)) {

			TargetDir = thisPawn.Location - CamLoc;
			Dist = VSize(TargetDir) * FMin(TanFOVx, 1.0);
			TargetDir = Normal(TargetDir + vect(0,0,1) * thisPawn.CollisionHeight);
			DistScale = FMin(133.0 * thisPawn.CollisionRadius / Dist, 1.0);

			if (DistScale > 0.5 && TargetDir dot X > 0 && (FastTrace(thisPawn.Location, CamLoc) || FastTrace(thisPawn.Location + vect(0,0,0.8) * thisPawn.CollisionHeight, CamLoc))) {
				BeaconScale = BaseBeaconScale * DistScale;
				Dir = X * (X dot TargetDir);
				XY = TargetDir - Dir;

				dx = C.ClipX * 0.5 * (1.0 + (XY dot Y) / (VSize(Dir) * TanFOVx));
				dy = C.ClipY * 0.5 * (1.0 - (XY dot Z) / (VSize(Dir) * TanFOVy));

				C.DrawColor = BeaconColor[thisPawn.PlayerReplicationInfo.Team];
				C.SetPos(dx - 0.5 * BeaconScale, dy - 2 * FontY * DistScale);

				BeaconText = thisPawn.PlayerReplicationInfo.PlayerName;
				if (C.ClipX > 600)
				BeaconText = BeaconText @ "(" $ thisPawn.Health $ ")";

				C.SetPos(dx + 0.6 * BeaconScale + 1, dy - 1.75 * FontY + 1);
				C.DrawColor = BeaconColor[thisPawn.PlayerReplicationInfo.Team] * 0.125;
				C.DrawTextClipped(BeaconText, False);

				C.SetPos(dx + 0.6 * BeaconScale, dy - 1.75 * FontY);
				C.DrawColor = BeaconColor[thisPawn.PlayerReplicationInfo.Team];
				C.DrawTextClipped(BeaconText, False);

			}
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
     logoBaseColor=(R=255,G=255,B=255)
     loadingColor=(R=227,G=164,B=12)
     readyColor=(G=255)
     bAlwaysTick=True
     BeaconColor(0)=(R=255)
     BeaconColor(1)=(R=32,G=64,B=255)
     RemoteRole=ROLE_None
}
