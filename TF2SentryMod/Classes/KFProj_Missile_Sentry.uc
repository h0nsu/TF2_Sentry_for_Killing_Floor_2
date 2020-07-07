class KFProj_Missile_Sentry extends KFProj_Missile_Patriarch;

var Pawn AimTarget;

replication
{
	// Variables the server should send ALL clients.
	if( true )
		AimTarget;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(0.05,true,'CheckHeading');
}

simulated function CheckHeading()
{
	local vector X,Y,Z;
	local float Dist;
	
	if( AimTarget==None || AimTarget.Health<=0 )
	{
		AimTarget = None;
		ClearTimer('CheckHeading');
		return;
	}
	X = (AimTarget.Location-Location);
	Dist = VSize(X);
	X = X / FMax(Dist,0.1);
	if( !FastTrace(AimTarget.Location,Location) )
	{
		// Check if we can curve to one direction to avoid hitting wall.
		Y = Normal(X Cross vect(0,0,1));
		Z = X Cross Y;
	
		if( !TestDirection(X,Z,Dist) && !TestDirection(X,-Z,Dist) && !TestDirection(X,Y,Dist) )
			TestDirection(X,-Y,Dist);
	}
	
	Y = Normal(Velocity);
	if( (Y Dot X)>0.99 )
		Y = X;
	else Y = Normal(Y+X*0.1);
	Velocity = Y*Speed;
	SetRotation(rotator(Velocity));
}

simulated final function bool TestDirection( out vector Aim, vector TestAxis, float Dist )
{
	local vector V;

	// Test with a ~35 degrees angle arc.
	V = Location+Aim*(Dist*0.5)+TestAxis*0.22;
	if( FastTrace(V,Location) && FastTrace(AimTarget.Location,V) )
	{
		Aim = Normal(V-Location);
		return true;
	}
	if( Dist>1500.f ) // Test with a small arc.
	{
		V = Location+Aim*(Dist*0.5)+TestAxis*200.f;
		if( FastTrace(V,Location) && FastTrace(AimTarget.Location,V) )
		{
			Aim = Normal(V-Location);
			return true;
		}
	}
	return false;
}

simulated event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if( KFPawn(Other)!=None && KFPawn(Other).GetTeamNum()==0 )
		return;
	Super.Touch(Other, OtherComp, HitLocation, HitNormal);
}

defaultproperties
{
   Begin Object Name=FlightPointLight
      Radius=120.000000
      FalloffExponent=10.000000
      Brightness=1.500000
      LightColor=(B=255,G=20,R=95,A=255)
      CastShadows=False
      CastStaticShadows=False
      CastDynamicShadows=False
      LightingChannels=(Outdoor=True)      
   End Object
   FlightLight=FlightPointLight
   Begin Object Name=ExploTemplate0
      ExplosionEffects=KFImpactEffectInfo'WEP_Patriarch_ARCH.Missile_Explosion'
      Damage=1000.000000
      DamageRadius=750.000000
      DamageFalloffExponent=2.000000
      ActorClassToIgnoreForDamage=Class'KFGame.KFPawn_Human'
      MyDamageType=Class'kfgamecontent.KFDT_Explosive_PatMissile'
      ExplosionSound=AkEvent'WW_WEP_SA_RPG7.Play_WEP_SA_RPG7_Explosion'      
      ExploLightFadeOutTime=0.500000
      CamShake=KFCameraShake'FX_CameraShake_Arch.Grenades.Default_Grenade'
      CamShakeInnerRadius=200.000000
      CamShakeOuterRadius=700.000000      
   End Object
   ExplosionTemplate=KFGameExplosion'tf2sentrymod.Default__KFProj_Missile_Sentry:ExploTemplate0'
   Begin Object Name=AmbientAkSoundComponent
      bStopWhenOwnerDestroyed=True
      bForceOcclusionUpdateInterval=True
      OcclusionUpdateInterval=0.100000      
   End Object
   AmbientComponent=AmbientAkSoundComponent
   Damage=1000.000000
   Begin Object Name=CollisionCylinder
      CollisionHeight=5.000000
      CollisionRadius=5.000000
      ReplacementPrimitive=None
      CollideActors=True
      BlockNonZeroExtent=False
   End Object
   CylinderComponent=CollisionCylinder
   Components(0)=CollisionCylinder
   Components(1)=FlightPointLight
   Components(2)=AmbientAkSoundComponent
   CollisionComponent=CollisionCylinder
}
