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
unit shared; 

{$INCLUDE defines.inc}


interface

uses SDL2, SDL2_mixer, Fonts, Images, Objects, SysUtils;


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
	ORG_MAP_W = 7; ORG_MAP_H = 7; ORG_ROOMNUM = ORG_MAP_W*ORG_MAP_H;
	TUT_MAP_W = 3; TUT_MAP_H = 3; TUT_ROOMNUM = TUT_MAP_W*TUT_MAP_H;

	RespRoom:Array[TGameMode] of TSDL_Point = ((X:0; Y:0), (X:3; Y:3));
	RespPos:Array[TGameMode] of TSDL_Point = ((X:1; Y:3), (X:10; Y:6));

	HERO_SPEED = TILE_S * 5; HERO_HEALTH = 50; HERO_FIREPOWER = 5; HERO_INVUL = 500;

	GFX_HERO = 0; GFX_ENEM = 1;
	CHARAS = 8; BULLETS = 5; SLIDES_IN = 6; SLIDES_OUT = 10;
	OTHERS = 3; //tiles, ui, colours; icon gets loaded separately

	WALL_SFX = 4; METAL_SFX = 3; DIE_SFX = 6; SHOT_SFX = 4; HIT_SFX = 1; EXTRA_SFX = 3;
	SFX_WALL = 0; SFX_METAL = SFX_WALL+WALL_SFX; SFX_DIE = SFX_METAL+METAL_SFX;
	SFX_SHOT = SFX_DIE+DIE_SFX; SFX_HIT = SFX_SHOT + SHOT_SFX; SFX_EXTRA = SFX_HIT+HIT_SFX;
	SOUNDS = SFX_EXTRA + EXTRA_SFX;

	FILES_TO_LOAD = CHARAS + BULLETS + SOUNDS + OTHERS + SLIDES_IN + SLIDES_OUT +
				  ORG_ROOMNUM + TUT_ROOMNUM;
	FILES_NOSOUND = FILES_TO_LOAD - SOUNDS;

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

	IconSurf: PSDL_Surface;
	TitleGfx, TileGfx, UIgfx, ColGfx : PImage;
	CharaGfx : Array[0..CHARAS-1] of PImage;
	ShotGfx  : Array[0..BULLETS-1] of PImage;
	SlideIn  : Array[0..SLIDES_IN-1] of PImage;
	SlideOut : Array[0..SLIDES_OUT-1] of PImage;  //Images, duh

	Font, NumFont : PFont; //Fonts
	FontImg, NumFontImg: PImage;

	Sfx  : Array[0..SOUNDS-1] of PMix_Chunk; //Sfx array

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

// Load gfx and sfx, melady
Function  LoadBasics(Out Status:AnsiString):Boolean;
Function  LoadRes(Out Status:AnsiString; Const Update: UpdateProc = NIL):Boolean;
Procedure LoadAndSetWindowIcon();

// Free resources
Procedure Free();


Implementation
Uses
	SDL2_Image,
	Colours, ConfigFiles, FloatingText, Rooms;

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


Function CheckForExitEvent():Boolean;
Var
	ExitRequested: Boolean;
Begin
	ExitRequested := False;
	While(SDL_PollEvent(@Ev) > 0) do Case(Ev.Type_) of
		SDL_QuitEv:
			ExitRequested := True;
	end;
	
	Result := ExitRequested
End;

{$DEFINE IGNORE_EVENTS := If(CheckForExitEvent()) then begin Status := 'Interrupted by user'; Exit(False) end;}

const
	GFX_TITLE = 'gfx/title.png';
	FILE_FONT = 'gfx/font.png';
	ICON_FILE = 'gfx/icon.png';
	GFX_FILE : Array[0..CHARAS-1] of String = (
		'gfx/hero.png','gfx/enem0.png','gfx/enem1.png','gfx/enem2.png','gfx/enem3.png',
		'gfx/enem4.png','gfx/enem5.png','gfx/enem6.png'
	);
	FILE_TILES = 'gfx/tiles.png';
	FILE_UI = 'gfx/ui.png';
	FILE_COLOURS = 'gfx/colours.png';
	NUMFONTFILE = 'gfx/numbers.png';
	PATH_ORG = 'map/org/'; 
	PATH_TUT = 'map/tut/';
	
	COLOUR_BLACK:TSDL_Colour = (R: 0; G: 0; B: 0; A: 255);
	COLOUR_GREY:TSDL_Colour = (R: $80; G: $80; B: $80; A: 255);
	COLOUR_LIME:TSDL_Colour = (R: 0; G: 255; B: 0; A: 255);

Function LoadBasics(Out Status:AnsiString):Boolean;
begin
	TitleGfx:=LoadImage(DataPath+GFX_TITLE, @COLOUR_BLACK);
	If (TitleGfx=NIL) then begin Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}GFX_TITLE+' ('+ImageError()+')'); Exit(False) end;
	
	IGNORE_EVENTS;

	FontImg:=LoadImage(DataPath+FILE_FONT, @COLOUR_BLACK);
	If (FontImg=NIL) then begin Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}FILE_FONT+' ('+ImageError()+')'); Exit(False) end;
	Font:=FontFromImage(FontImg,#32,5,7);
	Font^.SpacingX := 1;
	Font^.SpacingY := 1;

	IGNORE_EVENTS;
	Exit(True)
End;

Function LoadRes_Sounds(Out Status: AnsiString; Var FilesLoaded, FilesTotal: sInt; Const Update: UpdateProc):Boolean;
Var
	i: sInt;
	Filename: AnsiString;
	Sample: PMix_Chunk;
Begin
	For i:=0 to (WALL_SFX - 1) do begin
		WriteStr(Filename, 'sfx/wall',i,'.wav');
		
		Sample:=Mix_LoadWAV(PChar(DataPath+Filename));
		If (Sample = NIL) then begin
			Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}Filename; Exit(False)
		end;
		
		Sfx[SFX_WALL+i]:=Sample;
		FilesLoaded+=1; Update(Filename, FilesLoaded / FilesTotal); IGNORE_EVENTS
	end;
	For i:=0 to (METAL_SFX - 1) do begin
		WriteStr(Filename, 'sfx/metal',i,'.wav');
		
		Sample:=Mix_LoadWAV(PChar(DataPath+Filename));
		If (Sample = NIL) then begin
			Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}Filename; Exit(False) 
		end;
		
		Sfx[SFX_METAL+i]:=Sample;
		FilesLoaded+=1; Update(Filename, FilesLoaded / FilesTotal); IGNORE_EVENTS
	end;
	For i:=0 to (DIE_SFX - 1) do begin
		WriteStr(Filename, 'sfx/die',i,'.wav');
		
		Sample:=Mix_LoadWAV(PChar(DataPath+Filename));
		If (Sample = NIL) then begin
			Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}Filename; Exit(False)
		end;
		
		Sfx[SFX_DIE+i]:=Sample;
		FilesLoaded+=1; Update(Filename, FilesLoaded / FilesTotal); IGNORE_EVENTS
	end;
	For i:=0 to (SHOT_SFX - 1) do begin
		WriteStr(Filename, 'sfx/shot',i,'.wav');
		
		Sample:=Mix_LoadWAV(PChar(DataPath+Filename));
		If (Sample = NIL) then begin
			Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}Filename; Exit(False)
		end;
		
		Sfx[SFX_SHOT+i]:=Sample;
		FilesLoaded+=1; Update(Filename, FilesLoaded / FilesTotal); IGNORE_EVENTS
	end;
	For i:=0 to (HIT_SFX - 1) do begin
		WriteStr(Filename, 'sfx/hit',i,'.wav');
		
		Sample:=Mix_LoadWAV(PChar(DataPath+Filename));
		If (Sample = NIL) then begin
			Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}Filename; Exit(False)
		end;
		
		Sfx[SFX_HIT+i]:=Sample;
		FilesLoaded+=1; Update(Filename, FilesLoaded / FilesTotal); IGNORE_EVENTS
	end;
	For i:=0 to (EXTRA_SFX - 1) do begin
		WriteStr(Filename, 'sfx/extra',i,'.wav');
		
		Sample:=Mix_LoadWAV(PChar(DataPath+Filename));
		If (Sample = NIL) then begin
			Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}Filename; Exit(False)
		end;
		
		Sfx[SFX_EXTRA+i]:=Sample;
		FilesLoaded+=1; Update(Filename, FilesLoaded / FilesTotal); IGNORE_EVENTS
	end;
	Exit(True)
End;

Function LoadRes(Out Status:AnsiString; Const Update: UpdateProc = NIL):Boolean;
Var
	FilesLoaded, FilesTotal: sInt; 
	Filename: AnsiString;
	X, Y, i: sInt;
	
	Img: PImage; 
	Room: PRoom;
Begin
	FilesLoaded:=0;
	If (Not NoSound)
		then FilesTotal:=FILES_TO_LOAD
		else FilesTotal:=FILES_NOSOUND;

	// Numfont used for FPS display
	NumFontImg:=LoadImage(DataPath+NUMFONTFILE, @COLOUR_BLACK);
	If (NumFontImg = NIL) then begin
		Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}NUMFONTFILE);
		Exit(False)
	end;
	NumFont:=FontFromImage(NumFontImg, '0', 3, 5);
	NumFont^.SpacingX := 1; NumFont^.SpacingY := 1;
	FilesLoaded+=1; Update(NUMFONTFILE,FilesLoaded / FilesTotal); IGNORE_EVENTS;

	TileGfx:=LoadImage(DataPath+FILE_TILES, @COLOUR_BLACK);
	If (TileGfx = NIL) then begin
		Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}FILE_TILES);
		Exit(False)
	end;
	FilesLoaded+=1; Update(FILE_TILES,FilesLoaded / FilesTotal); IGNORE_EVENTS;

	UIgfx:=LoadImage(DataPath+FILE_UI, @COLOUR_LIME);
	If (UIgfx = NIL) then begin
		Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}FILE_UI);
		Exit(False)
	end;
	FilesLoaded+=1; Update(FILE_UI,FilesLoaded / FilesTotal); IGNORE_EVENTS;

	ColGfx:=LoadImage(DataPath+FILE_COLOURS, @COLOUR_GREY);
	If (ColGfx = NIL) then begin
		Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}FILE_UI);
		Exit(False)
	end;
	FilesLoaded+=1; Update(FILE_COLOURS,FilesLoaded / FilesTotal); IGNORE_EVENTS;
   
	// Load intro slides
	For i:=0 to SLIDES_IN-1 do begin
		WriteStr(Filename, 'intro/slide',i,'.png');
		
		Img:=LoadImage(DataPath+Filename, @COLOUR_BLACK);
		If (Img=NIL) then begin
			Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}Filename);
			Exit(False)
		end;
		
		SlideIn[i]:=Img;
		FilesLoaded+=1; Update(Filename, FilesLoaded / FilesTotal); IGNORE_EVENTS
	end;
     
	// Load outro slides  
	For i:=0 to SLIDES_OUT-1 do begin
		WriteStr(Filename, 'intro/out',i,'.png');
		Img:=LoadImage(DataPath+Filename, @COLOUR_BLACK);
		If (Img=NIL) then begin
			Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}Filename);
			Exit(False)
		end;
		
		SlideOut[i]:=Img;
		FilesLoaded+=1; Update(Filename, FilesLoaded / FilesTotal); IGNORE_EVENTS
	end;

	// Characters
	For i:=0 to CHARAS-1 do begin
		Img:=LoadImage(DataPath+GFX_FILE[i], @COLOUR_BLACK);
		If (Img=NIL) then begin
			Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}GFX_FILE[i]);
			Exit(False)
		end;
		
		CharaGfx[i]:=Img;
		FilesLoaded+=1; Update(GFX_FILE[i],FilesLoaded / FilesTotal); IGNORE_EVENTS
	end;

	// Bullets
	For i:=0 to BULLETS-1 do begin
		WriteStr(Filename, 'gfx/shot',i,'.png');
		Img:=LoadImage(DataPath+Filename, @COLOUR_BLACK);
		If (Img=NIL) then begin
			Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}Filename);
			Exit(False)
		end;
		
		ShotGfx[i]:=Img;
		FilesLoaded+=1; Update(Filename, FilesLoaded / FilesTotal); IGNORE_EVENTS
	end;

	If (Not NoSound) then begin
		If (Not LoadRes_Sounds(Status, FilesLoaded, FilesTotal, Update)) then Exit(False)
	end;
      
	// Maps. Original levels first, tutorial second.
	For Y:=0 to (ORG_MAP_H-1) do For X:=0 to (ORG_MAP_W-1) do begin
		WriteStr(Filename, PATH_ORG,X,'-',Y,'.txt');
		
		Room:=LoadRoom(X, Y, DataPath+Filename);
		If (Room = NIL) then begin
			Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}Filename;
			Exit(False) 
		end;
		
		Room^.X:=X; Room^.Y:=Y; OrgRoom[X][Y]:=Room;
		FilesLoaded+=1; Update(Filename, FilesLoaded / FilesTotal); IGNORE_EVENTS
	end;
	For Y:=0 to (TUT_MAP_H-1) do For X:=0 to (TUT_MAP_W-1) do begin
		WriteStr(Filename, PATH_TUT,X,'-',Y,'.txt');
		
		Room:=LoadRoom(X, Y, DataPath+Filename);
		If (Room = NIL) then begin
			Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}Filename;
			Exit(False)
		end;
		
		Room^.X:=X; Room^.Y:=Y; TutRoom[X][Y]:=Room;
		FilesLoaded+=1; Update(Filename, FilesLoaded / FilesTotal); IGNORE_EVENTS
	end;
       
	Exit(True)
End;

Procedure LoadAndSetWindowIcon();
Begin
	If(IconSurf = NIL) then begin
		IconSurf:=IMG_Load(PChar(DataPath+ICON_FILE));
		
		If (IconSurf = NIL) then begin
			Writeln('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}ICON_FILE);
			Exit()
		end
	end;
	
	SDL_SetWindowIcon(Window, IconSurf)
End;

Procedure Free;
Var C:uInt;
Begin
	(* Since this is called only on program exit, it doesn't
	 * really matter if we forget anything. It will all be freed
	 * by the OS when the program dies, afterall. *)

	If (IconSurf<>NIL) then begin
		SDL_SetWindowIcon(Window, NIL);
		SDL_FreeSurface(IconSurf);
	end;

	If (TitleGfx<>NIL) then FreeImage(TitleGfx);
	If (Font<>NIL) then FreeFont(Font);
	If (FontImg<>NIL) then FreeImage(FontImg);
	If (NumFont<>NIL) then FreeFont(NumFont);
	If (NumFontImg<>NIL) then FreeImage(NumFontImg);
	If (UIgfx<>NIL) then FreeImage(UIgfx);
	If (TileGfx<>NIL) then FreeImage(TileGfx);
	If (ColGfx<>NIL) then FreeImage(ColGfx);
	For C:=Low(SlideOut) to High(SlideOut) do
		If (SlideOut[C]<>NIL) then FreeImage(SlideOut[C]);
	For C:=Low(SlideIn) to High(SlideIn) do
		If (SlideIn[C]<>NIL) then FreeImage(SlideIn[C]);
	For C:=0 to CHARAS-1 do
		If (CharaGfx[C]<>NIL) then FreeImage(CharaGfx[C]);
	For C:=0 to BULLETS-1 do
		If (ShotGfx[C]<>NIL) then FreeImage(ShotGfx[C]);
	If (Not NoSound) then begin
		Mix_HaltChannel(-1);     //Halt all playing sounds
		Mix_AllocateChannels(0); //Free all sfx channels
		(* We do the two above to make sure no sound is being played.
		 * Freeing a sample (Chunk) that is being played is a bad idea. *)
		For C:=0 to (SOUNDS-1) do
			If (Sfx[C] <> NIL) then Mix_FreeChunk(Sfx[C])
	end;
	DestroyEntities(True);
	FreeRooms();
End;

initialization
   Shutdown:=False; GameOn:=False; NoSound:=False;
   Tikku := 0;

end.

