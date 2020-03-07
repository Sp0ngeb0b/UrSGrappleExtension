class URSInfo extends NexgenPopupDialog;

var localized string caption;                     // Caption to display on the dialog.
var localized string message1;                     // Dialog help / info / description message.

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the dialog. Calling this function will setup the static dialog contents.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function created() {
	local float cy;

	super.created();

	// Add components.
	cy = borderSize;

	addText(caption, cy, F_Bold, TA_Center);
	addNewLine(cy);
	addText(message1, cy, F_Normal, TA_Left);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     Caption="Welcome new Player!"
     Message1="We've just seen that this is the first time you visit this server. We have a mod running which combines ComboGib with a GrapplingHook. The GrapplingHook can be used by switching to the Translocator, or you can bind it to a key by typing !grapple. Please note that you will drop the flag while using the GrapplingHook. Have fun and happy fragging!"
     wrapLength=79
}
