unit configfiles; 

{$INCLUDE defines.inc}

interface
   uses Shared;

const HomeVar = {$IFDEF LINUX}   'HOME';    {$ELSE}
                {$IFDEF WINDOWS} 'APPDATA'; {$ELSE}
                {$FATAL Please set up the HomeVar, ConfDir and DirDelim constants before trying to compile for a new platform.} {$ENDIF} {$ENDIF}
      ConfDir = {$IFDEF LINUX}   '/.suve/colorful/'; {$ELSE}
                {$IFDEF WINDOWS} '\suve\colorful\';  {$ELSE}
                {$FATAL Didn't I just tell you something?} {$ENDIF} {$ENDIF}
      DirDelim = {$IFDEF LINUX}   '/'; {$ELSE}
                 {$IFDEF WINDOWS} '\'; {$ELSE}
                 {$FATAL Awful troll, 1/10.} {$ENDIF} {$ENDIF}

Var ConfPath, DataPath : AnsiString; //Configuration and data paths

Procedure SetPaths();

Function CheckConfPath():Boolean;

Function SaveIni():Boolean;
Function LoadIni():Boolean;
Function IHasIni():Boolean;

Procedure DefaultSettings();

Function SaveGame(GM:TGameMode):Boolean;
Function LoadGame(GM:TGameMode):Boolean;
Function IHasGame(GM:TGameMode):Boolean;

implementation
   uses SysUtils, IniFiles, Classes, SDL;

Const ConfFile = 'settings.ini';

// Check if ConfPath exists. If not, try to create it.
Function CheckConfPath():Boolean;
   begin
   If (Not DirectoryExists(ConfPath))
   then If (Not ForceDirectories(ConfPath)) then begin
           Writeln('Could not create configuration directory! (',ConfPath,')');
           Exit(False) end;
   Exit(True)
   end;

Function SaveGame(GM:TGameMode):Boolean;
   Var F:Text; C:uInt; Path:AnsiString;
   begin
   If (Not CheckConfPath()) then Exit(False);
   WriteStr(Path,ConfPath,GM,'.ini');
   Assign(F,Path); {$I-} Rewrite(F); {$I+}
   If (IOResult <> 0) then begin
      Writeln('Could not write savegame file! (',Path,')');
      Exit(False) end;
   { $I compiler switch controls generation of IO checking code. In "on" state
     (+), any error during IO operarions will result in a runtime error. In its
     "off" (-) state, no runtime errors are raised; instead, errorcode of the
     latest operation can be read by calling the IOResult() function. 0 means
     everything went fine. So, we turn off generating runtime errors during the
     rewrite operation and check the errorcode right after. If it's different
     than zero, something went wrong. We could check the IOResult errorcode
     table to provide the user with precise information what screwed up, but
     I don't really think anyone cares that much. }

   Writeln(F,'[Meta]');
   Writeln(F,'Version=',GAMEVERS);
   Writeln(F,'Gameworld=',GameMode);
   Writeln(F);
   Writeln(F,'[Colours]');
   For C:=0 to 7 do begin
       Write(F,ColourName[C],'=');
       If (ColState[C] = STATE_GIVEN)
          then Writeln(F,'given') else Writeln(F,'not')
       end;
   Writeln(F);
   Writeln(F,'[Switches]');
   For C:=Low(Switch) to High(Switch) do
       Writeln(F,Shared.IntToStr(C,2),'=',BoolToStr(Switch[C],'True','False'));
   Close(F); SaveExists[GM]:=True;
   Exit(True)
   end;

Function LoadGame(GM:TGameMode):Boolean;
   Var Ini:TIniFile; Str:TStringList; Path:AnsiString; C:uInt;
   begin
   WriteStr(Path,ConfPath,GM,'.ini');
   Ini:=TIniFile.Create(Path);
   If (Ini=NIL) then Exit(False);
   Str:=TStringList.Create();

   DestroyEntities(True); ResetGamestate();
   GameMode:=GM; GameOn:=True;

   Ini.ReadSectionValues('Colours',Str);
   For C:=0 to 7 do
       If (Str.Values[ColourName[C]]<>'given')
          then ColState[C]:=STATE_NONE
          else begin
          CentralPalette[C]:=PaletteColour[C]; PaletteColour[C]:=GreyColour;
          ColState[C]:=STATE_GIVEN; Given+=1
          end;

   Ini.ReadSectionValues('Switches',Str);
   For C:=Low(Switch) to High(Switch) do
       Switch[C]:=StrToBoolDef(Str.Values[Shared.IntToStr(C,2)],False);

   Ini.Destroy(); Str.Destroy();

   New(Hero,Create());
      Hero^.MaxHP:=HERO_HEALTH*(1+(Given/14)); Hero^.HP:=Hero^.MaxHP;
      Hero^.FirePower:=HERO_FIREPOWER*(1+(Given/14));
      Hero^.InvLength:=Trunc(HERO_INVUL*(1+(Given/14)));

   ChangeRoom(RespRoom[GM].X,RespRoom[GM].Y);
   Exit(True)
   end;

Function IHasGame(GM:TGameMode):Boolean;
   Var Path:AnsiString;
   begin WriteStr(Path,ConfPath,GM,'.ini'); Exit(FileExists(Path)) end;

Function SaveIni():Boolean;
   Var F:Text; K:TPlayerKey;
   begin
   If (Not CheckConfPath()) then Exit(False);
   Assign(F,ConfPath+ConfFile);
   {$I-} Rewrite(F); {$I+}
   If (IOResult <> 0) then Exit(False);
   Writeln(F,'[Info]');
   Writeln(F,'Version=',GAMEVERS);
   Writeln(F);
   Writeln(F,'[Window]');
   Writeln(F,'Fullscreen=',BoolToStr(Wnd_F,'True','False'));
   Writeln(F,'Width=',Wnd_W);
   Writeln(F,'Height=',Wnd_H);
   Writeln(F);
   Writeln(F,'[Audio]');
   Writeln(F,'Volume=',GetVol());
   Writeln(F);
   Writeln(F,'[Keybind]');
   For K:=Low(K) to High(K) do
       Writeln(F,K,'=',KeyBind[K]);
   Close(F); Exit(True);
   end;

Function LoadIni():Boolean;
   Var Ini:TIniFile; Str:TStringList; Name:AnsiString; K:TPlayerKey;
   begin
   Ini:=TIniFile.Create(ConfPath+ConfFile);
   If (Ini=NIL) then Exit(False);
   Str:=TStringList.Create();
   Ini.ReadSectionValues('Window',Str);
      Wnd_W:=StrToIntDef(Str.Values['Width'],WINDOW_W);
      Wnd_H:=StrToIntDef(Str.Values['Height'],WINDOW_H);
      Wnd_F:=StrToBoolDef(Str.Values['Fullscreen'],False);
   Ini.ReadSectionValues('Audio',Str);
      SetVol(StrToIntDef(Str.Values['Volume'],High(TVolLevel)),FALSE);
   Ini.ReadSectionValues('Keybind',Str);
   For K:=Low(K) to High(K) do begin
       WriteStr(Name,K);
       KeyBind[K]:=StrToIntDef(Str.Values[Name],SDLK_Escape)
       end;
   Ini.Destroy(); Str.Destroy();
   Exit(True)
   end;

Function IHasIni():Boolean;
   begin Exit(FileExists(ConfPath+ConfFile)) end;

Procedure DefaultSettings();
   begin
   KeyBind[KEY_UP]:=SDLK_UP;     KeyBind[KEY_RIGHT]:=SDLK_RIGHT;
   KeyBind[KEY_DOWN]:=SDLK_DOWN; KeyBind[KEY_LEFT]:=SDLK_LEFT;
   KeyBind[KEY_SHOOTLEFT]:=SDLK_Z;   KeyBind[KEY_SHOOTRIGHT]:=SDLK_X;
   KeyBind[KEY_VOLDOWN]:=SDLK_MINUS; KeyBind[KEY_VOLUP]:=SDLK_EQUALS;
   KeyBind[KEY_PAUSE]:=SDLK_P;
   // Key bindings
   Wnd_W:=WINDOW_W; Wnd_H:=WINDOW_H; Wnd_F:=False;
   // Window size
   SetVol(VolLevel_MAX,False) // Audio volume
   end;

Procedure SetPaths();
   begin
   ConfPath:=GetEnvironmentVariable(HomeVar)+ConfDir;
   (* Retrieve the appropriate place for storing the config files and
      add our folder tree to create the configuration path. *)
   
   {$IFNDEF PACKAGE}
   DataPath:=ExtractFileDir(ParamStr(0))+DirDelim+'..'+DirDelim+'..'+DirDelim;
   (* On most systems, ParamStr(0) returns the full path to the executable.
      ExtractFileDir() takes a string and returns everything until the last
      directory delimeter. So, we take the executable path, extract the dir,
      add the delimeter and voila, we now know where the executable resides.
      Since the executables are placed in bin/platform/, we need to go two
      folders up to reach the game's main directory. All the data files 
      (gfx, sfx, maps) should be found within subfolders of that location. *)
   
   {$ELSE}
   DataPath:='/usr/share/suve/colorful/';
   (* If we are building a package version, data files should be found in
      this pre-determined location. *)
   {$ENDIF}
   end;

initialization

finalization

end.

