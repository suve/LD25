unit shared; {$MODE OBJFPC} {$COPERATORS ON} {$WRITEABLECONST OFF} {$TYPEDADDRESS ON}

interface

uses SDL, Sour, GL, Objects, BASS;

// A shitload of constants - but hey, this is the 'shared' unit, isn't it?

const GAMENAME = 'Colorful'; GAMEAUTH = 'suve';
      GAMEVERS = '1.0';      GAMEDATE = {$INCLUDE %DATE%}+', '+{$INCLUDE %TIME%};

      FPS_LIMIT = 120; TICKS_MINIMUM = 1000 div FPS_LIMIT;

      WINDOW_W = 640; WINDOW_H = 640;
      RESOL_W = 320; RESOL_H = 320;

      TILE_W = 16; TILE_H = 16; TILE_S = ((TILE_W + TILE_H) div 2);
      ROOM_W = 20; ROOM_H = 20;
      MAP_W = 7; MAP_H = 7;

      HERO_SPEED = TILE_S * 5; HERO_HEALTH = 50; HERO_FIREPOWER = 5; HERO_INVUL = 500;

      GFX_HERO = 0; GFX_ENEM = 1;
      CHARAS = 8; BULLETS = 5; SLIDES_IN = 6; SLIDES_OUT = 10;
      OTHERS = 3; //tiles, ui, colours

      WALL_SFX = 4; METAL_SFX = 3; DIE_SFX = 6; SHOT_SFX = 4; HIT_SFX = 1; EXTRA_SFX = 3;
      SFX_WALL = 0; SFX_METAL = SFX_WALL+WALL_SFX; SFX_DIE = SFX_METAL+METAL_SFX;
      SFX_SHOT = SFX_DIE+DIE_SFX; SFX_HIT = SFX_SHOT + SHOT_SFX; SFX_EXTRA = SFX_HIT+HIT_SFX;
      SOUNDS = SFX_EXTRA + EXTRA_SFX;

      FILES_TO_LOAD = CHARAS + BULLETS + SOUNDS + OTHERS + SLIDES_IN + SLIDES_OUT;

      AnimFPS = 16; AnimTime = 1000 div AnimFPS;
      GibSpeed = TILE_S*8; GIB_X = 4; GIB_Y = 4;
      DeathLength = 2500; WOMAN = 8;

Const UIcolour : Array[0..7] of LongWord =
      ($505050FF,$0000FFFF,$00FF00FF,$00FFFFFF,$FF0000FF,$FF00FFFF,$FFFF00FF,$FFFFFFFF);
      MapColour : Array[0..7] of LongWord =
      ($323232, $10186A, $299C00, $009A9A, $7A0818, $94188B, $FFDE5A, $DADADA);
      WhiteColour : Sour.TColour = (R: 255; G: 255; B: 255; A: 255);
      GreyColour : Sour.TColour = (R: 128; G: 128; B: 128; A: 255);

Type TPlayerKey = (KEY_UP, KEY_RIGHT, KEY_DOWN, KEY_LEFT, KEY_Z, KEY_X, KEY_C);
     TEnemyType = (ENEM_DRONE,ENEM_BASHER,ENEM_BALL,ENEM_SPITTER,ENEM_SPAMMER,
                   ENEM_GENERATOR, ENEM_TURRET);
     TColState = (STATE_NONE,STATE_PICKED,STATE_GIVEN);
     TCrystal = record
     IsSet : Boolean;
     mX, mY: LongInt;
     Col : LongWord
     end;

// Progstate and gamestate variables. This isn't a project big enough to actually
// require having a separate game controller class. I'll just keep everything global...

var Screen : PSDL_Surface;
    TitleGfx, TileGfx, UIgfx, ColGfx : Sour.PImage;
    Font, NumFont : Sour.PFont;
    CharaGfx : Array[0..CHARAS-1] of Sour.PImage;
    ShotGfx  : Array[0..BULLETS-1] of Sour.PImage;
    Hero : PPlayer;
    PBul, EBul : Array of PBullet;
    Mob  : Array of PEntity;
    Gib  : Array of PGib;
    Ev   : TSDL_Event;
    Key  : Array[TPlayerKey] of Boolean;
    Sfx  : Array[0..SOUNDS-1] of HSAMPLE;
    Switch : Array[0..99] of Boolean;
    ColState : Array[0..7] of TColState;
    Crystal : TCrystal;
    PaletteColour : Array[0..7] of Sour.TColour;
    CentralPalette : Array[0..7] of Sour.TColour;
    RoomPalette, DeadTime, Carried, Given : LongInt;
    SlideIn  : Array[0..SLIDES_IN-1] of Sour.PImage;
    SlideOut : Array[0..SLIDES_OUT-1] of Sour.PImage;

Type UpdateProc = Procedure(Name:AnsiString;Perc:Double);

// The name is obvious, duh
Procedure GetDeltaTime(Out Time:LongWord);
Procedure GetDeltaTime(Out Time,Ticks:LongWord);

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
Function IntToStr(Num:LongWord;Digits:LongWord=0;Chr:Char='0'):AnsiString;
Function StrToInt(S:AnsiString):Int64;

// Play a sound
Procedure PlaySfx(ID:LongWord);

// Place a bullet, duh
Procedure PlaceBullet(Owner:PEntity;XV,YV,Pow:Double;Tp:LongWord);

// Spawn enemies
Procedure SpawnEnemy(Tp:TEnemyType;mapX,mapY:LongInt;SwitchNum:LongInt=-1);

// Someone got killed - place gibs!
Procedure PlaceGibs(E:PEntity);

// Load gfx and sfx, melady
Function LoadBasics(Out Status:AnsiString):Boolean;
Function LoadRes(Out Status:AnsiString; Update : UpdateProc = NIL):Boolean;

// Free resources
Procedure Free();

implementation

var Tikku : LongWord;

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

Procedure PlaySfx(ID:LongWord);
   Var Chan:HCHANNEL;
   begin
   If (ID>=SOUNDS) then Exit;
   Chan:=BASS_SampleGetChannel(Sfx[ID],False);
   If (Chan = 0) then Exit;
   BASS_ChannelPlay(Chan,True)
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

const GFX_TITLE = 'gfx/title.png'; FILE_FONT = 'gfx/font.png';
      GFX_FILE : Array[0..CHARAS-1] of String = (
      'gfx/hero.png','gfx/enem0.png','gfx/enem1.png','gfx/enem2.png','gfx/enem3.png',
      'gfx/enem4.png','gfx/enem5.png','gfx/enem6.png');
      FILE_TILES = 'gfx/tiles.png'; FILE_UI = 'gfx/ui.png'; FILE_COLOURS = 'gfx/colours.png';
      NUMFONTFILE = 'gfx/numbers.png';

Function LoadBasics(Out Status:AnsiString):Boolean;
   begin
   TitleGfx:=Sour.LoadImage(GFX_TITLE);
   If (TitleGfx=NIL) then begin Status:=('Failed to load file: '+GFX_TITLE); Exit(False) end;
   Font:=Sour.LoadFont(FILE_FONT,$000000,5,7,#32);
   If (Font=NIL) then begin Status:=('Failed to load file: '+FILE_FONT); Exit(False) end;
   Sour.SetFontSpacing(Font,1,1);
   Exit(True)
   end;

Function LoadRes(Out Status:AnsiString; Update : UpdateProc = NIL):Boolean;
   Var FilesLoaded, C:LongWord; Img:Sour.PImage; S:AnsiString; Samp:HSAMPLE;
   begin
   FilesLoaded:=0;
   // SOME MINOR SETUP
   NumFont:=Sour.LoadFont(NUMFONTFILE,$000000,3,5,'0');
   If (NumFont = NIL) then begin
      Status:=('Failed to load file: '+NUMFONTFILE);
      Exit(False)
      end;
   Sour.SetFontSpacing(NumFont,1,1);
   // Loaded numfont for fps
   TileGfx:=Sour.LoadImage(FILE_TILES,$000000);
   If (TileGfx = NIL) then begin
      Status:=('Failed to load file: '+FILE_TILES);
      Exit(False)
      end;
   FilesLoaded+=1; Update(FILE_TILES,FilesLoaded / FILES_TO_LOAD);
   // Loaded tiles
   UIgfx:=Sour.LoadImage(FILE_UI,$00FF00);
   If (UIgfx = NIL) then begin
      Status:=('Failed to load file: '+FILE_UI);
      Exit(False)
      end;
   FilesLoaded+=1; Update(FILE_UI,FilesLoaded / FILES_TO_LOAD);
   // UI loaded
   ColGfx:=Sour.LoadImage(FILE_COLOURS,$808080);
   If (ColGfx = NIL) then begin
      Status:=('Failed to load file: '+FILE_UI);
      Exit(False)
      end;
   FilesLoaded+=1; Update(FILE_COLOURS,FilesLoaded / FILES_TO_LOAD);
   // Loaded colours (crystals). Load intro/outro slides
   For C:=0 to SLIDES_IN-1 do begin
       S:='intro/slide'+IntToStr(C)+'.png';
       Img:=Sour.LoadImage(S,$000000);
       If (Img=NIL) then begin
          Status:=('Failed to load file: '+S);
          Exit(False)
          end;
       SlideIn[C]:=Img; FilesLoaded+=1;
       Update(S,FilesLoaded / FILES_TO_LOAD)
       end;
   For C:=0 to SLIDES_OUT-1 do begin
       S:='intro/out'+IntToStr(C)+'.png';
       Img:=Sour.LoadImage(S,$000000);
       If (Img=NIL) then begin
          Status:=('Failed to load file: '+S);
          Exit(False)
          end;
       SlideOut[C]:=Img; FilesLoaded+=1;
       Update(S,FilesLoaded / FILES_TO_LOAD)
       end;
   // Loaded slides. Load charas
   For C:=0 to CHARAS-1 do begin
       Img:=Sour.LoadImage(GFX_FILE[C],$000000);
       If (Img=NIL) then begin
          Status:=('Failed to load file: '+GFX_FILE[C]);
          Exit(False)
          end;
       CharaGfx[C]:=Img; FilesLoaded+=1;
       Update(GFX_FILE[C],FilesLoaded / FILES_TO_LOAD)
       end;
   // Loaded characters, time for them bullets
   For C:=0 to BULLETS-1 do begin
       WriteStr(S,'gfx/shot',C,'.png');
       Img:=Sour.LoadImage(S,$000000);
       If (Img=NIL) then begin
          Status:=('Failed to load file: '+S);
          Exit(False)
          end;
       ShotGfx[C]:=Img; FilesLoaded+=1;
       Update(S,FilesLoaded / FILES_TO_LOAD)
       end;
   // Loaded bullets, time for sfx
   For C:=0 to (WALL_SFX - 1) do begin
       S:='sfx/wall'+IntToStr(C)+'.wav';
       Samp:=BASS_SampleLoad(FALSE,PChar(S),0,0,64,0);
       If (Samp = 0) then begin
          Status:='Failed to load file: '+S; Exit(False) end;
       Sfx[SFX_WALL+C]:=Samp
       end;
   For C:=0 to (METAL_SFX - 1) do begin
       S:='sfx/metal'+IntToStr(C)+'.wav';
       Samp:=BASS_SampleLoad(FALSE,PChar(S),0,0,64,0);
       If (Samp = 0) then begin
          Status:='Failed to load file: '+S; Exit(False) end;
       Sfx[SFX_METAL+C]:=Samp
       end;
   For C:=0 to (DIE_SFX - 1) do begin
       S:='sfx/die'+IntToStr(C)+'.wav';
       Samp:=BASS_SampleLoad(FALSE,PChar(S),0,0,64,0);
       If (Samp = 0) then begin
          Status:='Failed to load file: '+S; Exit(False) end;
       Sfx[SFX_DIE+C]:=Samp
       end;
   For C:=0 to (SHOT_SFX - 1) do begin
       S:='sfx/shot'+IntToStr(C)+'.wav';
       Samp:=BASS_SampleLoad(FALSE,PChar(S),0,0,64,0);
       If (Samp = 0) then begin
          Status:='Failed to load file: '+S; Exit(False) end;
       Sfx[SFX_SHOT+C]:=Samp
       end;
   For C:=0 to (HIT_SFX - 1) do begin
       S:='sfx/hit'+IntToStr(C)+'.wav';
       Samp:=BASS_SampleLoad(FALSE,PChar(S),0,0,64,0);
       If (Samp = 0) then begin
          Status:='Failed to load file: '+S; Exit(False) end;
       Sfx[SFX_HIT+C]:=Samp
       end;
   For C:=0 to (EXTRA_SFX - 1) do begin
       S:='sfx/extra'+IntToStr(C)+'.wav';
       Samp:=BASS_SampleLoad(FALSE,PChar(S),0,0,64,0);
       If (Samp = 0) then begin
          Status:='Failed to load file: '+S; Exit(False) end;
       Sfx[SFX_EXTRA+C]:=Samp
       end;
   Exit(True)
   end;

Procedure Free;
   Var C:LongWord;
   begin
   // Don't have time to add everything, lol
   If (TitleGfx<>NIL) then Sour.FreeImage(TitleGfx);
   If (Font<>NIL) then Sour.FreeFont(Font);
   For C:=0 to CHARAS-1 do
       If (CharaGfx[C]<>NIL) then Sour.FreeImage(CharaGfx[C]);
   For C:=0 to BULLETS-1 do
       If (ShotGfx[C]<>NIL) then Sour.FreeImage(ShotGfx[C]);
   BASS_Free()
   end;

initialization
   For Tikku:=0 to 7 do PaletteColour[Tikku]:=Sour.MakeColour(MapColour[Tikku]);
   For Tikku:=0 to 7 do CentralPalette[Tikku]:=Sour.MakeColour(127,127,127);
   For Tikku:=Low(ColState) to High(ColState) do ColState[Tikku]:=STATE_NONE;
   For Tikku:=Low(Switch) to High(Switch) do Switch[Tikku]:=False;
   Carried:=0; Given:=0; Tikku := 0;

end.

