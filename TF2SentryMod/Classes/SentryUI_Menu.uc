Class SentryUI_Menu extends GFxMoviePlayer;

var SentryUI_Network NetOwner;
var GFxObject ManagerObject;
var SentryUI_UpgradeMenu UpgradeMenu;

function Init(optional LocalPlayer LocPlay)
{
	Super.Init(LocPlay);
	
	ManagerObject.SetBool("backgroundVisible", false);
	ManagerObject.SetBool("IISMovieVisible", false);
	
	LoadMenu( "../UI_Menus/InventoryMenu_SWF.swf", true );
}

/** Tells actionscript which .swf to open up */
function LoadMenu(string Path, bool bShowWidgets)
{
	ManagerObject.ActionScriptVoid("loadCurrentMenu");
}

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget)
{
	switch ( WidgetName )
	{
	case 'root1':
		if ( ManagerObject == none )
		{
			ManagerObject = Widget;
			// Let the menuManager know if we are on console.
			ManagerObject.SetBool("bConsoleBuild",class'WorldInfo'.static.IsConsoleBuild());
		}
		break;
	case 'inventoryMenu':
		if( UpgradeMenu==None )
		{
			UpgradeMenu = SentryUI_UpgradeMenu(Widget);
			UpgradeMenu.InitializeMenu(Self);
		}
		SetWidgetPathBinding(Widget, WidgetPath);
		SetExternalInterface(Widget);
		break;
	}
	return true;
}

event bool FilterButtonInput(int ControllerId, name ButtonName, EInputEvent InputEvent)
{
	// Handle closing out of currently active menu
	if ( InputEvent == EInputEvent.IE_Released && (ButtonName == 'Escape' || ButtonName == 'XboxTypeS_Start') )
	{
		CloseMenu();
		return true;
	}
 	return false;
}

/** Called when the movie player is closed */
event OnClose()
{
	if( NetOwner!=None )
		NetOwner.NotifyMenuClosed();
	NetOwner = None;
}

final function CloseMenu( optional bool bExternal )
{
	SetMenuVisibility(false);
	
	if( NetOwner!=None && !bExternal )
		NetOwner.NotifyMenuClosed();
	NetOwner = None;
	
	if( GetPC().PlayerInput != none )
		GetPC().PlayerInput.ResetInput();
	GetPC().SetTimer(0.1,false,'FinishedAnim',Self);
}

function SetMenuVisibility( bool bVisible )
{
	ManagerObject.ActionScriptVoid("setMenuVisibility");
}

function FinishedAnim()
{
	Close();
}

function UpdateDisplay()
{
	if( UpgradeMenu!=None )
		UpgradeMenu.Refresh();
}

defaultproperties
{
   MovieInfo=SwfMovie'UI_Managers.LoaderManager_SWF'
   bAutoPlay=True
   bCaptureInput=True
   SoundThemes(0)=(ThemeName="SoundTheme_Crate",Theme=UISoundTheme'SoundsShared_UI.SoundTheme_Crate')
   SoundThemes(1)=(ThemeName="ButtonSoundTheme",Theme=UISoundTheme'SoundsShared_UI.SoundTheme_Buttons')
   SoundThemes(2)=(ThemeName="AAR",Theme=UISoundTheme'SoundsShared_UI.SoundTheme_AAR')
   Priority=10
   WidgetBindings(0)=(WidgetName="root1",WidgetClass=Class'GFxUI.GFxObject')
   WidgetBindings(1)=(WidgetName="InventoryMenu",WidgetClass=Class'SentryUI_UpgradeMenu')
   Name="Default__SentryUI_Menu"
   ObjectArchetype=GFxMoviePlayer'GFxUI.Default__GFxMoviePlayer'
}
