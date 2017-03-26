unit shared; {$MODE OBJFPC} {$COPERATORS ON} {$WRITEABLECONST OFF} {$TYPEDADDRESS ON}

interface

uses SDL, Sour, GL, Objects, SDL_Mixer, SysUtils;

// A shitload of constants - but hey, this is the 'shared' unit, isn't it?

const GAMENAME = 'Colorful'; GAMEAUTH = 'suve';
      MAJORNUM = '1'; MINORNUM = '2'; GAMEVERS = MAJORNUM+'.'+MINORNUM;
      GAMEDATE = {$INCLUDE %DATE%}+', '+{$INCLUDE %TIME%};

      FPS_LIMIT = 120; TICKS_MINIMUM = 1000 div FPS_LIMIT;

      WINDOW_W = 640; WINDOW_H = 640; // Default window size
      RESOL_W = 320; RESOL_H = 320;   // Game resolution (set in OpenGL)

      TILE_W = 16; TILE_H = 16; TILE_S = ((TILE_W + TILE_H) div 2);
      ROOM_W = 20; ROOM_H = 20;

Type TGameMode = (GM_TUTORIAL, GM_ORIGINAL);

Const ORG_MAP_W = 7; ORG_MAP_H = 7; ORG_ROOMNUM = ORG_MAP_W*ORG_MAP_H;
      TUT_MAP_W = 3; TUT_MAP_H = 3; TUT_ROOMNUM = TUT_MAP_W*TUT_MAP_H;

      RespRoom:Array[TGameMode] of Sour.TCrd = ((X:0; Y:0), (X:3; Y:3));
      RespPos:Array[TGameMode] of Sour.TCrd = ((X:1; Y:3), (X:10; Y:6));

      HERO_SPEED = TILE_S * 5; HERO_HEALTH = 50; HERO_FIREPOWER = 5; HERO_INVUL = 500;

      GFX_HERO = 0; GFX_ENEM = 1;
      CHARAS = 8; BULLETS = 5; SLIDES_IN = 6; SLIDES_OUT = 10;
      OTHERS = 3; //tiles, ui, colours

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

Const UIcolour : Array[0..7] of LongWord =
      ($585858FF,$0000FFFF,$00FF00FF,$00FFFFFF,$FF0000FF,$FF00FFFF,$FFFF00FF,$FFFFFFFF);
      MapColour : Array[0..7] of LongWord =
      ($323232, $10186A, $299C00, $009A9A, $7A0818, $94188B, $FFDE5A, $DADADA);
      WhiteColour : Sour.TColour = (R: 255; G: 255; B: 255; A: 255);
      GreyColour : Sour.TColour = (R: 128; G: 128; B: 128; A: 255);
      BlackColour : Sour.TColour = (R: 0; G: 0; B: 0; A: 255);
      
      ColourName : Array[0..7] of AnsiString = 
      ('black','navy','green','blue','red','purple','yellow','white');
      
      VolLevel_MAX = 6;

Type TPlayerKey = (KEY_UP, KEY_RIGHT, KEY_DOWN, KEY_LEFT, KEY_SHOOTLEFT, KEY_SHOOTRIGHT,
                   KEY_PAUSE, KEY_VOLDOWN, KEY_VOLUP);
     TEnemyType = (ENEM_DRONE,ENEM_BASHER,ENEM_BALL,ENEM_SPITTER,ENEM_SPAMMER,
                   ENEM_GENERATOR, ENEM_TURRET);
     TColState = (STATE_NONE,STATE_PICKED,STATE_GIVEN);
     TVolLevel = 0..VolLevel_MAX;
     TCrystal = record
     IsSet : Boolean;
     mX, mY: LongInt;
     Col : LongWord
     end;

// Progstate and gamestate variables. This isn't a project big enough to actually
// require having a separate game controller class. I'll just keep everything global...

var Screen : PSDL_Surface;  // SDL Video surface
    Ev     : TSDL_Event;    // For retrieving SDL events

    Wnd_W, Wnd_H : LongWord; // Window width, height and fullscreen flag.
    Wnd_F : Boolean;         // These can be read from Screen, but we save the .ini after closing SDL.

    TitleGfx, TileGfx, UIgfx, ColGfx : Sour.PImage;
    CharaGfx : Array[0..CHARAS-1] of Sour.PImage;
    ShotGfx  : Array[0..BULLETS-1] of Sour.PImage;
    SlideIn  : Array[0..SLIDES_IN-1] of Sour.PImage;
    SlideOut : Array[0..SLIDES_OUT-1] of Sour.PImage;  //Images, duh

    Font, NumFont : Sour.PFont; //Fonts

    Sfx  : Array[0..SOUNDS-1] of PMix_Chunk; //Sfx array

    Hero : PPlayer;
    PBul, EBul : Array of PBullet;
    Mob  : Array of PEntity;
    Gib  : Array of PGib; //Entity arrays

    Key     : Array[TPlayerKey] of Boolean;
    KeyBind :Array[TPlayerKey] of TSDLKey; //Playa controls

    GameOn : Boolean; // Is a game in progress?
    GameMode : TGameMode; // Current game mode
    Switch : Array[0..99] of Boolean;
    ColState : Array[0..7] of TColState;
    Crystal : TCrystal;
    PaletteColour : Array[0..7] of Sour.TColour;
    CentralPalette : Array[0..7] of Sour.TColour;
    RoomPalette, DeadTime, Carried, Given : LongInt;
    // Gamestate variables

    SaveExists : Array[TGameMode] of Boolean;
    Shutdown, NoSound : Boolean;

Type UpdateProc = Procedure(Name:AnsiString;Perc:Double);

// The name is obvious, duh
Procedure GetDeltaTime(Out Time:LongWord);
Procedure GetDeltaTime(Out Time,Ticks:LongWord);

// Mainly used in initialization, as we later switch to SDL ticks
Function GetMSecs:Comp;

// Resize window, doh
Procedure ResizeWindow(W,H:LongWord;Full:Boolean=FALSE);
Procedure SetResolution();

// Some functions for calculating distances
Function  Hypotenuse(X,Y:Double):Double;
Function  Hypotenuse(aX,aY,bX,bY:Double):Double;
Function  Hypotenuse(A,B:PEntity):Double;
Procedure GetDist(A,B:PEntity;Out oX,oY,oD:Double);

// Sign function (probably is implemented in math or sysutils, but I'm too lazy to check)
Function Sgn(Wat:Double):LongInt;
Function InRange(Num,Min,Max:Int64):Boolean;
Function Random(Min,Max:Int64):Int64; Overload;

// Check if objects overlap
Function Overlap(AX,AY:Double;AW,AH:LongWord;BX,BY:Double;BW,BH:LongWord):Boolean;
Function Overlap(A,B:PEntity):Boolean;

// Some simple converstions from and to strings
Function IntToStr(Num:LongWord;Digits:LongWord=0;Chr:Char='0'):AnsiString; Overload;
Function StrToInt(S:AnsiString):Int64;

// Volume functions
Procedure ChgVol(Change:LongInt;ChgChanVol:Boolean = TRUE);
Procedure SetVol(NewVol:TVolLevel;ChgChanVol:Boolean = TRUE);
Function  GetVol:TVolLevel;

// Play a sound
Procedure PlaySfx(ID:LongWord);

// Place a bullet, duh
Procedure PlaceBullet(Owner:PEntity;XV,YV,Pow:Double;Tp:LongWord);

// Spawn enemies
Procedure SpawnEnemy(Tp:TEnemyType;mapX,mapY:LongInt;SwitchNum:LongInt=-1);

// Someone got killed - place gibs!
Procedure PlaceGibs(E:PEntity);

// Change current room
Function ChangeRoom(NX,NY:LongInt):Boolean;

// Used in new game, load game and change room.
Procedure DestroyEntities(KillHero:Boolean=FALSE);
Procedure ResetGamestate();

// Load gfx and sfx, melady
Function LoadBasics(Out Status:AnsiString):Boolean;
Function LoadRes(Out Status:AnsiString; Update : UpdateProc = NIL):Boolean;

// Free resources
Procedure Free();

implementation
   uses Rooms, FloatingText, ConfigFiles;

var Tikku : LongWord;
    VolLevel : TVolLevel;
    Volume : LongWord;

Procedure GetDeltaTime(Out Time:LongWord);
   begin
   While ((SDL_GetTicks - Tikku) < TICKS_MINIMUM) do SDL_Delay(1);
   Time:=(SDL_GetTicks - Tikku); Tikku+=Time
   end;

Procedure GetDeltaTime(Out Time,Ticks:LongWord);
   begin
   While ((SDL_GetTicks - Tikku) < TICKS_MINIMUM) do SDL_Delay(1);
   Time:=(SDL_GetTicks - Tikku); Tikku+=Time; Ticks:=Tikku
   end;

Function GetMSecs():Comp;
   begin Exit(TimeStampToMSecs(DateTimeToTimeStamp(Now()))) end;

Procedure ResizeWindow(W,H:LongWord;Full:Boolean=FALSE);
   Var Flag : LongWord;
   begin
   If (Full) then begin Flag:=SDL_FullScreen; W:=0; H:=0 end
             else Flag:=SDL_Resizable;
   (* If the fullscreen flag is set, we set W and H to 0. This will make SDL
      create a window with the user's desktop size, thus saving the video
      drivers the crazy work of changing the display resolution. *)
   Screen:=Sour.ResizeWindow(W,H,Flag);
   SetResolution()
   end;

Procedure SetResolution();

   Function FlagSet(Const Flag,Val:LongWord):Boolean;
      begin Exit((Val and Flag) = Flag) end;
   (* Fuck yeah, Pascal allows creating sub-routines. Beat that, C! *)

   Var X, Y : LongInt;
   begin
   Wnd_W:=Screen^.W; Wnd_H:=Screen^.H; Wnd_F:=FlagSet(SDL_FullScreen, Screen^.Flags);
   If (Wnd_H < Wnd_W)
      then begin X:=Trunc((Wnd_W - Wnd_H)/(Wnd_H*2)*RESOL_W); Y:=0 end
      else begin X:=0; Y:=Trunc((Wnd_H - Wnd_W)/(Wnd_W*2)*RESOL_H) end;
   (* Since we want to keep the aspect ratio of the game screen, we have to
      calculate the resolution accordingly. The game area should be centered
      on the screen, with unused bars left at the sides. *)
   Sour.SetVisibleArea(-X,-Y,RESOL_W+(X*2),RESOL_H+(Y*2))
   end;

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

Function Sgn(Wat:Double):LongInt;
   begin If (Wat>0) then Exit(+1) else If (Wat<0) then Exit(-1) else Exit(0) end;

Function InRange(Num,Min,Max:Int64):Boolean;
   begin Exit((Num>=Min) and (Num<=Max)) end;

Function Random(Min,Max:Int64):Int64; Overload;
   begin Exit(Min+Random(Max-Min+1)) end;

Function Overlap(AX,AY:Double;AW,AH:LongWord;BX,BY:Double;BW,BH:LongWord):Boolean;
   begin
   If ((AX + AW - 1) < BX) then Exit(False);
   If ((BX + BW - 1) < AX) then Exit(False);
   If ((AY + AH - 1) < BY) then Exit(False);
   If ((BY + BH - 1) < AY) then Exit(False);
   Exit(True) end;

Function Overlap(A,B:PEntity):Boolean;
   begin Exit(Overlap(A^.X,A^.Y,A^.W,A^.H,B^.X,B^.Y,B^.W,B^.H)) end;

Function IntToStr(Num:LongWord;Digits:LongWord=0;Chr:Char='0'):AnsiString;
   Var Res:AnsiString;
   begin
   WriteStr(Res,Num);
   If (Length(Res)<Digits) then Res:=StringOfChar(Chr,Digits-Length(Res))+Res;
   Exit(Res)
   end;

Function StrToInt(S:AnsiString):Int64;
   Var P:LongWord; R:Int64;
   begin
   R:=0; If (Length(S) = 0) then Exit(0);
   For P:=1 to Length(S) do
      If (S[P]>=#48) and (S[P]<=#57) then R:=(R*10)+(Ord(S[P])-48);
   If (S[1]<>'-') then Exit(R) else Exit(-R)
   end;

Procedure ChgVol(Change:LongInt;ChgChanVol:Boolean = TRUE);
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

Procedure PlaySfx(ID:LongWord);
   Var Chan:LongInt;
   begin
   If (NoSound) or (ID>=SOUNDS) then Exit;
   Chan:=Mix_PlayChannel(-1, Sfx[ID], 0);
   If (Chan < 0) then Exit;
   Mix_Volume(Chan, Volume)
   end;

Procedure PlaceBullet(Owner:PEntity;XV,YV,Pow:Double;Tp:LongWord);
   Var B:PBullet;
   begin
   New(B,Create(Tp));
   If (Owner^.Enemy) then SetLength(EBul,Length(EBul)+1)
                     else SetLength(PBul,Length(PBul)+1);
   B^.X:=Owner^.X+(Owner^.W / 2);
   B^.Y:=Owner^.Y+(Owner^.H / 2);
   B^.Enemy:=Owner^.Enemy; B^.Col:=Owner^.Col;
   B^.XVel:=XV; B^.YVel:=YV; B^.Power:=Pow; B^.HP:=Pow;
   If (Owner^.Enemy) then EBul[High(EBul)]:=B
                     else PBul[High(PBul)]:=B
   end;

Procedure SpawnEnemy(Tp:TEnemyType;mapX,mapY:LongInt;SwitchNum:LongInt=-1);
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
      end;
   E^.mX:=mapX; E^.mY:=mapY; E^.SwitchNum:=SwitchNum;
   If (RoomPalette < 8) then E^.Col:=@PaletteColour[RoomPalette];
   Mob[High(Mob)]:=E;
   end;

Procedure PlaceGibs(E:PEntity);
   Var X,Y,W,H,I:LongWord; Angle:Double; G:PGib;
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

Function ChangeRoom(NX,NY:LongInt):Boolean;
   Var NoRoom:Boolean;
   begin
   // First, check if room exists
   Case GameMode of
      GM_TUTORIAL: NoRoom:=(NX<0) or (NY<0) or (NX>=TUT_MAP_W) or (NY>=TUT_MAP_H) or (TutRoom[NX][NY]=NIL);
      GM_ORIGINAL: NoRoom:=(NX<0) or (NY<0) or (NX>=ORG_MAP_W) or (NY>=ORG_MAP_H) or (OrgRoom[NX][NY]=NIL);
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
   Var C:LongWord;
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
   Var C:LongInt;
   begin
   For C:=0 to 7 do PaletteColour[C]:=Sour.MakeColour(MapColour[C]);
   For C:=0 to 7 do CentralPalette[C]:=Sour.MakeColour(127,127,127);
   For C:=Low(ColState) to High(ColState) do ColState[C]:=STATE_NONE;
   For C:=Low(Switch) to High(Switch) do Switch[C]:=False;
   // Set array variables
   Carried:=0; Given:=0;
   end;

const GFX_TITLE = 'gfx/title.png'; FILE_FONT = 'gfx/font.png';
      GFX_FILE : Array[0..CHARAS-1] of String = (
      'gfx/hero.png','gfx/enem0.png','gfx/enem1.png','gfx/enem2.png','gfx/enem3.png',
      'gfx/enem4.png','gfx/enem5.png','gfx/enem6.png');
      FILE_TILES = 'gfx/tiles.png'; FILE_UI = 'gfx/ui.png'; FILE_COLOURS = 'gfx/colours.png';
      NUMFONTFILE = 'gfx/numbers.png';
      PATH_ORG = 'map/org/'; PATH_TUT = 'map/tut/';

Function LoadBasics(Out Status:AnsiString):Boolean;
   begin
   TitleGfx:=Sour.LoadImage(DataPath+GFX_TITLE);
   If (TitleGfx=NIL) then begin Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}GFX_TITLE); Exit(False) end;
   Font:=Sour.LoadFont(DataPath+FILE_FONT,$000000,5,7,#32);
   If (Font=NIL) then begin Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}FILE_FONT); Exit(False) end;
   Sour.SetFontSpacing(Font,1,1);
   Exit(True)
   end;

Function LoadRes(Out Status:AnsiString; Update : UpdateProc = NIL):Boolean;
   Var FilesLoaded, FilesTotal, C,X,Y:LongWord; S:AnsiString;
       Img:Sour.PImage; Samp:PMix_Chunk; R:PRoom;
   begin
   FilesLoaded:=0;
   If (Not NoSound) then FilesTotal:=FILES_TO_LOAD
                    else FilesTotal:=FILES_NOSOUND;
   // SOME MINOR SETUP
   NumFont:=Sour.LoadFont(DataPath+NUMFONTFILE,$000000,3,5,'0');
   If (NumFont = NIL) then begin
      Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}NUMFONTFILE);
      Exit(False)
      end;
   Sour.SetFontSpacing(NumFont,1,1);
   FilesLoaded+=1; Update(NUMFONTFILE,FilesLoaded / FilesTotal);
   // Loaded numfont for fps
   TileGfx:=Sour.LoadImage(DataPath+FILE_TILES,$000000);
   If (TileGfx = NIL) then begin
      Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}FILE_TILES);
      Exit(False)
      end;
   FilesLoaded+=1; Update(FILE_TILES,FilesLoaded / FilesTotal);
   // Loaded tiles
   UIgfx:=Sour.LoadImage(DataPath+FILE_UI,$00FF00);
   If (UIgfx = NIL) then begin
      Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}FILE_UI);
      Exit(False)
      end;
   FilesLoaded+=1; Update(FILE_UI,FilesLoaded / FilesTotal);
   // UI loaded
   ColGfx:=Sour.LoadImage(DataPath+FILE_COLOURS,$808080);
   If (ColGfx = NIL) then begin
      Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}FILE_UI);
      Exit(False)
      end;
   FilesLoaded+=1; Update(FILE_COLOURS,FilesLoaded / FilesTotal);
   // Loaded colours (crystals). Load intro/outro slides
   For C:=0 to SLIDES_IN-1 do begin
       WriteStr(S,'intro/slide',C,'.png');
       Img:=Sour.LoadImage(DataPath+S,$000000);
       If (Img=NIL) then begin
          Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}S);
          Exit(False)
          end;
       SlideIn[C]:=Img;
       FilesLoaded+=1; Update(S,FilesLoaded / FilesTotal)
       end;
   For C:=0 to SLIDES_OUT-1 do begin
       WriteStr(S,'intro/out',C,'.png');
       Img:=Sour.LoadImage(DataPath+S,$000000);
       If (Img=NIL) then begin
          Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}S);
          Exit(False)
          end;
       SlideOut[C]:=Img;
       FilesLoaded+=1; Update(S,FilesLoaded / FilesTotal)
       end;
   // Loaded slides. Load charas
   For C:=0 to CHARAS-1 do begin
       Img:=Sour.LoadImage(DataPath+GFX_FILE[C],$000000);
       If (Img=NIL) then begin
          Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}GFX_FILE[C]);
          Exit(False)
          end;
       CharaGfx[C]:=Img;
       FilesLoaded+=1; Update(GFX_FILE[C],FilesLoaded / FilesTotal)
       end;
   // Loaded characters, time for them bullets
   For C:=0 to BULLETS-1 do begin
       WriteStr(S,'gfx/shot',C,'.png');
       Img:=Sour.LoadImage(DataPath+S,$000000);
       If (Img=NIL) then begin
          Status:=('Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}S);
          Exit(False)
          end;
       ShotGfx[C]:=Img;
       FilesLoaded+=1; Update(S,FilesLoaded / FilesTotal)
       end;
   // Loaded bullets, time for sfx
   If (Not NoSound) then begin
      For C:=0 to (WALL_SFX - 1) do begin
          WriteStr(S,'sfx/wall',C,'.wav');
          Samp:=Mix_LoadWAV(PChar(DataPath+S));
          If (Samp = NIL) then begin
             Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}S; Exit(False) end;
          Sfx[SFX_WALL+C]:=Samp;
          FilesLoaded+=1; Update(S,FilesLoaded / FilesTotal)
          end;
      For C:=0 to (METAL_SFX - 1) do begin
          WriteStr(S,'sfx/metal',C,'.wav');
          Samp:=Mix_LoadWAV(PChar(DataPath+S));
          If (Samp = NIL) then begin
             Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}S; Exit(False) end;
          Sfx[SFX_METAL+C]:=Samp;
          FilesLoaded+=1; Update(S,FilesLoaded / FilesTotal)
          end;
      For C:=0 to (DIE_SFX - 1) do begin
          WriteStr(S,'sfx/die',C,'.wav');
          Samp:=Mix_LoadWAV(PChar(DataPath+S));
          If (Samp = NIL) then begin
             Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}S; Exit(False) end;
          Sfx[SFX_DIE+C]:=Samp;
          FilesLoaded+=1; Update(S,FilesLoaded / FilesTotal)
          end;
      For C:=0 to (SHOT_SFX - 1) do begin
          WriteStr(S,'sfx/shot',C,'.wav');
          Samp:=Mix_LoadWAV(PChar(DataPath+S));
          If (Samp = NIL) then begin
             Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}S; Exit(False) end;
          Sfx[SFX_SHOT+C]:=Samp;
          FilesLoaded+=1; Update(S,FilesLoaded / FilesTotal)
          end;
      For C:=0 to (HIT_SFX - 1) do begin
          WriteStr(S,'sfx/hit',C,'.wav');
          Samp:=Mix_LoadWAV(PChar(DataPath+S));
          If (Samp = NIL) then begin
             Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}S; Exit(False) end;
          Sfx[SFX_HIT+C]:=Samp;
          FilesLoaded+=1; Update(S,FilesLoaded / FilesTotal)
          end;
      For C:=0 to (EXTRA_SFX - 1) do begin
          WriteStr(S,'sfx/extra',C,'.wav');
          Samp:=Mix_LoadWAV(PChar(DataPath+S));
          If (Samp = NIL) then begin
             Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}S; Exit(False) end;
          Sfx[SFX_EXTRA+C]:=Samp;
          FilesLoaded+=1; Update(S,FilesLoaded / FilesTotal)
          end
      end;
   // Sounds loaded (or skipped). Get them maps!
   For Y:=0 to (ORG_MAP_H-1) do For X:=0 to (ORG_MAP_W-1) do begin
       WriteStr(S,PATH_ORG,X,'-',Y,'.txt');
       R:=LoadRoom(DataPath+S);
       If (R = NIL) then begin
          Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}S; Exit(False) end;
       R^.X:=X; R^.Y:=Y; OrgRoom[X][Y]:=R;
       FilesLoaded+=1; Update(S,FilesLoaded / FilesTotal)
       end;
   For Y:=0 to (TUT_MAP_H-1) do For X:=0 to (TUT_MAP_W-1) do begin
       WriteStr(S,PATH_TUT,X,'-',Y,'.txt');
       R:=LoadRoom(DataPath+S);
       If (R = NIL) then begin
          Status:='Failed to load file: '+{$IFDEF PACKAGE}DataPath+{$ENDIF}S; Exit(False) end;
       R^.X:=X; R^.Y:=Y; TutRoom[X][Y]:=R;
       FilesLoaded+=1; Update(S,FilesLoaded / FilesTotal)
       end;
   Exit(True)
   end;

Procedure Free;
   Var C:LongWord;
   begin
   (* Since this is called only on program exit, it doesn't
      really matter if we forget anything. It will all be freed
      by the OS when the program dies, afterall. *)
   If (TitleGfx<>NIL) then Sour.FreeImage(TitleGfx);
   If (Font<>NIL) then Sour.FreeFont(Font);
   If (NumFont<>NIL) then Sour.FreeFont(NumFont);
   If (UIgfx<>NIL) then Sour.FreeImage(UIgfx);
   If (TileGfx<>NIL) then Sour.FreeImage(TileGfx);
   If (ColGfx<>NIL) then Sour.FreeImage(ColGfx);
   For C:=Low(SlideOut) to High(SlideOut) do
       If (SlideOut[C]<>NIL) then Sour.FreeImage(SlideOut[C]);
   For C:=Low(SlideIn) to High(SlideIn) do
       If (SlideIn[C]<>NIL) then Sour.FreeImage(SlideIn[C]);
   For C:=0 to CHARAS-1 do
       If (CharaGfx[C]<>NIL) then Sour.FreeImage(CharaGfx[C]);
   For C:=0 to BULLETS-1 do
       If (ShotGfx[C]<>NIL) then Sour.FreeImage(ShotGfx[C]);
   If (Not NoSound) then begin
      Mix_HaltChannel(-1);     //Halt all playing sounds
      Mix_AllocateChannels(0); //Free all sfx channels
      (* We do the two above to make sure no sound is being played.
         Freeing a sample (Chunk) that is being played is a bad idea. *)
      For C:=0 to (SOUNDS-1) do
          If (Sfx[C] <> NIL) then Mix_FreeChunk(Sfx[C])
      end;
   DestroyEntities(True);
   FreeRooms();
   end;

initialization
   Shutdown:=False; GameOn:=False; NoSound:=False;
   Tikku := 0;

end.

