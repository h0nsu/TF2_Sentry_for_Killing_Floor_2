Class SentryUI_UpgradeMenu extends GFxObject;

var SentryUI_Menu Manager;
var GFxObject ItemDetailsContainer,EquipButton;
var int CurrentFilterIndex,OldWorth;

function InitializeMenu( SentryUI_Menu InManager )
{
	Manager = InManager;
	UpdateText();
	ItemDetailsContainer = GetObject("itemDetailsContainer");
	EquipButton = ItemDetailsContainer.GetObject("equipButton");
}

final function UpdateText()
{
	local GFxObject LocalizedObject;

	LocalizedObject = GetObject("localizedText");
	if( LocalizedObject==None )
	{
		LocalizedObject = CreateObject( "Object" );
		LocalizedObject.SetString("back",Class'KFCommon_LocalizedStrings'.default.BackString);
		LocalizedObject.SetString("inventory",Manager.NetOwner.TurretOwner.GetOwnerName()$"'s Turret");
		LocalizedObject.SetString("craftWeapon","Sell Turret");
		LocalizedObject.SetString("craftCosmetic","Close Menu");
		LocalizedObject.SetString("all","Levels");
		LocalizedObject.SetString("weaponSkins","Upgrades");
		LocalizedObject.SetString("cosmetics","Ammunition");
		LocalizedObject.SetString("craftingMats","N/A");
		LocalizedObject.SetString("items","N/A");
	}
	OldWorth = Manager.NetOwner.TurretOwner.SentryWorth;
	LocalizedObject.SetString("filters","Value: "$OldWorth$Chr(163));
	SetObject("localizedText", LocalizedObject);
}

function CallBack_RequestWeaponCraftInfo() // Sell!
{
	Manager.NetOwner.SellTurret();
	Manager.CloseMenu();
}
function CallBack_RequestCosmeticCraftInfo() // Close menu.
{
	Manager.CloseMenu();
}

function Refresh()
{
	if( OldWorth!=Manager.NetOwner.TurretOwner.SentryWorth )
		UpdateText();
	Callback_InventoryFilter(CurrentFilterIndex);
}

function Callback_InventoryFilter( int FilterIndex )
{
	local GFxObject ItemArray, ItemObject;
	local int i,j;
	local SentryUI_Network N;
	local string S;
	local bool bUpgrade;
	
	CurrentFilterIndex = FilterIndex;
	ItemArray = CreateArray();
	N = Manager.NetOwner;
	j = 0;

	for( i=0; i<N.Upgrades.Length; ++i )
	{
		if( N.Upgrades[i].Filter!=FilterIndex )
			continue;
		ItemObject = CreateObject("Object");
		
		ItemObject.SetInt("count", Max(N.Upgrades[i].Cost,1));
		ItemObject.SetString("label", N.Upgrades[i].Text);
		ItemObject.SetString("price", "");
		ItemObject.Setstring("typeRarity", "");
		bUpgrade = N.TurretOwner.CanUpgrade(i);
		ItemObject.SetInt("type", (bUpgrade ? 0 : 1));
		ItemObject.SetBool("exchangeable", false);
		ItemObject.SetBool("recyclable", false);
		ItemObject.SetBool("active", bUpgrade);
		ItemObject.SetInt("rarity", j);
		ItemObject.SetString("description", N.Upgrades[i].Desc);
		S = "img://"$PathName(N.Upgrades[i].Icon);
		ItemObject.SetString("iconURLSmall", S);
		ItemObject.SetString("iconURLLarge", S);
		ItemObject.SetInt("definition", i);

		ItemArray.SetElementObject(j, ItemObject);
		++j;
	}

	SetObject("inventoryList", ItemArray);
}

function Callback_RequestInitialnventory()
{
	Callback_InventoryFilter(0);
}

function CallBack_ItemDetailsClicked(int ItemDefinition)
{
	EquipButton.SetString("label", "Buy for "$Manager.NetOwner.Upgrades[ItemDefinition].Cost$Chr(163));
}

function Callback_Equip( int ItemDefinition )
{
	Manager.NetOwner.BuyPowerup(ItemDefinition);
}

defaultproperties
{
   Name="Default__SentryUI_UpgradeMenu"
   ObjectArchetype=GFxObject'GFxUI.Default__GFxObject'
}
