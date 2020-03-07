class URSGrappleConfig extends ReplicationInfo;

var config int botCountForSinglePlayer;
var config string InfoText;
var config color textColor;

var config string spawnActors[16];

var config string CTFSoundCap[2];
var config string CTFSoundDrop[2];
var config string CTFSoundReturn[2];
var config string CTFSoundTaken[2];
var config string CTFSoundTeam[2];
var config string CTFSoundReturnExtra;
var config string CTFSoundTakenYou;
var config string playSound;

var config float spawnProtectionTime;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Replication block.
 *
 **************************************************************************************************/
replication {

	reliable if (role == ROLE_Authority)
		//Config settings.
		InfoText, textColor, spawnProtectionTime;

}

defaultproperties
{
  CTFSoundCap(0)="UrSGrappleSounds.Cap-r",
  CTFSoundCap(1)="UrSGrappleSounds.Cap-b",
  CTFSoundDrop(0)="UrSGrappleSounds.Dropped-r",
  CTFSoundDrop(1)="UrSGrappleSounds.Dropped-b",
  CTFSoundReturn(0)="UrSGrappleSounds.Returned-r",
  CTFSoundReturn(1)="UrSGrappleSounds.Returned-b",
  CTFSoundTaken(0)="UrSGrappleSounds.Taken-r",
  CTFSoundTaken(1)="UrSGrappleSounds.Taken-b",
  CTFSoundTeam(0)="UrSGrappleSounds.OnRed",
  CTFSoundTeam(1)="UrSGrappleSounds.OnBlue",
  CTFSoundReturnExtra="UrSGrappleSounds.Return",
  CTFSoundTakenYou="UrSGrappleSounds.Taken-you",
  playSound="UrSGrappleSounds.Play"
}
