Class SentryMainRep extends ReplicationInfo
	transient;

var repnotify ObjectReferencer ObjRef;
var ObjectReferencer BaseRef;
var MaterialInstanceConstant TurSkins[3];
var KFCharacterInfo_Monster TurretArch[3];

replication
{
	if ( true )
		ObjRef;
}

simulated static final function SentryMainRep FindContentRep( WorldInfo Level )
{
	local SentryMainRep H;
	
	foreach Level.DynamicActors(class'SentryMainRep',H)
		if( H.ObjRef!=None )
			return H;
	if( Level.NetMode!=NM_Client )
	{
		H = Level.Spawn(class'SentryMainRep');
		return H;
	}
	return None;
}

function PostBeginPlay()
{
	local KFGameInfo K;
	
	Class'SentryTurret'.Static.UpdateConfig();

	// Replace scriptwarning spewing DialogManager.
	K = KFGameInfo(WorldInfo.Game);
	if( K!=None )
	{
		if( K.DialogManager!=None )
		{
			if( K.DialogManager.Class==Class'KFDialogManager' )
			{
				K.DialogManager.Destroy();
				K.DialogManager = Spawn(class'KFDialogManagerSentry');
			}
		}
		else if( K.DialogManagerClass==Class'KFDialogManager' )
			K.DialogManagerClass = class'KFDialogManagerSentry';
	}

	ObjRef = BaseRef;
	if( ObjRef!=None )
		InitRep();
}

simulated function ReplicatedEvent( name VarName )
{
	if( VarName=='ObjRef' && ObjRef!=None )
		InitRep();
}

simulated final function InitRep()
{
	if( WorldInfo.NetMode!=NM_DedicatedServer )
	{
		TurSkins[0] = CloneMIC(MaterialInstanceConstant(ObjRef.ReferencedObjects[1]));
		TurSkins[1] = CloneMIC(MaterialInstanceConstant(ObjRef.ReferencedObjects[3]));
		TurSkins[2] = CloneMIC(MaterialInstanceConstant(ObjRef.ReferencedObjects[12]));
	}
	TurretArch[0] = KFCharacterInfo_Monster(ObjRef.ReferencedObjects[0]);
	TurretArch[1] = KFCharacterInfo_Monster(ObjRef.ReferencedObjects[2]);
	TurretArch[2] = KFCharacterInfo_Monster(ObjRef.ReferencedObjects[11]);
	
	if( WorldInfo.NetMode==NM_Client )
		UpdateInstances();
}
simulated final function UpdateInstances()
{
	local SentryWeapon W;
	local SentryTurret T;

	foreach DynamicActors(class'SentryWeapon',W)
		W.InitDisplay(Self);
	foreach WorldInfo.AllPawns(class'SentryTurret',T)
	{
		T.ContentRef = Self;
		T.InitDisplay();
	}
}

simulated static final function MaterialInstanceConstant CloneMIC( MaterialInstanceConstant B )
{
	local int i;
	local MaterialInstanceConstant M;
	
	M = new (None) class'MaterialInstanceConstant';
	M.SetParent(B.Parent);
	
	for( i=0; i<B.TextureParameterValues.Length; ++i )
		if( B.TextureParameterValues[i].ParameterValue!=None )
			M.SetTextureParameterValue(B.TextureParameterValues[i].ParameterName,B.TextureParameterValues[i].ParameterValue);
	return M;
}

defaultproperties
{
   BaseRef=ObjectReferencer'tf2sentry.Arch.TurretObjList'
   NetUpdateFrequency=4.000000
   Name="Default__SentryMainRep"
   ObjectArchetype=ReplicationInfo'Engine.Default__ReplicationInfo'
}
