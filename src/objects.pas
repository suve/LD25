(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2017 Artur Iwicki
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License, version 3,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *)
unit objects;

{$INCLUDE defines.inc}

interface
	uses SysUtils, SDL2, Images;

Type
    TFacing = 0..1;
Const
	FACE_RIGHT = 0; FACE_LEFT = 1;

Type
	// Basic class for all in-game entities
	PEntity = ^TEntity;
	TEntity = Object
		Private
			fX, fY : Double;   // floating-point position
			intX, intY : sInt; // integer position
			mapX, mapY : sInt; // map (room) position

			Procedure Set_fX(newX:Double);
			Procedure Set_fY(newY:Double);
			Procedure Set_iX(newX:sInt);
			Procedure Set_iY(newY:sInt);
			Procedure Set_mX(newX:sInt);
			Procedure Set_mY(newY:sInt); // army of setters, duh

		Public
			Gfx : PImage;    // Pointer to a Sour Picture
			Col : PSDL_Colour;   // Pointer to a Sour Colour
			XVel, YVel : Double;  // X,Y velocity
			XCol, YCol : Boolean; // X,Y collision
			W, H : uInt;          // Width and height
			HP  : Double;         // Health points
			Enemy : Boolean;      // Team indicator
			Face : TFacing;       // Facing
			SfxID : sInt;         // Death SFX ID. <0 means none.
			SwitchNum : sInt;     // Switch to trigger on death

			Function GetCoords:TSDL_Point; // fart out an SDL Coordinate

			Property X:Double read fX write Set_fX;
			Property Y:Double read fY write Set_fY;
			Property iX:sInt read intX write Set_iX;
			Property iY:sInt read intY write Set_iY;
			Property mX:sInt read mapX write Set_mX;
			Property mY:sInt read mapY write Set_mY;

			Procedure Calculate(dt:uInt); Virtual;

			Constructor Create;
			Destructor Destroy; Virtual;
	end;

	// Bullet, duh
	PBullet = ^TBullet;
	TBullet = Object(TEntity)
		Public
			Power : Double;

			Constructor Create(Index:uInt);
			Destructor Destroy; Virtual;
	end;

	// Remains - after killing an enemy or dying
	PGib = ^TGib;
	TGib = Object(TEntity)
		Public
			Rect : TSDL_Rect;
			Constructor Create(pX,pY,pW,pH:uInt);
			Destructor Destroy; Virtual;
	end;

	// Player Object
	PPlayer = ^TPlayer;
	TPlayer = Object(TEntity)
		Public
			FireTimer : sInt;
			InvTimer  : sInt;
			MaxHP     : Double;
			FirePower : Double;
			InvLength : uInt;

			Procedure Calculate(dt:uInt); Virtual;

			Constructor Create;
			Destructor Destroy; Virtual;
	end;

	// Drone, a basic enemy
	PDrone = ^TDrone;
	TDrone = Object(TEntity)
		Private
			ChaseTime, IdleTime : uInt;
			Chase : Boolean;
			Timer : sInt;
		Public
			Procedure Calculate(dt:uInt); Virtual;

			Constructor Create;
			Destructor Destroy; Virtual;
	end;

	// Basher, another basic enemy
	PBasher = ^TBasher;
	TBasher = Object(TEntity)
		Private
			BashTime, IdleTime, AccelTime : uInt;
			Dir : uInt;
			Bash : Boolean;
			Timer : sInt;
		Public
			Procedure Calculate(dt:uInt); Virtual;

			Constructor Create;
			Destructor Destroy; Virtual;
	end;

	// Ball, yet another enemy
	PBall = ^TBall;
	TBall = Object(TEntity)
		Public
			Procedure Calculate(dt:uInt); Virtual;

			Constructor Create;
			Destructor Destroy; Virtual;
	end;

	// All right, let's try an enemy that can shoot
	PSpitter = ^TSpitter;
	TSpitter = Object(TEntity)
		Private
			MoveTime, IdleTime, FireInterval : uInt;
			FireTimer, MoveTimer : sInt;
			Move : Boolean;
		Public
			Procedure Calculate(dt:uInt); Virtual;

			Constructor Create;
			Destructor Destroy; Virtual;
	end;

	// An enemy that spams the map with bullets
	PSpammer = ^TSpammer;
	TSpammer = Object(TEntity)
		Private
			FireInterval : uInt;
			FireTimer, MoveTimer : sInt;
			Angle : Double;
		Public
			Procedure Calculate(dt:uInt); Virtual;

			Constructor Create;
			Destructor Destroy; Virtual;
	end;

	// Energy generator
	PGenerator = ^TGenerator;
	TGenerator = Object(TEntity)
		Private
			BigTimer,SmallTimer : sInt;
		Public
			Procedure Calculate(dt:uInt); Virtual;

			Constructor Create;
			Destructor Destroy; Virtual;
	end;

	// Turret, doh
	PTurret = ^TTurret;
	TTurret = Object(TEntity)
		Private
			NorTime,SpamTime : sInt;
		Public
			Procedure Calculate(dt:uInt); Virtual;

			Constructor Create;
			Destructor Destroy; Virtual;
	end;

implementation
	uses Shared;

Const
	TwoRoot = Sqrt(2);

Function RndInt(Val:sInt;Dif:Double):sInt;
Begin
	Exit(Trunc(Val*(1+Random(-1000,+1000)/1000*Dif)))
End;

Function RndDbl(Val,Dif:Double):Double;
Begin
	Exit(Val*(1+Random(-1000,+1000)/1000*Dif))
End;

Function TEntity.GetCoords:TSDL_Point
Begin
	Result.X := Self.intX;
	Result.Y := Self.intY
End;

Procedure TEntity.Set_fX(newX:Double);
Begin
	fX:=newX; intX:=Trunc(fX); mapX:=Trunc(fX / TILE_W)
End;

Procedure TEntity.Set_fY(newY:Double);
Begin
	fY:=newY; intY:=Trunc(fY); mapY:=Trunc(fY / TILE_H)
End;

Procedure TEntity.Set_iX(newX:sInt);
Begin
	fX:=newX; intX:=newX; mapX:=Trunc(fX / TILE_W)
End;

Procedure TEntity.Set_iY(newY:sInt);
Begin
	fY:=newY; intY:=newY; mapY:=Trunc(fY / TILE_H)
End;

Procedure TEntity.Set_mX(newX:sInt);
Begin
	mapX:=newX; iX:=newX*Tile_W; fX:=iX
End;

Procedure TEntity.Set_mY(newY:sInt);
Begin
	mapY:=newY; iY:=newY*Tile_H; fY:=iY
End;

Procedure TEntity.Calculate(dt:uInt);
Begin End; //By default, an entity does nothing

Constructor TEntity.Create();
Begin
	Set_fX(0); Set_fY(0);
	Gfx:=NIL; Col:=NIL;
	W:=TILE_W; H:=TILE_H;
	XCol:=False; YCol:=False;
	SfxID:=(-1); SwitchNum:=(-1)
End;

Destructor TEntity.Destroy();
Begin End;

Constructor TGib.Create(pX,pY,pW,pH:uInt);
Begin
	With Rect do begin
		X:=pX; Y:=pY; W:=pW; H:=pH
	end;
	Self.W:=pW; Self.H:=pH; HP:=3
End;

Destructor TGib.Destroy();
Begin 
	Inherited Destroy
End;

Constructor TBullet.Create(Index:uInt);
Begin
	Inherited Create();
	Gfx:=ShotGfx[Index];
	W:=Gfx^.W div 2; H:=Gfx^.H;
End;

Destructor TBullet.Destroy();
Begin
	Inherited Destroy();
End;

Procedure TPlayer.Calculate(dt:uInt);
Const
	FireInterval = 250;
Begin
	XVel:=0; YVel:=0;
	If (Key[KEY_UP   ]) then YVel-=HERO_SPEED;
	If (Key[KEY_DOWN ]) then YVel+=HERO_SPEED;
	If (Key[KEY_LEFT ]) then XVel-=HERO_SPEED;
	If (Key[KEY_RIGHT]) then XVel+=HERO_SPEED;
	If (XVel<>0) and (YVel<>0) then begin
		XVel/=TwoRoot; YVel/=TwoRoot
	end;
	
	If (FireTimer > 0) then
		FireTimer-=dt
	else begin
		If (Key[KEY_ShootLeft]) then begin
			Face:=FACE_LEFT; PlaySfx(SFX_SHOT+2);
			FireTimer:=FireInterval+FireTimer;
			PlaceBullet(@Self,(-2)*HERO_SPEED,0,FirePower,2)
		end else
		If (Key[KEY_ShootRight]) then begin
			FACE:=FACE_RIGHT; PlaySfx(SFX_SHOT+2);
			FireTimer:=FireInterval+FireTimer;
			PlaceBullet(@Self,(+2)*HERO_SPEED,0,FirePower,2)
		end
	end;
	If (InvTimer > 0) then InvTimer-=dt
End;

Constructor TPlayer.Create();
Begin
	Inherited Create();
	mX:=RespPos[GameMode].X; mY:=RespPos[GameMode].Y;
	Gfx:=CharaGfx[GFX_HERO];
	Col:=@GreyColour;
	MaxHP:=HERO_HEALTH; HP:=MaxHP;
	FirePower:=HERO_FIREPOWER; InvLength := HERO_INVUL;
	Enemy:=False
End;

Destructor TPlayer.Destroy();
Begin
	Inherited Destroy();
End;

Procedure TDrone.Calculate(dt:uInt);
Const
	Spd = TILE_S * 3;
Var
	Dist : Double;
Begin
	If (Timer > 0) then begin
		Timer-=dt;
		
		If (Chase) then begin
			If (XCol) then XVel:=-XVel;
			If (YCol) then YVel:=-YVel;
		end
	end else begin
		If (Chase) then begin
			Chase:=False; Timer:=IdleTime+Timer;
			XVel:=0; YVel:=0
		end else begin
			Chase:=True; Timer:=ChaseTime+Timer;
			GetDist(@Self,Hero,XVel,YVel,Dist);
			XVel:=XVel/Dist*Spd;
			YVel:=YVel/Dist*Spd
		end
	end
End;

Constructor TDrone.Create();
Begin 
	Inherited Create();
	Gfx:=CharaGfx[GFX_ENEM]; SfxID:=SFX_DIE+3;
	ChaseTime:=RndInt(800,0.2); IdleTime:=RndInt(200,0.2);
	Chase:=False; Timer:=IdleTime div 2;
	HP:=5.75; Enemy:=True
End;

Destructor TDrone.Destroy();
Begin
	Inherited Destroy();
End;

Procedure TBasher.Calculate(dt:uInt);
Const
	Spd = TILE_S * 8;
Var 
	XD,YD, Perc : Double;
Begin
	If (Timer > 0) then begin
		Timer-=dt;
		
		If (Bash) then begin
			If (XCol) or (YCol) then begin
				Case Dir of
					2: Dir:=8; {} 4: Dir:=6; {} 6: Dir:=4; {} 8: Dir:=2
				end
			end;
			
			If (Timer<AccelTime) then
				Perc:=(Timer/AccelTime) 
			else If (Timer>BashTime-AccelTime) then
				Perc:=((BashTime-Timer)/AccelTime)
			else
				Perc:=1;
			
			Case Dir of
				2: YVel:=(+Perc)*Spd; 8: YVel:=(-Perc)*Spd;
				4: XVel:=(-Perc)*Spd; 6: XVel:=(+Perc)*Spd
			end
		end
	end else begin
		If (Bash) then begin
			Bash:=False; Timer:=IdleTime+Timer;
			XVel:=0; YVel:=0
		end else begin
			Bash:=True; Timer:=BashTime+Timer;
			XD:=(Hero^.X-Self.X); YD:=(Hero^.Y-Self.Y);
			
			If (Abs(XD)>Abs(YD)) or (Random(4)=0) then
				if (XD>0) then Dir:=6 else Dir:=4
			else
				if (YD>0) then Dir:=2 else Dir:=8
		end
	end
End;

Constructor TBasher.Create();
Begin
	Inherited Create();
	Gfx:=CharaGfx[GFX_ENEM+3]; SfxID:=SFX_DIE+3;
	BashTime:=RndInt(1500,0.2); IdleTime:=RndInt(100,0.2);
	AccelTime:=(BashTime div 10);
	Bash:=False; Timer:=IdleTime;
	HP:=16; Enemy:=True
End;

Destructor TBasher.Destroy();
Begin
	Inherited Destroy();
End;

Procedure TBall.Calculate(dt:uInt);
Const
	Spd = TILE_S / 6;
Var
	Dist : Double;
Begin
	If (XCol) then XVel:=-XVel;
	If (YCol) then YVel:=-YVel;
	Dist:=Hypotenuse(@Self,Hero);
	XVel+=(Hero^.X-Self.X)/Dist*Spd;
	YVel+=(Hero^.Y-Self.Y)/Dist*Spd;
End;

Constructor TBall.Create();
Begin
	Inherited Create();
	Gfx:=CharaGfx[GFX_ENEM+2]; SfxID:=SFX_DIE+2;
	HP:=9.75; Enemy:=True
End;

Destructor TBall.Destroy();
Begin
	Inherited Destroy();
End;

Procedure TSpitter.Calculate(dt:uInt);
Const
	Spd = TILE_S * 2.4;
Var
	Dist : Double;
Begin
	If (FireTimer > 0) then
		FireTimer-=dt
	else begin
		PlaySfx(SFX_SHOT);
		FireTimer:=FireInterval+FireTimer;
		PlaceBullet(@Self,Sgn(Hero^.X-Self.X)*TILE_S*4,0,5,0)
	end;
	
	If (MoveTimer > 0) then begin
		MoveTimer-=dt;
		If (Move) then begin
			If (XCol) then XVel:=-XVel;
			If (YCol) then YVel:=-YVel;
		end
	end else begin
		If (Move) then begin
			Move:=False; MoveTimer:=IdleTime+MoveTimer;
			XVel:=0; YVel:=0
		end else begin
			Move:=True; MoveTimer:=MoveTime+MoveTimer;
			GetDist(@Self,Hero,XVel,YVel,Dist);
			XVel:=XVel/Dist*Spd;
			YVel:=YVel/Dist*Spd
		end
	end
End;

Constructor TSpitter.Create();
Begin
	Inherited Create();
	Gfx:=CharaGfx[GFX_ENEM+1]; SfxID:=SFX_DIE+4;
	MoveTime:=RndInt(444,0.2); IdleTime:=RndInt(100,0.2); FireInterval:=RndInt(1200,0.2);
	Move:=False; MoveTimer:=IdleTime; FireTimer:=(FireInterval * 5) div 6;
	HP:=12; Enemy:=True
End;

Destructor TSpitter.Destroy();
Begin
	Inherited Destroy();
End;

Procedure TSpammer.Calculate(dt:uInt);
Const
	MoveMin = 500; MoveMax = 700;
	Spd = TILE_S * 1.5;
Begin
	If (FireTimer > 0) then
		FireTimer-=dt
	else begin
		PlaySfx(SFX_SHOT+1);
		FireTimer:=FireInterval+FireTimer;
		PlaceBullet(@Self,TILE_S*(+6),0,5,0); PlaceBullet(@Self,TILE_S*(-6),0,5,0);
		PlaceBullet(@Self,0,TILE_S*(+6),5,0); PlaceBullet(@Self,0,TILE_S*(-6),5,0);
	end;
	
	If (MoveTimer > 0) then begin
		MoveTimer-=dt;
		If (XCol) then XVel:=-XVel;
		If (YCol) then YVel:=-YVel;
	end else begin
		MoveTimer:=Random(MoveMin,MoveMax)+MoveTimer;
		Angle+=(Random(2001)-1000)*Pi/2000;
		XVel:=Cos(Angle)*Spd;
		YVel:=Sin(Angle)*Spd
	end
End;

Constructor TSpammer.Create();
Begin
	Inherited Create();
	Gfx:=CharaGfx[GFX_ENEM+4]; SfxID:=SFX_DIE+4;
	FireInterval:=RndInt(800,0.2);
	MoveTimer:=Random(100,333); FireTimer:=(FireInterval*10) div 8;
	Angle:=Random(2000)*Pi/1000;
	HP:=18; Enemy:=True
End;

Destructor TSpammer.Destroy();
Begin 
	Inherited Destroy();
End;

Procedure TGenerator.Calculate(dt:uInt);
Const
	BigTimerMin = 1500; BigTimerMax = 2500;
	SmaTimerMin = 700;  SmaTimerMax = 1000;
	BigSpd = HERO_SPEED * 1.75;
	SmaSpd = HERO_SPEED * 1.25;
	SmaNum = 5;
Var
	Angle,Dist,XV,YV:Double; BulNum:uInt;
Begin
	If (BigTimer > 0) then 
		BigTimer-=dt 
	else begin
		BigTimer:=Random(BigTimerMin,BigTimerMax)+BigTimer;
		GetDist(@Self,Hero,XV,YV,Dist);
		XV:=XV/Dist*BigSpd; YV:=YV/Dist*BigSpd;
		
		PlaceBullet(@Self,XV,YV,12,4);
		If (Random(2)=0) then
			PlaceBullet(@Self,XV*1.1,YV/1.1,12,4)
		else
			PlaceBullet(@Self,XV/1.1,YV*1.1,12,4);
	end;
	
	If (SmallTimer > 0) then
		SmallTimer-=dt
	else begin
		SmallTimer:=Random(SmaTimerMin,SmaTimerMax)+SmallTimer;
		For BulNum:=1 to SmaNum do begin
			Angle:=Random(-450,450)*Pi/1800;
			If (Hero^.X<Self.X) then Angle+=Pi;
			PlaceBullet(@Self,Cos(Angle)*SmaSpd,Sin(Angle)*SmaSpd,4,3)
		end
	end;
End;

Constructor TGenerator.Create();
Begin
	Inherited Create();
	Gfx:=CharaGfx[GFX_ENEM+5]; SfxID:=SFX_DIE+0;
	BigTimer:=2000; SmallTimer:=2000;
	HP:=64; Enemy:=True
End;

Destructor TGenerator.Destroy();
Begin
	Inherited Destroy();
End;

Procedure TTurret.Calculate(dt:uInt);
Const
	NorTimerMin = 400; NorTimerMax = 480;
	//SpamTimerMin = 3000; SpamTimerMax = 4000;
	NorSpd = HERO_SPEED * 0.8;
	//SpamSpd = HERO_SPEED * 1.2;
	//SpamNum = 8;
Var
	Dist,XV,YV:Double; //Angle:Double; BulNum:uInt;
Begin
	If (NorTime > 0) then 
		NorTime-=dt
	else begin
		NorTime:=Random(NorTimerMin,NorTimerMax)+NorTime;
		GetDist(@Self,Hero,XV,YV,Dist);
		XV:=XV/Dist*NorSpd; YV:=YV/Dist*NorSpd;
		PlaceBullet(@Self,XV,YV,3,3)
	end;

	{If (SpamTime > 0) then
		SpamTime-=dt 
	else begin
		SpamTime:=Random(SpamTimerMin,SpamTimerMax)+SpamTime;
		For BulNum:=1 to SpamNum do begin
			Angle:=Random(-500,500)*Pi/1800;
			If (Hero^.X<Self.X) then Angle+=Pi;
			PlaceBullet(@Self,Cos(Angle)*SpamSpd,Sin(Angle)*SpamSpd,4,0)
		end
	end;}
End;

Constructor TTurret.Create();
Begin
	Inherited Create();
	Gfx:=CharaGfx[GFX_ENEM+6]; SfxID:=SFX_DIE+5;
	NorTime:=1000; SpamTime:=1800;
	HP:=27; Enemy:=True
End;

Destructor TTurret.Destroy();
Begin
	Inherited Destroy();
End;

End.

