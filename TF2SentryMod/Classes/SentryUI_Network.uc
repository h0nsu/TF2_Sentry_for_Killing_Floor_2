class SentryUI_Network extends ReplicationInfo;

var repnotify SentryTurret TurretOwner;
var repnotify PlayerController PlayerOwner;
var SentryUI_Menu ActiveMenu;
var transient byte SendIndex;
var transient int OldAmmoCount[2];

struct FUpgradeInfo
{
	var string Text,Desc;
	var int Cost,Extra,ExtraB;
	var Texture2D Icon;
	var byte Filter;
	var PlayerReplicationInfo Buyer;
};
var transient array<FUpgradeInfo> Upgrades;
var transient bool bWasInitAlready,bActiveTimer;

replication
{
	// Variables the server should send ALL clients.
	if( true )
		TurretOwner,PlayerOwner;
}

simulated function PostBeginPlay()
{
}

simulated event ReplicatedEvent( name VarName )
{
	if( TurretOwner!=None && PlayerOwner!=None && !bWasInitAlready )
	{
		bWasInitAlready = true;
		SetOwner(PlayerOwner);
		SetTurret(TurretOwner);
	}
}

simulated final function SetTurret( SentryTurret T )
{
	TurretOwner = T;
	TurretOwner.CurrentUsers.AddItem(Self);
	
	if( PlayerOwner!=None && LocalPlayer(PlayerOwner.Player)!=None )
	{
		ActiveMenu = new(None) class'SentryUI_Menu';
		ActiveMenu.SetTimingMode(TM_Real);
		ActiveMenu.NetOwner = Self;
		ActiveMenu.Init(LocalPlayer(PlayerOwner.Player));
	}
	if( WorldInfo.NetMode!=NM_Client )
	{
		if( TurretOwner.OwnerController==None ) // Claim ownership of this turret.
			TurretOwner.SetTurretOwner(PlayerOwner);
		GoToState('ReplicateData');
	}
}
simulated function Destroyed()
{
	if( ActiveMenu!=None )
	{
		ActiveMenu.CloseMenu(true);
		ActiveMenu = None;
	}
	if( TurretOwner!=None )
		TurretOwner.CurrentUsers.RemoveItem(Self);
}

simulated final function NotifyMenuClosed()
{
	ActiveMenu = None;
	ServerMenuClosed();
}
reliable server function ServerMenuClosed()
{
	Destroy();
}

simulated reliable client function ClientUpgradeInfo( byte Index, int Cost, PlayerReplicationInfo Buyer, optional int Extra )
{
	local byte i;

	if( Upgrades.Length<=Index )
		Upgrades.Length = (Index+1);
	Upgrades[Index].Cost = Cost;
	Upgrades[Index].Buyer = Buyer;

	if( Index<TurretOwner.MAX_TURRET_LEVELS )
	{
		Upgrades[Index].Icon = TurretOwner.Levels[Index].Icon;
		Upgrades[Index].Filter = 0;
		Upgrades[Index].Extra = Extra & 1023;
		Upgrades[Index].ExtraB = Extra >> 10;
	}
	else
	{
		i = Index-TurretOwner.MAX_TURRET_LEVELS;
		if( i<TurretOwner.ETU_MAXUPGRADES )
		{
			Upgrades[Index].Icon = TurretOwner.Upgrades[i].Icon;
			Upgrades[Index].Filter = i>=TurretOwner.ETU_AmmoSMG ? 2 : 1;
		}
	}
	UpdateDesc(Index);
	SetTimer(0.15,false,'PendingUpdateDisplay');
}
simulated reliable client function ClientUpdateInfo( byte Index, PlayerReplicationInfo Buyer )
{
	if( Upgrades.Length<=Index )
		Upgrades.Length = (Index+1);
	Upgrades[Index].Buyer = Buyer;
	UpdateDesc(Index);
	SetTimer(0.15,false,'PendingUpdateDisplay');
}

simulated function PendingUpdateDisplay()
{
	if( ActiveMenu!=None )
	{
		ActiveMenu.UpdateDisplay();
		if( !bActiveTimer )
		{
			SetTimer(1,true,'CheckAmmoLevel');
			bActiveTimer = true;
		}
	}
}
simulated final function CheckAmmoLevel()
{
	local byte i;

	if( TurretOwner==None || ActiveMenu==None || ActiveMenu.UpgradeMenu.CurrentFilterIndex!=2 )
		return;

	if( OldAmmoCount[0]!=TurretOwner.AmmoLevel[0] || OldAmmoCount[1]!=TurretOwner.AmmoLevel[1] )
	{
		OldAmmoCount[0] = TurretOwner.AmmoLevel[0];
		OldAmmoCount[1] = TurretOwner.AmmoLevel[1];
		
		for( i=TurretOwner.MAX_TURRET_LEVELS+TurretOwner.ETU_AmmoSMG; i<Upgrades.Length; ++i ) // Make sure these menus stay in sync.
			UpdateDesc(i);
		SetTimer(0.1,false,'PendingUpdateDisplay');
	}
}

simulated final function UpdateDesc( byte Index )
{
	local byte i,j;

	if( Index<TurretOwner.MAX_TURRET_LEVELS )
	{
		Upgrades[Index].Text = "Level "$(Index+1)$" Sentry";
		if( Index==0 )
			Upgrades[Index].Desc = "This is initial level of the Sentry Turret.";
		else Upgrades[Index].Desc = "Upgrades sentry to level "$(Index+1)$" Sentry Turret.";
		Upgrades[Index].Desc = Upgrades[Index].Desc$"\nHealth: "$Upgrades[Index].ExtraB$"\nRate of fire: "$TurretOwner.Levels[Index].RoF$"\nBullet damage: "$Upgrades[Index].Extra;
		
		if( Index==0 )
			Upgrades[Index].Desc = Upgrades[Index].Desc$"\nSentry bought by: "$TurretOwner.GetOwnerName();
		else if( TurretOwner.HasUpgrade(Index) )
			Upgrades[Index].Desc = Upgrades[Index].Desc$"\nUpgrade bought by: "$(Upgrades[Index].Buyer!=None ? Upgrades[Index].Buyer.PlayerName : "Someone");
		return;
	}
	i = Index-TurretOwner.MAX_TURRET_LEVELS;
	if( i<TurretOwner.ETU_MAXUPGRADES )
	{
		j = InStr(TurretOwner.UpgradeNames[i],"|");
		Upgrades[Index].Text = Left(TurretOwner.UpgradeNames[i],j);
		Upgrades[Index].Desc = Mid(TurretOwner.UpgradeNames[i],j+1);
		
		if( i>=TurretOwner.ETU_AmmoSMG )
		{
			if( i<TurretOwner.ETU_AmmoMissiles )
				Upgrades[Index].Desc = Upgrades[Index].Desc$"\n\nCURRENT AMMO: "$TurretOwner.AmmoLevel[0]$"/"$TurretOwner.MaxAmmoCount[0];
			else Upgrades[Index].Desc = Upgrades[Index].Desc$"\n\nCURRENT AMMO: "$TurretOwner.AmmoLevel[1]$"/"$TurretOwner.MaxAmmoCount[1];
		}
		else if( TurretOwner.HasUpgrade(Index) )
			Upgrades[Index].Desc = Upgrades[Index].Desc$"\nUpgrade bought by: "$(Upgrades[Index].Buyer!=None ? Upgrades[Index].Buyer.PlayerName : "Someone");
	}
}


reliable server function BuyPowerup( byte Index )
{
	if( !TurretOwner.CanUpgrade(Index) )
		return;

	if( Index<TurretOwner.MAX_TURRET_LEVELS )
	{
		if( PlayerOwner.PlayerReplicationInfo.Score<TurretOwner.LevelCfgs[Index].Cost )
		{
			PlayerOwner.ReceiveLocalizedMessage( class'KFLocalMessage_Turret', 7 );
			return;
		}
		TurretOwner.SentryWorth += TurretOwner.LevelCfgs[Index].Cost;
		TurretOwner.Levels[Index].Buyer = PlayerOwner.PlayerReplicationInfo;
		PlayerOwner.PlayerReplicationInfo.Score -= TurretOwner.LevelCfgs[Index].Cost;
		TurretOwner.SetLevelUp();
		TurretOwner.NotifyStatUpdate(Index);
		if( PlayerOwner!=TurretOwner.OwnerController && KFPlayerController(PlayerOwner)!=None )
			KFPlayerController(PlayerOwner).AddWeldPoints(TurretOwner.LevelCfgs[Index].Cost>>1);
		return;
	}
	Index -= TurretOwner.MAX_TURRET_LEVELS;
	if( Index<TurretOwner.ETU_MAXUPGRADES )
	{
		if( PlayerOwner.PlayerReplicationInfo.Score<TurretOwner.UpgradeCosts[Index] )
		{
			PlayerOwner.ReceiveLocalizedMessage( class'KFLocalMessage_Turret', 7 );
			return;
		}
		if( Index<TurretOwner.ETU_AmmoSMG )
		{
			TurretOwner.SentryWorth += TurretOwner.UpgradeCosts[Index];
			TurretOwner.Upgrades[Index].Buyer = PlayerOwner.PlayerReplicationInfo;
		}
		PlayerOwner.PlayerReplicationInfo.Score -= TurretOwner.UpgradeCosts[Index];
		if( PlayerOwner!=TurretOwner.OwnerController && KFPlayerController(PlayerOwner)!=None )
			KFPlayerController(PlayerOwner).AddWeldPoints(TurretOwner.UpgradeCosts[Index]>>1);
		TurretOwner.ApplyUpgrade(Index);
		return;
	}
}
reliable server function SellTurret()
{
	TurretOwner.TryToSellTurret(PlayerOwner);
}

function StatUpdated( byte Index )
{
	local byte i;

	if( Index<TurretOwner.MAX_TURRET_LEVELS )
		ClientUpdateInfo(Index,TurretOwner.Levels[Index].Buyer);
	else
	{
		i = Index-TurretOwner.MAX_TURRET_LEVELS;
		if( i<TurretOwner.ETU_MAXUPGRADES )
			ClientUpdateInfo(Index,TurretOwner.Upgrades[i].Buyer);
	}
}
simulated final function ClientStatUpdated( byte Index )
{
	SetTimer(0.15,false,'PendingUpdateDisplay');
}

state ReplicateData
{
	function Tick( float Delta )
	{
		if( TurretOwner==None || TurretOwner.Health<=0 || PlayerOwner==None || PlayerOwner.Pawn==None )
			Destroy();
	}

Begin:
	Sleep(0.1);
	for( SendIndex=0; SendIndex<TurretOwner.MAX_TURRET_LEVELS; ++SendIndex )
	{
		ClientUpgradeInfo(SendIndex,TurretOwner.LevelCfgs[SendIndex].Cost,TurretOwner.Levels[SendIndex].Buyer,(TurretOwner.LevelCfgs[SendIndex].Damage & 1023) | (TurretOwner.LevelCfgs[SendIndex].Health << 10));
		Sleep(0.001);
	}
	for( SendIndex=0; SendIndex<TurretOwner.ETU_MAXUPGRADES; ++SendIndex )
	{
		ClientUpgradeInfo(TurretOwner.MAX_TURRET_LEVELS+SendIndex,TurretOwner.UpgradeCosts[SendIndex],TurretOwner.Upgrades[SendIndex].Buyer);
		Sleep(0.001);
	}
}

defaultproperties
{
   bOnlyRelevantToOwner=True
   bAlwaysRelevant=False
   Name="Default__SentryUI_Network"
   ObjectArchetype=ReplicationInfo'Engine.Default__ReplicationInfo'
}
