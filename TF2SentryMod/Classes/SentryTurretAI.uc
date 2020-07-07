Class SentryTurretAI extends AIController;

var SentryTurret TPawn;
var vector LastAliveSpot;

function InitPlayerReplicationInfo()
{
	if( PlayerReplicationInfo==None )
		PlayerReplicationInfo = Spawn(class'KFDummyReplicationInfo', self,, vect(0,0,0),rot(0,0,0));
	PlayerReplicationInfo.PlayerName = "TF2Sentry";
	if( WorldInfo.GRI!=None && WorldInfo.GRI.Teams.Length>0 )
		PlayerReplicationInfo.Team = WorldInfo.GRI.Teams[0];
}

event Destroyed()
{
	if ( PlayerReplicationInfo!=None )
		CleanupPRI();
}

function Restart(bool bVehicleTransition)
{
	TPawn = SentryTurret(Pawn);
	Enemy = None;
	InitPlayerReplicationInfo();

	GoToState('WaitForEnemy');
}

event SeePlayer( Pawn Seen )
{
	SetEnemy(Seen);
}
event SeeMonster( Pawn Seen )
{
	SetEnemy(Seen);
}
event HearNoise( float Loudness, Actor NoiseMaker, optional Name NoiseType )
{
	if( NoiseMaker!=None && NoiseMaker.Instigator!=None )
		SetEnemy(NoiseMaker.Instigator);
}
function NotifyTakeHit(Controller InstigatedBy, vector HitLocation, int Damage, class<DamageType> damageType, vector Momentum)
{
	if( InstigatedBy!=None && InstigatedBy.Pawn!=None )
		SetEnemy(InstigatedBy.Pawn);
}
function bool SetEnemy( Pawn Other )
{
	if( TPawn.BuildTimer>WorldInfo.TimeSeconds || Other==None || Other==Enemy || !Other.IsAliveAndWell() || Other.IsSameTeam(Pawn) || !Other.CanAITargetThisPawn(Self) || !CanSeeSpot(Other.Location) )
		return false;
	
	Enemy = Other;
	LastAliveSpot = Other.Location;
	EnemyChanged();
	return true;
}

function Rotator GetAdjustedAimFor( Weapon W, vector StartFireLoc )
{
	if( Enemy!=None && CanSeeSpot(Enemy.Location,true) )
		return rotator(TPawn.GetAimPos(StartFireLoc,Enemy)-StartFireLoc);
	return Super.GetAdjustedAimFor(W,StartFireLoc);
}

final function bool CanSeeSpot( vector P, optional bool bSkipTrace )
{
	return VSizeSq(P-Pawn.Location)<Square(Pawn.SightRadius) && (Normal(P-Pawn.Location) Dot vector(Pawn.Rotation))>0.6 && (bSkipTrace || FastTrace(P,TPawn.GetTraceStart()));
}

function EnemyChanged();

final function FindNextEnemy()
{
	local KFPawn M,Best;
	local byte i;
	local float Dist,BestDist;
	
	foreach WorldInfo.AllPawns(class'KFPawn',M,Pawn.Location,Pawn.SightRadius)
	{
		if( Global.SetEnemy(M) )
		{
			if( M.Controller!=None )
				M.Controller.SeePlayer(Pawn);

			// Pick closest enemy.
			Dist = VSizeSq(M.Location-Pawn.Location)*(0.8+FRand()*0.4);
			if( Best==None || Dist<BestDist )
			{
				Best = M;
				BestDist = Dist;
			}
		}
		if( ++i>100 )
			break;
	}
	if( Best!=None )
		Enemy = Best;
}

state WaitForEnemy
{
	function BeginState( name OldState )
	{
		Enemy = None;
		TPawn.SetViewFocus(None);
	}
	function EnemyChanged()
	{
		GoToState('FightEnemy');
	}
Begin:
	while( true )
	{
		Sleep(0.25+FRand()*0.75);
		FindNextEnemy();
	}
}
state FightEnemy
{
	function BeginState( name OldState )
	{
		TPawn.PlaySoundBase(SoundCue'tf2sentry.Sounds.sentry_spot_Cue');
		TPawn.SetTimer(0.18,false,'DelayedStartFire');
		TPawn.SetViewFocus(Enemy);
		SetTimer(0.1,true);
	}
	function EndState( name NewState )
	{
		if( TPawn!=None )
			TPawn.TurretSetFiring(false);
		SetTimer(0.f,false);
	}
	function EnemyChanged()
	{
		TPawn.SetViewFocus(Enemy);
	}
	function bool SetEnemy( Pawn Other )
	{
		if( Enemy!=None )
		{
			if( Enemy.IsAliveAndWell() )
				return false;
			Enemy = None;
		}
		return Global.SetEnemy(Other);
	}
	function Timer()
	{
		if( Enemy==None || !Enemy.IsAliveAndWell() || !CanSeeSpot(Enemy.Location) )
		{
			Enemy = None;
			FindNextEnemy();
			if( Enemy==None )
				GoToState('WaitForEnemy');
		}
		else LastAliveSpot = Enemy.Location;
	}
}

defaultproperties
{
   Name="Default__SentryTurretAI"
   ObjectArchetype=AIController'Engine.Default__AIController'
}
