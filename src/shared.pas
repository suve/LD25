(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2024 suve (a.k.a. Artur Frenszek Iwicki)
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
Unit Shared; 

{$INCLUDE defines.inc}


Interface
Uses
	SysUtils,
	SDL2, SDL2_mixer,
	Buffers, Entities, Sprites;


// A shitload of constants - but hey, this is the 'shared' unit, isn't it?
const 
	GAMENAME = 'Colorful'; GAMEAUTH = 'suve';
	MAJORNUM = '2'; MINORNUM = '1'; GAMEVERS = MAJORNUM+'.'+MINORNUM;

	FPS_LIMIT = 120; TICKS_MINIMUM = 1000 div FPS_LIMIT;

	TILE_W = 16; TILE_H = 16; TILE_S = ((TILE_W + TILE_H) div 2);
	ROOM_W = 20; ROOM_H = 20;
	SWITCHES = 100;

	GIBS_PIECES_X = 4;
	GIBS_PIECES_Y = 4;
	GIBS_PIECES_TOTAL = (GIBS_PIECES_X * GIBS_PIECES_Y);

Type
	TGameMode = (GM_TUTORIAL, GM_ORIGINAL);

Const
	RespRoom:Array[TGameMode] of TSDL_Point = ((X:0; Y:0), (X:3; Y:3));
	RespPos:Array[TGameMode] of TSDL_Point = ((X:1; Y:3), (X:10; Y:6));

	HERO_SPEED = TILE_S * 5; HERO_HEALTH = 50; HERO_FIREPOWER = 5; HERO_INVUL = 500;

	AUDIO_FREQ = 22050; AUDIO_TYPE = AUDIO_S16; AUDIO_CHAN = 2; AUDIO_CSIZ = 2048;
	SFXCHANNELS = 32;

	DeathLength = 2500; WOMAN = 8;

Const
	VOL_LEVEL_MAX = 6;
Type
	TVolLevel = 0..VOL_LEVEL_MAX;

Type
	TPlayerKey = (
		KEY_UP, KEY_RIGHT, KEY_DOWN, KEY_LEFT,
		KEY_SHOOTLEFT, KEY_SHOOTRIGHT,
		KEY_PAUSE, KEY_VOLDOWN, KEY_VOLUP
	);
	TEnemyType = (
		ENEM_DRONE, ENEM_BASHER, ENEM_BALL, ENEM_SPITTER, ENEM_SPAMMER,
		ENEM_SNEK,
		ENEM_GENERATOR, ENEM_TURRET
	);
	TColState = (
		STATE_NONE, STATE_PICKED, STATE_GIVEN
	);
	TCrystal = record
		IsSet : Boolean;
		mX, mY: sInt;
		Col : uInt
	end;

// Progstate and gamestate variables. This isn't a project big enough to actually
// require having a separate game controller class. I'll just keep everything global...

Var 
	Ev: TSDL_Event;    // For retrieving SDL events
	Hero: PPlayer;

Type
	TBulletBuffer = specialize GenericBuffer<PBullet>;
	TEnemyBuffer = specialize GenericBuffer<PEnemy>;
	TGibBuffer = specialize GenericBuffer<PGib>;

Var
	PlayerBullets, EnemyBullets: TBulletBuffer;
	Mobs: TEnemyBuffer;
	Gibs: TGibBuffer;

	Key     : Array[TPlayerKey] of Boolean;
	KeyBind :Array[TPlayerKey] of TSDL_Keycode; //Playa controls

	GameOn : Boolean; // Is a game in progress?
	GameMode : TGameMode; // Current game mode
	Switch : Array[0..SWITCHES-1] of Boolean;
	ColState : Array[0..7] of TColState;
	Crystal : TCrystal;
	PaletteColour : Array[0..7] of TSDL_Colour;
	CentralPalette : Array[0..7] of TSDL_Colour;
	RoomPalette, DeadTime, Carried, Given : sInt;
	// Gamestate variables

	SaveExists : Array[TGameMode] of Boolean;
	Shutdown, NoSound : Boolean;

// The name is obvious, duh
Procedure GetDeltaTime(Out Time:uInt);
Procedure GetDeltaTime(Out Time,Ticks:uInt);

// Mainly used in initialization, as we later switch to SDL ticks
Function GetTimeStamp(): TTimeStamp;
Function TimestampDiffMillis(Const First, Second: TTimeStamp): sInt;

// Draw primitives using SDL
Procedure DrawRectFilled(Const Rect: PSDL_Rect; Const Colour: PSDL_Colour);
Procedure DrawRectFilled(Const Rect: PSDL_Rect; Const RGB: LongWord);
Procedure DrawRectOutline(Const Rect: PSDL_Rect; Const Colour: PSDL_Colour);
Procedure DrawRectOutline(Const Rect: PSDL_Rect; Const RGB: LongWord);

// Some simple converstions from and to strings
Function IntToStr(Num:uInt;Digits:uInt=0;Chr:Char='0'):AnsiString; Overload;
Function StrToInt(S:AnsiString):Int64;

// Volume functions
Procedure ChgVol(Change:sInt; ChangeChannelsVolume: Boolean = TRUE);
Procedure SetVol(NewVol:TVolLevel; ChangeChannelsVolume: Boolean = TRUE);
Function  GetVol:TVolLevel;

// Play a sound
Procedure PlaySfx(ID:uInt);

// Place a bullet, duh
Procedure PlaceBullet(Owner:PEntity; XVel, YVel, Power:Double; Sprite: PSprite);

// Spawn enemies
Procedure SpawnEnemy(Tp:TEnemyType;mapX,mapY:sInt;SwitchNum:sInt=-1);

// Someone got killed - place gibs!
Procedure PlaceGibs(Const E: PEntity; Const Frame: TSDL_Rect);

// Change current room
Function ChangeRoom(NX,NY:sInt):Boolean;

// Used in new game, load game and change room.
Procedure DestroyEntities(KillHero:Boolean=FALSE);
Procedure ResetGamestate();

// Convenience function for reducing the amount of copy-pasted code.
Procedure SaveCurrentGame(Reason: AnsiString = '');


Implementation
Uses
	Assets, Colours, ConfigFiles, FloatingText, Rendering, Rooms;

Var
	Tikku : uInt;
	VolLevel : TVolLevel;
	Volume : uInt;

Procedure GetDeltaTime(Out Time:uInt);
Begin
	While ((SDL_GetTicks() - Tikku) < TICKS_MINIMUM) do SDL_Delay(1);
	
	Time:=(SDL_GetTicks() - Tikku);
	Tikku+=Time
End;

Procedure GetDeltaTime(Out Time,Ticks:uInt);
Begin
	While ((SDL_GetTicks() - Tikku) < TICKS_MINIMUM) do SDL_Delay(1);
	
	Time:=(SDL_GetTicks - Tikku);
	Tikku += Time;
	Ticks := Tikku
End;

Function GetTimeStamp(): TTimeStamp;
Begin
	Result := DateTimeToTimeStamp(Now())
End;

Function TimestampDiffMillis(Const First, Second: TTimeStamp): sInt;
Var
	Diff: Comp;
Begin
	Diff := TimeStampToMSecs(Second) - TimeStampToMSecs(First);
	{$IFDEF CPUI386}
		(*
		 * On i386, the Comp type cannot be cast to an sInt, resulting in a compilation error.
		 * As a (rather dirty) workaround, force a cast to a floating-point value and then cast back to integer.
		 *)
		Result := Trunc(Extended(Diff))
	{$ELSE}
		Result := sInt(Diff)
	{$ENDIF}
End;

Procedure DrawRectFilled(Const Rect: PSDL_Rect; Const Colour: PSDL_Colour);
Begin
	SDL_SetRenderDrawColor(Renderer, Colour^.R, Colour^.G, Colour^.B, Colour^.A);
	SDL_RenderFillRect(Renderer, Rect)
End;

Procedure DrawRectFilled(Const Rect: PSDL_Rect; Const RGB: LongWord);
Var
	Colour: TSDL_Colour;
Begin
	Colour := RGBToColour(RGB);
	DrawRectFilled(Rect, @Colour)
End;

Procedure DrawRectOutline(Const Rect: PSDL_Rect; Const Colour: PSDL_Colour);
Begin
	SDL_SetRenderDrawColor(Renderer, Colour^.R, Colour^.G, Colour^.B, Colour^.A);
	SDL_RenderDrawRect(Renderer, Rect)
End;

Procedure DrawRectOutline(Const Rect: PSDL_Rect; Const RGB: LongWord);
Var
	Colour: TSDL_Colour;
Begin
	Colour := RGBToColour(RGB);
	DrawRectOutline(Rect, @Colour)
End;


Function IntToStr(Num:uInt;Digits:uInt=0;Chr:Char='0'):AnsiString;
   Var Res:AnsiString;
   begin
   WriteStr(Res,Num);
   If (Length(Res)<Digits) then Res:=StringOfChar(Chr,Digits-Length(Res))+Res;
   Exit(Res)
   end;

Function StrToInt(S:AnsiString):Int64;
   Var P:uInt; R:Int64;
   begin
   R:=0; If (Length(S) = 0) then Exit(0);
   For P:=1 to Length(S) do
      If (S[P]>=#48) and (S[P]<=#57) then R:=(R*10)+(Ord(S[P])-48);
   If (S[1]<>'-') then Exit(R) else Exit(-R)
   end;

Procedure ChgVol(Change:sInt; ChangeChannelsVolume:Boolean = TRUE);
Begin
	Change += VolLevel;
	If(Change < 0) then
		SetVol(0, ChangeChannelsVolume)
	else If(Change > VOL_LEVEL_MAX) then
		SetVol(VOL_LEVEL_MAX, ChangeChannelsVolume)
	else
		SetVol(TVolLevel(Change), ChangeChannelsVolume)
end;

Procedure SetVol(NewVol:TVolLevel;ChangeChannelsVolume:Boolean = TRUE);
Begin
	VolLevel:=NewVol;
	Volume:=Trunc(VolLevel * MIX_MAX_VOLUME / VOL_LEVEL_MAX);

	// Passing -1 as channel number changes volume of all channels
	If (Not NoSound) and (ChangeChannelsVolume) then Mix_Volume(-1, Volume)
end;

Function GetVol:TVolLevel;
Begin
	Result := VolLevel
End;

Procedure PlaySfx(ID:uInt);
   Var Chan:sInt;
   begin
   If (NoSound) or (ID>=SOUNDS) then Exit;
   Chan:=Mix_PlayChannel(-1, Sfx[ID], 0);
   If (Chan < 0) then Exit;
   Mix_Volume(Chan, Volume)
   end;

Procedure PlaceBullet(Owner:PEntity; XVel, YVel, Power:Double; Sprite: PSprite);
Var
	B:PBullet;
Begin
	New(B,Create(Sprite));
	B^.X := Owner^.X+(Owner^.W / 2);
	B^.Y := Owner^.Y+(Owner^.H / 2);
	B^.XVel := XVel;
	B^.YVel := YVel;
	B^.Power := Power;
	B^.HP := Power;
	B^.Col := Owner^.Col;

	If (Owner <> PEntity(Hero)) then begin
		If ((EnemyBullets.GetCount() mod 256) = 0) then EnemyBullets.Compact();
		EnemyBullets.Append(B)
	end else begin
		If ((PlayerBullets.GetCount() mod 256) = 0) then PlayerBullets.Compact();
		PlayerBullets.Append(B)
	end;
End;

Procedure SpawnEnemy(Tp: TEnemyType; mapX, mapY:sInt; SwitchNum: sInt = -1);
Var
	Dron: PDrone;
	Bash: PBasher;
	Ball: PBall;
	Spit: PSpitter;
	Spam: PSpammer;
	Gene: PGenerator;
	Turr: PTurret;
	E: PEnemy;
Begin
	If (mapX<0) or (mapY<0) or (mapX>=ROOM_W) or (mapY>=ROOM_H) then Exit;

	Case Tp of
		ENEM_DRONE:     begin New(Dron,Create()); E:=Dron end;
		ENEM_BASHER:    begin New(Bash,Create()); E:=Bash end;
		ENEM_BALL:      begin New(Ball,Create()); E:=Ball end;
		ENEM_SPITTER:   begin New(Spit,Create()); E:=Spit end;
		ENEM_SPAMMER:   begin New(Spam,Create()); E:=Spam end;
		ENEM_GENERATOR: begin New(Gene,Create()); E:=Gene end;
		ENEM_TURRET:    begin New(Turr,Create()); E:=Turr end;
		otherwise Exit()
	end;

	E^.mX:=mapX; E^.mY:=mapY; E^.SwitchNum:=SwitchNum;
	If (RoomPalette < 8) then E^.Col:=@PaletteColour[RoomPalette];

	Mobs.Append(E)
End;

Procedure PlaceGibs(Const E: PEntity; Const Frame: TSDL_Rect);
Const
	GIB_SPEED = TILE_S*8;
Var
	X, Y, W, H: uInt;
	Angle: Double;
	G: PGib;
begin
	W := Frame.W div GIBS_PIECES_X;
	H := Frame.H div GIBS_PIECES_Y;
	For Y:=0 to (GIBS_PIECES_Y-1) do
		For X:=0 to (GIBS_PIECES_X-1) do begin
			New(G, Create(Frame.X + (X*W), Frame.Y + (Y*H), W, H));

			G^.X := E^.X+(X*W);
			G^.Y := E^.Y+(Y*H);
			Angle:=Random(3600)*Pi/1800;
			G^.XVel := Cos(Angle) * GIB_SPEED;
			G^.YVel := Sin(Angle) * GIB_SPEED;
			G^.Col := E^.Col;

			Gibs.Append(G)
		end
end;

Function ChangeRoom(NX,NY:sInt):Boolean;
Var
	NoRoom:Boolean;
	ErrStr: AnsiString;
Begin
	// First, check if room exists
	Case GameMode of
		GM_TUTORIAL: NoRoom:=(NX<0) or (NY<0) or (NX>=TUT_MAP_W) or (NY>=TUT_MAP_H) or (TutRoom[NX][NY]=NIL);
		GM_ORIGINAL: NoRoom:=(NX<0) or (NY<0) or (NX>=ORG_MAP_W) or (NY>=ORG_MAP_H) or (OrgRoom[NX][NY]=NIL);
		otherwise Exit(False)
	end;
	If (NoRoom) then begin
		WriteStr(ErrStr, 'Room ',GameMode,':',NX,':',NY,' not found!');
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, '%s', [PChar(ErrStr)]);
		Exit(False)
	end;

	DestroyEntities();

	// Change room and run its script
	Case GameMode of
		GM_TUTORIAL: Room:=TutRoom[NX][NY];
		GM_ORIGINAL: Room:=OrgRoom[NX][NY];
	end;
	Room^.RunScript();

	If (GameMode=GM_TUTORIAL) then Hero^.HP:=Hero^.MaxHP;
	Exit(True)
end;

Procedure FreeBullet(B: PBullet);
Begin
	Dispose(B, Destroy())
End;

Procedure FreeEnemy(E: PEnemy);
Begin
	Dispose(E, Destroy())
End;

Procedure FreeGib(G: PGib);
Begin
	Dispose(G, Destroy())
End;

Procedure DestroyEntities(KillHero:Boolean=FALSE);
begin
	PlayerBullets.Flush(@FreeBullet);
	EnemyBullets.Flush(@FreeBullet);
	Mobs.Flush(@FreeEnemy);
	Gibs.Flush(@FreeGib);

	FlushFloatTxt();
	Crystal.IsSet:=False;

	If (KillHero) then begin
		If (Hero<>NIL) then Dispose(Hero,Destroy());
		Hero:=NIL
	end
end;

Procedure ResetGamestate();
Var C:sInt;
Begin
	For C:=0 to 7 do PaletteColour[C]:=MapColour[C];

	For C:=0 to 7 do begin
		CentralPalette[C].R := 127;
		CentralPalette[C].G := 127;
		CentralPalette[C].B := 127
	end;

	For C:=Low(ColState) to High(ColState) do ColState[C]:=STATE_NONE;
	For C:=Low(Switch) to High(Switch) do Switch[C]:=False;

	Carried:=0; Given:=0;
End;

Procedure SaveCurrentGame(Reason: AnsiString = '');
Begin
	If Not GameOn then Exit;

	If (Reason <> '') then
		SDL_Log('Saving game %s...', [PChar(Reason)])
	else
		SDL_Log('Saving current game...', []);

	If SaveGame(GameMode) then
		SDL_Log('Game saved successfully.', [])
	else
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, 'Failed to save the game!', [])
End;


Initialization
	Tikku := 0;

End.

