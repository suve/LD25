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
Unit Shared; 

{$INCLUDE defines.inc}


Interface
Uses
	SysUtils,
	SDL2, SDL2_mixer,
	Entities;


// A shitload of constants - but hey, this is the 'shared' unit, isn't it?
const 
	GAMENAME = 'Colorful'; GAMEAUTH = 'suve';
	MAJORNUM = '2'; MINORNUM = '0'; GAMEVERS = MAJORNUM+'.'+MINORNUM;

{$IFNDEF PACKAGE}
	GAMEDATE = {$INCLUDE %DATE%}+', '+{$INCLUDE %TIME%};
{$ENDIF}

	FPS_LIMIT = 120; TICKS_MINIMUM = 1000 div FPS_LIMIT;

	WINDOW_W = 640; WINDOW_H = 640; // Default window size
	RESOL_W = 320; RESOL_H = 320;   // Game resolution (SDL renderer logical size)

	TILE_W = 16; TILE_H = 16; TILE_S = ((TILE_W + TILE_H) div 2);
	ROOM_W = 20; ROOM_H = 20;
	SWITCHES = 100;

Type
	TGameMode = (GM_TUTORIAL, GM_ORIGINAL);

Const
	RespRoom:Array[TGameMode] of TSDL_Point = ((X:0; Y:0), (X:3; Y:3));
	RespPos:Array[TGameMode] of TSDL_Point = ((X:1; Y:3), (X:10; Y:6));

	HERO_SPEED = TILE_S * 5; HERO_HEALTH = 50; HERO_FIREPOWER = 5; HERO_INVUL = 500;

	AnimFPS = 16; AnimTime = 1000 div AnimFPS;

	AUDIO_FREQ = 22050; AUDIO_TYPE = AUDIO_S16; AUDIO_CHAN = 2; AUDIO_CSIZ = 2048;
	SFXCHANNELS = 32;

	GibSpeed = TILE_S*8; GIB_X = 4; GIB_Y = 4;
	DeathLength = 2500; WOMAN = 8;

Const
	VolLevel_MAX = 6;
Type
	TVolLevel = 0..VolLevel_MAX;

Type
	TPlayerKey = (
		KEY_UP, KEY_RIGHT, KEY_DOWN, KEY_LEFT,
		KEY_SHOOTLEFT, KEY_SHOOTRIGHT,
		KEY_PAUSE, KEY_VOLDOWN, KEY_VOLUP
	);
	TEnemyType = (
		ENEM_DRONE, ENEM_BASHER, ENEM_BALL, ENEM_SPITTER, ENEM_SPAMMER,
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
	Window   : PSDL_Window;   // Game window
	Renderer : PSDL_Renderer; // Renderer handle
	Display  : PSDL_Texture;  // The drawing target texture
	Ev       : TSDL_Event;    // For retrieving SDL events

	Wnd_W, Wnd_H : uInt; // Window width, height and fullscreen flag.
	Wnd_F : Boolean;     // These can be read from Screen, but we save the .ini after closing SDL.

	Hero : PPlayer;
	PBul, EBul : Array of PBullet;
	Mob  : Array of PEntity;
	Gib  : Array of PGib; //Entity arrays

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

Type UpdateProc = Procedure(Name:AnsiString;Perc:Double);

// The name is obvious, duh
Procedure GetDeltaTime(Out Time:uInt);
Procedure GetDeltaTime(Out Time,Ticks:uInt);

// Mainly used in initialization, as we later switch to SDL ticks
Function GetMSecs:Comp;

// Resize window, doh
Procedure ResizeWindow(W,H:uInt;Full:Boolean=FALSE);

// Set up buffers for drawing frame, send frame to display
Procedure BeginFrame();
Procedure FinishFrame();

// Draw primitives using SDL
Procedure DrawColouredRect(Const Rect: PSDL_Rect; Const Colour: PSDL_Colour);
Procedure DrawColouredRect(Const Rect: PSDL_Rect; Const RGB: LongWord);

// Some functions for calculating distances
Function  Hypotenuse(X,Y:Double):Double;
Function  Hypotenuse(aX,aY,bX,bY:Double):Double;
Function  Hypotenuse(A,B:PEntity):Double;
Procedure GetDist(A,B:PEntity;Out oX,oY,oD:Double);

// Sign function (probably is implemented in math or sysutils, but I'm too lazy to check)
Function Sgn(Wat:Double):sInt;
Function InRange(Num,Min,Max:Int64):Boolean;
Function Random(Min,Max:Int64):Int64; Overload;

// Check if objects overlap
Function Overlap(AX,AY:Double;AW,AH:uInt;BX,BY:Double;BW,BH:uInt):Boolean;
Function Overlap(A,B:PEntity):Boolean;

// Some simple converstions from and to strings
Function IntToStr(Num:uInt;Digits:uInt=0;Chr:Char='0'):AnsiString; Overload;
Function StrToInt(S:AnsiString):Int64;

// Volume functions
Procedure ChgVol(Change:sInt;ChgChanVol:Boolean = TRUE);
Procedure SetVol(NewVol:TVolLevel;ChgChanVol:Boolean = TRUE);
Function  GetVol:TVolLevel;

// Play a sound
Procedure PlaySfx(ID:uInt);

// Place a bullet, duh
Procedure PlaceBullet(Owner:PEntity;XV,YV,Pow:Double;Tp:uInt);

// Spawn enemies
Procedure SpawnEnemy(Tp:TEnemyType;mapX,mapY:sInt;SwitchNum:sInt=-1);

// Someone got killed - place gibs!
Procedure PlaceGibs(E:PEntity);

// Change current room
Function ChangeRoom(NX,NY:sInt):Boolean;

// Used in new game, load game and change room.
Procedure DestroyEntities(KillHero:Boolean=FALSE);
Procedure ResetGamestate();


Implementation
Uses
	Assets, Colours, ConfigFiles, FloatingText, Rooms;

Var
	Tikku : uInt;
	VolLevel : TVolLevel;
	Volume : uInt;
	WindowTex: PSDL_Texture;

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

Function GetMSecs():Comp;
Begin
	Exit(TimeStampToMSecs(DateTimeToTimeStamp(Now())))
End;

Procedure ResizeWindow(W,H:uInt;Full:Boolean=FALSE);
Begin
	If (Full) then begin
		SDL_SetWindowSize(Window, RESOL_W, RESOL_H);
		SDL_SetWindowFullscreen(Window, SDL_WINDOW_FULLSCREEN_DESKTOP);
		Wnd_F := True
	end else begin
		SDL_SetWindowFullscreen(Window, 0);
		SDL_SetWindowSize(Window, W, H);
		
		// Centre window on the screen when coming back from fullscreen mode.
		// We need the If() because otherwise, when dragging the window size,
		// it keeps jumping back-and-forth as the WM fights the game over setting the window position.
		If(Wnd_F) then SDL_SetWindowPosition(Window, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED);
		
		Wnd_W := W; Wnd_H := H;
		Wnd_F := False
	end
End;

Procedure BeginFrame();
Begin
	WindowTex := SDL_GetRenderTarget(Renderer);
	SDL_SetRenderTarget(Renderer, Display);

	SDL_SetRenderDrawBlendMode(Renderer, SDL_BLENDMODE_BLEND);
	SDL_SetRenderDrawColor(Renderer, 0, 0, 0, 255);
	SDL_RenderClear(Renderer)
End;

Procedure FinishFrame();
Begin
	SDL_SetRenderTarget(Renderer, WindowTex);
	
	SDL_SetRenderDrawBlendMode(Renderer, SDL_BLENDMODE_BLEND);
	SDL_SetRenderDrawColor(Renderer, 0, 0, 0, 255);
	SDL_RenderClear(Renderer);
	
	SDL_RenderCopy(Renderer, Display, NIL, NIL);
	SDL_RenderPresent(Renderer)
End;

Procedure DrawColouredRect(Const Rect: PSDL_Rect; Const Colour: PSDL_Colour);
Begin
	SDL_SetRenderDrawColor(Renderer, Colour^.R, Colour^.G, Colour^.B, Colour^.A);
	SDL_RenderFillRect(Renderer, Rect)
End;

Procedure DrawColouredRect(Const Rect: PSDL_Rect; Const RGB: LongWord);
Var
	Colour: TSDL_Colour;
Begin
	Colour := RGBToColour(RGB);
	DrawColouredRect(Rect, @Colour)
End;

Function Hypotenuse(X,Y:Double):Double;
   begin Exit(Sqrt(Sqr(X)+Sqr(Y))) end;

Function Hypotenuse(aX,aY,bX,bY:Double):Double;
   begin Exit(Sqrt(Sqr(aX-bX)+Sqr(aY-bY))) end;

Function Hypotenuse(A,B:PEntity):Double;
   begin Exit(Hypotenuse(A^.X+(A^.W/2),A^.Y+(A^.H/2),B^.X+(B^.W/2),B^.Y+(B^.H/2))) end;

Procedure GetDist(A,B:PEntity;Out oX,oY,oD:Double);
   begin
   oX:=(B^.X+(B^.W/2))-(A^.X+(A^.W/2));
   oY:=(B^.Y+(B^.H/2))-(A^.Y+(A^.H/2));
   oD:=Hypotenuse(oX,oY)
   end;

Function Sgn(Wat:Double):sInt;
   begin If (Wat>0) then Exit(+1) else If (Wat<0) then Exit(-1) else Exit(0) end;

Function InRange(Num,Min,Max:Int64):Boolean;
   begin Exit((Num>=Min) and (Num<=Max)) end;

Function Random(Min,Max:Int64):Int64; Overload;
   begin Exit(Min+Random(Max-Min+1)) end;

Function Overlap(AX,AY:Double;AW,AH:uInt;BX,BY:Double;BW,BH:uInt):Boolean;
   begin
   If ((AX + AW - 1) < BX) then Exit(False);
   If ((BX + BW - 1) < AX) then Exit(False);
   If ((AY + AH - 1) < BY) then Exit(False);
   If ((BY + BH - 1) < AY) then Exit(False);
   Exit(True) end;

Function Overlap(A,B:PEntity):Boolean;
   begin Exit(Overlap(A^.X,A^.Y,A^.W,A^.H,B^.X,B^.Y,B^.W,B^.H)) end;

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

Procedure ChgVol(Change:sInt;ChgChanVol:Boolean = TRUE);
   begin
   Change+=VolLevel;
   If (Change<Low(VolLevel)) then SetVol(Low(VolLevel),ChgChanVol) else
   If (Change>High(VolLevel)) then SetVol(High(VolLevel),ChgChanVol) {else}
                               else SetVol(Change,ChgChanVol)
   end;

Procedure SetVol(NewVol:TVolLevel;ChgChanVol:Boolean = TRUE);
   begin
   VolLevel:=NewVol;
   Volume:=Trunc(VolLevel * MIX_MAX_VOLUME / VolLevel_MAX);
   If (Not NoSound) and (ChgChanVol) then Mix_Volume( -1, Volume)
      // When -1 is passes to Mix_Volume, it changes volume of all channels
   end;

Function GetVol:TVolLevel;
   begin Exit(VolLevel) end;

Procedure PlaySfx(ID:uInt);
   Var Chan:sInt;
   begin
   If (NoSound) or (ID>=SOUNDS) then Exit;
   Chan:=Mix_PlayChannel(-1, Sfx[ID], 0);
   If (Chan < 0) then Exit;
   Mix_Volume(Chan, Volume)
   end;

Procedure PlaceBullet(Owner:PEntity;XV,YV,Pow:Double;Tp:uInt);
Var
	B:PBullet;
Begin
	New(B,Create(Tp));
	B^.X:=Owner^.X+(Owner^.W / 2);
	B^.Y:=Owner^.Y+(Owner^.H / 2);
	B^.XVel:=XV; B^.YVel:=YV;
	B^.Power:=Pow; B^.HP:=Pow;
	B^.Col:=Owner^.Col;
	
	If (Owner <> PEntity(Hero)) then begin
		SetLength(EBul,Length(EBul)+1);
		EBul[High(EBul)]:=B
	end else begin
		SetLength(PBul,Length(PBul)+1);
		PBul[High(PBul)]:=B
	end
End;

Procedure SpawnEnemy(Tp:TEnemyType;mapX,mapY:sInt;SwitchNum:sInt=-1);
   Var Dron:PDrone;     Bash:PBasher; Ball:PBall; Spit:PSpitter; Spam:PSpammer;
       Gene:PGenerator; Turr:PTurret;
       E:PEntity;
   begin
   If (mapX<0) or (mapY<0) or (mapX>=ROOM_W) or (mapY>=ROOM_H) then Exit;
   SetLength(Mob,Length(Mob)+1);
   Case Tp of
      ENEM_DRONE:     begin New(Dron,Create()); E:=Dron end;
      ENEM_BASHER:    begin New(Bash,Create()); E:=Bash end;
      ENEM_BALL:      begin New(Ball,Create()); E:=Ball end;
      ENEM_SPITTER:   begin New(Spit,Create()); E:=Spit end;
      ENEM_SPAMMER:   begin New(Spam,Create()); E:=Spam end;
      ENEM_GENERATOR: begin New(Gene,Create()); E:=Gene end;
      ENEM_TURRET:    begin New(Turr,Create()); E:=Turr end;
      otherwise Exit();
      end;
   E^.mX:=mapX; E^.mY:=mapY; E^.SwitchNum:=SwitchNum;
   If (RoomPalette < 8) then E^.Col:=@PaletteColour[RoomPalette];
   Mob[High(Mob)]:=E;
   end;

Procedure PlaceGibs(E:PEntity);
   Var X,Y,W,H,I:uInt; Angle:Double; G:PGib;
   begin
   I:=Length(Gib);
   SetLength(Gib,Length(Gib)+(GIB_X*GIB_Y));
   W:=E^.W div GIB_X; H:=E^.H div GIB_Y;
   For Y:=0 to (GIB_Y-1) do For X:=0 to (GIB_X-1) do begin
       New(G,Create(X*W,Y*H,W,H));
       Angle:=Random(3600)*Pi/1800;
       G^.X:=E^.X+(X*W); G^.Y:=E^.Y+(Y*H);
       G^.XVel:=Cos(Angle)*GibSpeed;
       G^.YVel:=Sin(Angle)*GibSpeed;
       G^.Gfx:=E^.Gfx; G^.Col:=E^.Col;
       Gib[I]:=G; I+=1
       end
   end;

Function ChangeRoom(NX,NY:sInt):Boolean;
   Var NoRoom:Boolean;
   begin
   // First, check if room exists
   Case GameMode of
      GM_TUTORIAL: NoRoom:=(NX<0) or (NY<0) or (NX>=TUT_MAP_W) or (NY>=TUT_MAP_H) or (TutRoom[NX][NY]=NIL);
      GM_ORIGINAL: NoRoom:=(NX<0) or (NY<0) or (NX>=ORG_MAP_W) or (NY>=ORG_MAP_H) or (OrgRoom[NX][NY]=NIL);
      otherwise Exit(False)
      end;
   If (NoRoom) then begin
      Writeln('Error: Room ',GameMode,':',NX,':',NY,' not found!'); Exit(False) end;
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

Procedure DestroyEntities(KillHero:Boolean=FALSE);
   Var C:uInt;
   begin
   If (Length(Mob)>0) then
      For C:=Low(Mob) to High(Mob) do
          If (Mob[C]<>NIL) then Dispose(Mob[C],Destroy());
   If (Length(PBul)>0) then
      For C:=Low(PBul) to High(PBul) do
          If (PBul[C]<>NIL) then Dispose(PBul[C],Destroy());
   If (Length(EBul)>0) then
      For C:=Low(EBul) to High(EBul) do
          If (EBul[C]<>NIL) then Dispose(EBul[C],Destroy());
   If (Length(Gib)>0) then
      For C:=Low(Gib) to High(Gib) do
          If (Gib[C]<>NIL) then Dispose(Gib[C],Destroy());
   SetLength(Mob,0); SetLength(EBul,0); SetLength(PBul,0); SetLength(Gib,0);
   FlushFloatTxt(); Crystal.IsSet:=False;
   If (KillHero) then begin
      If (Hero<>NIL) then Dispose(Hero,Destroy());
      Hero:=NIL; end
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


Initialization
	Shutdown:=False; GameOn:=False; NoSound:=False;
	Tikku := 0;

End.

