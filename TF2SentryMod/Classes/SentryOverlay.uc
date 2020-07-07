Class SentryOverlay extends Interaction;

var array<SentryTurret> ActiveTurrets;
var PlayerController LocalPC;
var FontRenderInfo DrawInfo;
var color OwnerColor,OtherColor;

var transient vector CamLocation,XDir;
var transient rotator CamRotation;
var transient float XL,YL,ZDepth;

static final function SentryOverlay GetOverlay( PlayerController PC )
{
	local Interaction I;
	local SentryOverlay S;

	foreach PC.Interactions(I)
	{
		S = SentryOverlay(I);
		if( S!=None )
			return S;
	}
	S = new (PC) class'SentryOverlay';
	S.LocalPC = PC;
	PC.Interactions.AddItem(S);
	S.Init();
	return S;
}
event PostRender(Canvas Canvas)
{
	local float FontScale,ZDist,Scale;
	local SentryWeapon W;
	local SentryTurret S;
	local vector V;
	local string Str;

	if( LocalPC==None || LocalPC.Pawn==None )
		return;

	LocalPC.GetPlayerViewPoint(CamLocation,CamRotation);
	XDir = vector(CamRotation);
	ZDepth = CamLocation Dot XDir;

	FontScale = class'KFGameEngine'.Static.GetKFFontScale();
	Canvas.Font = class'KFGameEngine'.Static.GetKFCanvasFont();
	
	W = SentryWeapon(LocalPC.Pawn.Weapon);
	if( W!=None )
		W.DrawInfo(Canvas,FontScale);
	
	foreach ActiveTurrets(S)
	{
		if( S.Health<=0 ) // Filter by dead.
			continue;
		V = S.Location+vect(0,0,70);
		ZDist = (V Dot XDir) - ZDepth;
		if( ZDist<1.f || ZDist>1000.f ) // Filter by distance.
			continue;
		V = Canvas.Project(V);
		if( V.X<0.f || V.Y<0.f || V.X>Canvas.ClipX || V.Y>Canvas.ClipY ) // Filter by screen bounds.
			continue;
		
		Scale = FontScale * 2.f * (1.f - ZDist/1000.f); // Linear scale font size by distance.

		Canvas.DrawColor = (S.PlayerReplicationInfo==LocalPC.PlayerReplicationInfo) ? OwnerColor : OtherColor;
		Str = S.GetInfo();
		Canvas.TextSize(Str,XL,YL,Scale,Scale);
		Canvas.SetPos(V.X-(XL*0.5),V.Y-(YL*0.5),0.25f/(ZDist+1.f));
		Canvas.DrawText(Str,,Scale,Scale,DrawInfo);
		
		if( ZDist<600.f )
		{
			V.Y+=YL;
			Str = S.GetAmmoStatus();
			Canvas.TextSize(Str,XL,YL,Scale,Scale);
			Canvas.SetPos(V.X-(XL*0.5),V.Y-(YL*0.5),Canvas.CurZ);
			Canvas.DrawText(Str,,Scale,Scale,DrawInfo);
		}
		
		if( ZDist<100.f )
		{
			V.Y+=(YL*0.5);
			Str = "[Use] for options";
			Scale*=0.75;
			Canvas.TextSize(Str,XL,YL,Scale,Scale);
			Canvas.SetPos(V.X-(XL*0.5),V.Y,Canvas.CurZ);
			Canvas.DrawText(Str,,Scale,Scale,DrawInfo);
		}
	}
}

defaultproperties
{
   DrawInfo=(bClipText=True,bEnableShadow=True,GlowInfo=(GlowColor=(R=0.000000,G=0.000000,B=0.000000,A=1.000000)))
   OwnerColor=(B=48,G=255,R=48,A=255)
   OtherColor=(B=48,G=200,R=255,A=255)
   Name="Default__SentryOverlay"
   ObjectArchetype=Interaction'Engine.Default__Interaction'
}
