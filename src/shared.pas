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
	Buffers, Controllers, Entities, Sprites;


// A shitload of constants - but hey, this is the 'shared' unit, isn't it?
const 
	GAMENAME = 'Colorful'; GAMEAUTH = 'suve';
	MAJORNUM = '2'; MINORNUM = '2'; GAMEVERS = MAJORNUM+'.'+MINORNUM;

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
	TControllerMovementMode = (
		CMM_INVALID = -1,
		CMM_LEFT_STICK, CMM_RIGHT_STICK, CMM_DPAD
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

	// Main variables holding info on whether virtual keys are pressed or not.
	// All control methods (keyboard, gamepad, touch) work by virtue of
	// toggling these virtual keys on or off.
	Key: Array[TPlayerKey] of Boolean;

	// Keyboard key binds
	KeyBind: Array[TPlayerKey] of TSDL_Keycode;

	// Game controller binds.
	PadMovementMode: TControllerMovementMode;
	PadShootLeft, PadShootRight: TControllerBinding;

	GameOn : Boolean; // Is a game in progress?
	GameMode : TGameMode; // Current game mode
	Switch : Array[0..SWITCHES-1] of Boolean;

	ColState: Array[0..7] of TColState;
	ColOrder: Array[0..7] of sInt;
	Crystal: TCrystal;

	PaletteColour : Array[0..7] of TSDL_Colour;
	CentralPalette : Array[0..7] of TSDL_Colour;
	RoomPalette, DeadTime, Carried, Given : sInt;
	// Gamestate variables

	SaveExists : Array[TGameMode] of Boolean;
	Shutdown, NoSound : Boolean;

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

// Sanitize the contents of the ColOrder array, ensuring that all entries
// from [0] to [Given-1] contain a valid value, and there are no duplicates.
Procedure SanitizeColourOrder();

// Convenience function for reducing the amount of copy-pasted code.
Procedure SaveCurrentGame(Reason: AnsiString = '');


Implementation
Uses
	{$IFDEF LD25_DEBUG} ctypes, {$ENDIF}
	Assets, Colours, ConfigFiles, FloatingText, Rendering, Rooms;

Var
	VolLevel : TVolLevel;
	Volume : uInt;

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
	For C:=Low(ColOrder) to High(ColOrder) do ColOrder[C]:=-1;
	For C:=Low(Switch) to High(Switch) do Switch[C]:=False;

	Carried:=0; Given:=0;
End;

Procedure SanitizeColourOrder();
Var
	HasOrder: Array[0..7] of Boolean;

	Procedure FillUnknownValues(OnlyGiven: Boolean);
	Var
		Idx, Guess: sInt;
	Begin
		For Idx := 0 to (Given-1) do begin
			If(ColOrder[Idx] >= 0) and (ColOrder[Idx] <= 7) then Continue;

			// Go over all colours and assign the first retrieved colour
			// which is not yet present in the ordering.
			For Guess:=0 to 7 do begin
				If(HasOrder[Guess]) then Continue;

				If(OnlyGiven) and (ColState[Guess] <> STATE_GIVEN) then Continue;

				HasOrder[Guess] := True;
				ColOrder[Idx] := Guess;
				Break
			end
		end
	End;

Var
	Idx, Claim: sInt;
Begin
	{$IFDEF LD25_DEBUG}
		SDL_LogDebug(
			SDL_LOG_CATEGORY_APPLICATION,
			'Sanitizing order of %d colours: %d (%s), %d (%s), %d (%s), %d (%s), %d (%s), %d (%s), %d (%s), %d (%s)',
			[
				cint(Given),
				cint(ColOrder[0]), PChar(ColourIndexToName(ColOrder[0])),
				cint(ColOrder[1]), PChar(ColourIndexToName(ColOrder[1])),
				cint(ColOrder[2]), PChar(ColourIndexToName(ColOrder[2])),
				cint(ColOrder[3]), PChar(ColourIndexToName(ColOrder[3])),
				cint(ColOrder[4]), PChar(ColourIndexToName(ColOrder[4])),
				cint(ColOrder[5]), PChar(ColourIndexToName(ColOrder[5])),
				cint(ColOrder[6]), PChar(ColourIndexToName(ColOrder[6])),
				cint(ColOrder[7]), PChar(ColourIndexToName(ColOrder[7]))
			]
		);
	{$ENDIF}

	If(Given = 0) then Exit;

	// Mark all the colours as not having an ordering assigned
	For Idx := 0 to 7 do HasOrder[Idx] := False;

	// Go over the claimed ordering.
	For Idx := 0 to (Given-1) do begin
		Claim := ColOrder[Idx];

		// Claimed ordering includes an invalid value. Ignore.
		If(Claim < 0) or (Claim > 7) then Continue;

		(*
		 * a) Claimed ordering includes a colour that was not retrieved.
		 * b) Claimed ordering includes a colour twice.
		 * Set the value to "unknown" and move to next entry.
		 *)
		If(ColState[Claim] <> STATE_GIVEN) or (HasOrder[Claim]) then begin
			ColOrder[Idx] := -1;
			Continue
		end;

		// Seems ok!
		HasOrder[Claim] := True
	end;

	// Go over the resulting ordering and look for unknown values.
	// Fill unknown values with colours marked as given.
	FillUnknownValues(True);

	// Go over the result once again, using all colours.
	// This will make sure the ordering always makes sense,
	// even if the Given value is larger than the actual number
	// of colours marked as STATE_GIVEN.
	FillUnknownValues(False);

	{$IFDEF LD25_DEBUG}
		SDL_LogDebug(
			SDL_LOG_CATEGORY_APPLICATION,
			'Sanitized order of %d colours: %d (%s), %d (%s), %d (%s), %d (%s), %d (%s), %d (%s), %d (%s), %d (%s)',
			[
				cint(Given),
				cint(ColOrder[0]), PChar(ColourIndexToName(ColOrder[0])),
				cint(ColOrder[1]), PChar(ColourIndexToName(ColOrder[1])),
				cint(ColOrder[2]), PChar(ColourIndexToName(ColOrder[2])),
				cint(ColOrder[3]), PChar(ColourIndexToName(ColOrder[3])),
				cint(ColOrder[4]), PChar(ColourIndexToName(ColOrder[4])),
				cint(ColOrder[5]), PChar(ColourIndexToName(ColOrder[5])),
				cint(ColOrder[6]), PChar(ColourIndexToName(ColOrder[6])),
				cint(ColOrder[7]), PChar(ColourIndexToName(ColOrder[7]))
			]
		);
	{$ENDIF}
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

End.
