class KFLocalMessage_Turret extends LocalMessage
	abstract;

static function ClientReceive(
	PlayerController P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	local string MessageString;
	local KFPlayerController KFP;

	MessageString = static.GetString(Switch);
	if ( MessageString != "" )
	{
		KFP = KFPlayerController(P);
		if( KFP!=None && KFP.MyGFxHUD!=None )
			KFP.MyGFxHUD.ShowNonCriticalMessage(MessageString);
		if(IsConsoleMessage(Switch) && LocalPlayer(P.Player) != None && LocalPlayer(P.Player).ViewportClient != None)
			LocalPlayer(P.Player).ViewportClient.ViewportConsole.OutputText( "<Turret>: "$MessageString );
	}
}

static function string GetString(
    optional int Sw,
    optional bool bPRI1HUD,
    optional PlayerReplicationInfo RelatedPRI_1,
    optional PlayerReplicationInfo RelatedPRI_2,
    optional Object OptionalObject
    )
{
	switch(Sw)
	{
	case 0:
		return "Not enough dosh to buy this turret";
	case 1:
		return "Too close to another turret";
	case 2:
		return "Can't place the turret here";
	case 3:
		return "You have reached the maximum turrets alive";
	case 4:
		return "Turret destroyed!";
	case 5:
		return "This turret does not belong to you!";
	case 6:
		return "There are too many turrets in the game";
	case 7:
		return "Not enough dosh for this turret upgrade!";
	default:
		return "";
	}
}

defaultproperties
{
   Name="Default__KFLocalMessage_Turret"
   ObjectArchetype=LocalMessage'Engine.Default__LocalMessage'
}
