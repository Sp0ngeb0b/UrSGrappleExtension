class URSChatLog extends NexgenPanel;

var UWindowDynamicTextArea chatLog;
var UWindowCheckbox displayNewChat;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {

	// Create layout & add components.
	createWindowRootRegion();

	splitRegionH(244);
	chatLog = addDynamicTextArea();
	splitRegionV(300);
  skipRegion();
	displayNewChat = addCheckBox(TA_Left, "Display new chat messages");

	displayNewChat.bChecked = true;
  displayNewChat.register(self);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Adds a new message to the to message chat box.
 *  $PARAM        msg  The message to add.
 *
 **************************************************************************************************/
function addChatMsg(string msg) {
	local string timeStamp;

    if (displayNewChat.bChecked) {
      timeStamp = "[" $ right("0" $ client.level.hour, 2) $ ":" $ right("0" $ client.level.minute, 2) $ "]";
    	chatLog.addText(timeStamp @ msg);
    }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/

defaultproperties
{
     panelIdentifier="chatlog"
}
