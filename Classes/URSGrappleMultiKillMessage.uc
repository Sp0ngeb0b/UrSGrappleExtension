class URSGrappleMultiKillMessage extends LocalMessagePlus;

var localized string multiKillMessage[5];         // Multi kill message strings.
var localized string cheaterMessage;              // Message for extreme players.
var localized string insaneComboMessage;          // Message for an insane combo.
var localized string insaneComboMessageWicked;    // Message for a wicked insane combo.

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the string for this localized message.
 *  $PARAM        switch          Optional message switch.
 *  $PARAM        pri1            Replication info of the first player involved with the message.
 *  $PARAM        pri1            Replication info of the second player involved with the message.
 *  $PARAM        optionalObject  Extra object related to the message.
 *  $RETURN       The message string.
 *
 **************************************************************************************************/
static function string getString(optional int switch, optional PlayerReplicationInfo pri1,
                                 optional PlayerReplicationInfo pri2, optional Object optionalObject) {
	local string msg;
	
	if (pri1 != none) {
		if (1 <= switch) {
			if (switch == 10) {
				msg = class'NexgenUtil'.static.format(default.cheaterMessage, pri1.playerName);
			} else if (switch == 998) {
        msg = class'NexgenUtil'.static.format(default.insaneComboMessage, pri1.playerName);
      } else if (switch == 999) {
        msg = class'NexgenUtil'.static.format(default.insaneComboMessageWicked, pri1.playerName);
      } else if (switch > arrayCount(default.multiKillMessage)) {
				msg = class'NexgenUtil'.static.format(default.multiKillMessage[arrayCount(default.multiKillMessage) - 1], pri1.playerName);
			} else {
				msg = class'NexgenUtil'.static.format(default.multiKillMessage[switch - 1], pri1.playerName);
			}
		}
	}
	
	return msg;
}


/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     MultiKillMessage(0)="<C03>%1 had a Double Kill."
     MultiKillMessage(1)="<C02>%1 had a Multi Kill!"
     MultiKillMessage(2)="<C06>%1 had an ULTRA KILL!!"
     MultiKillMessage(3)="<C10>%1 had a  M O N S T E R  KILL!!!"
     MultiKillMessage(4)="<C10>%1 had another  M O N S T E R  KILL!!!"
     cheaterMessage="<C10>%1 should get a life! :D"
     insaneComboMessage="<C06>%1 had an insane combo!"
     insaneComboMessageWicked="<C06>%1 had another insane combo - WICKED SICK!"
}
