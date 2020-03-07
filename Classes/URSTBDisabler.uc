// Since we cant deactivate Nexgen's build-in teambalancer, we have to overwrite it.
// Messages can't be deactivated without modifying Nexgen's base. :(
// So Nexgen will always say that the Teams are even
class URSTBDisabler extends NexgenTeamBalancer;

var NexgenController control;           // The Nexgen controller.

/***************************************************************************************************
 *
 *  $DESCRIPTION  Initializes the team balancer.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function preBeginPlay() {

	// Check owner.
	if (owner == none || !owner.isA('NexgenController')) {
		destroy();
		return;
	}

	// Set controller.
	control = NexgenController(owner);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Attempts to balance the current teams.
 *  $RETURN       True if the teams have been balanced, false if they are already balanced.
 *
 **************************************************************************************************/
function bool balanceTeams() {

	return false;
}

defaultproperties
{
}
