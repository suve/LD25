(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2022 suve (a.k.a. Artur Frenszek Iwicki)
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
unit configfiles; 

{$INCLUDE defines.inc}

interface
	uses Shared;

Var
	ConfPath, OldConfPath: AnsiString; // Configuration (.ini, savegame) paths
	DataPath : AnsiString; // Location of assets

Procedure SetPaths();
Procedure CopyOldSavegames();
Function CheckConfPath():Boolean;

Type
	TIniVersion = (
		INIVER_1_0 = 1,
		INIVER_2_0 = 2
	);

Function SaveIni():Boolean;
Function LoadIni(Const Version: TIniVersion):Boolean;
Function IHasIni(Const Version: TIniVersion):Boolean;

Procedure DefaultSettings();

Function SaveGame(Const GM:TGameMode):Boolean;
Function LoadGame(Const GM:TGameMode):Boolean;
Function IHasGame(Const GM:TGameMode):Boolean;


Implementation
Uses
	Classes, IniFiles, SysUtils,
	SDL2,
	Colours, SDL1Keys;

Const
	ConfFileName = 'settings.ini';

// Check if ConfPath exists. If not, try to create it.
Function CheckConfPath():Boolean;
Begin
	If (Not DirectoryExists(ConfPath)) then begin
		If (Not ForceDirectories(ConfPath)) then begin
			Writeln('Could not create configuration directory! (',ConfPath,')');
			Exit(False) 
		end
	end;
	Exit(True)
End;

Function SaveGame(Const GM:TGameMode):Boolean;
Var
	F:Text; C:uInt; Path:AnsiString;
Begin
	If (Not CheckConfPath()) then Exit(False);
	
	WriteStr(Path,ConfPath,GM,'.ini');
	(* The $I compiler switch controls generation of IO checking code.
	 * In "on" state (+), any error during IO operarions will result in a runtime error.
	 * In its "off" (-) state, no runtime errors are raised; 
	 * instead, errorcode of the latest operation can be read by calling the IOResult() function. 
	 * Zero means everything went fine. So, we turn off generating runtime errors
	 * during the rewrite operation and check the errorcode right after. 
	 * If it's non-zero, something went wrong. We could check the IOResult errorcode table
	 * to provide the user with precise information what screwed up,
	 * but I don't really think anyone cares that much. *)
	Assign(F,Path); {$I-} Rewrite(F); {$I+}
	If (IOResult <> 0) then begin
		Writeln('Could not write savegame file! (',Path,')');
		Exit(False)
	end;

	Writeln(F,'[Meta]');
	Writeln(F,'Version=',GAMEVERS);
	Writeln(F,'Gameworld=',GameMode);
	Writeln(F);
	
	Writeln(F,'[Colours]');
	For C:=0 to 7 do begin
		Write(F,ColourName[C],'=');
		If (ColState[C] = STATE_GIVEN) then
			Writeln(F,'given')
		else
			Writeln(F,'not')
	end;
	Writeln(F);
	
	Writeln(F,'[Switches]');
	For C:=Low(Switch) to High(Switch) do Writeln(F,Shared.IntToStr(C,2),'=',BoolToStr(Switch[C],'True','False'));
	
	Close(F); SaveExists[GM]:=True;
	Exit(True)
End;

Function LoadGame(Const GM:TGameMode):Boolean;
Var
	Ini:TIniFile; Str:TStringList; Path:AnsiString; C:uInt;
Begin
	WriteStr(Path,ConfPath,GM,'.ini');
	Ini:=TIniFile.Create(Path);
	If (Ini=NIL) then Exit(False);
	
	Str:=TStringList.Create();

	DestroyEntities(True); ResetGamestate();
	GameMode:=GM; GameOn:=True;

	Ini.ReadSectionValues('Colours',Str);
	For C:=0 to 7 do begin
		If (Str.Values[ColourName[C]]<>'given') then
			ColState[C]:=STATE_NONE
		else begin
			CentralPalette[C]:=PaletteColour[C]; PaletteColour[C]:=GreyColour;
			ColState[C]:=STATE_GIVEN; Given+=1
		end
	end;

	Ini.ReadSectionValues('Switches',Str);
	For C:=Low(Switch) to High(Switch) do Switch[C]:=StrToBoolDef(Str.Values[Shared.IntToStr(C,2)],False);

	Ini.Destroy(); Str.Destroy();

	New(Hero,Create());
	Hero^.Level := Given;

	ChangeRoom(RespRoom[GM].X,RespRoom[GM].Y);
	Exit(True)
End;

Function IHasGame(Const GM:TGameMode):Boolean;
Var
	Path:AnsiString;
Begin
	WriteStr(Path, ConfPath, GM, '.ini');
	Exit(FileExists(Path))
End;

Function Capitalise(Const Str: AnsiString):AnsiString;
Begin
	Result := UpCase(Str[1]) + Copy(Str, 2, 256)
End;

Function SaveIni():Boolean;
Var
	F:Text;
	C:sInt;
	K:TPlayerKey;
Begin
	If (Not CheckConfPath()) then Exit(False);
	
	Assign(F, ConfPath + ConfFileName);
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
	For K:=Low(K) to High(K) do Writeln(F,K,'=',KeyBind[K]);
	Writeln(F);
	
	Writeln(F, '[Colours]');
	For C:=0 to 7 do Writeln(F, Capitalise(ColourName[C]),'=',ColourToStr(MapColour[C]));
	
	Close(F); Exit(True);
End;

Function ParseIni(Const Ini:TIniFile;Const GuessedVersion: sInt):Boolean;
Var
	Str:TStringList; 
	Version, C: sInt;
	KeyBindName, CapitalisedColourName:AnsiString;
	K:TPlayerKey;
Begin
	Str:=TStringList.Create();
	
	Ini.ReadSectionValues('Info',Str);
	Version:=Trunc(StrToFloatDef(Str.Values['Version'], GuessedVersion));
	
	Ini.ReadSectionValues('Window',Str);
	Wnd_W:=StrToIntDef(Str.Values['Width'],WINDOW_W);
	Wnd_H:=StrToIntDef(Str.Values['Height'],WINDOW_H);
	Wnd_F:=StrToBoolDef(Str.Values['Fullscreen'],False);
	
	Ini.ReadSectionValues('Audio',Str);
	SetVol(StrToIntDef(Str.Values['Volume'],High(TVolLevel)),FALSE);
	
	Ini.ReadSectionValues('Keybind',Str);
	For K:=Low(K) to High(K) do begin
		WriteStr(KeyBindName,K);
		KeyBind[K]:=StrToIntDef(Str.Values[KeyBindName], SDLK_Escape);
		
		If(Version = 1) then KeyBind[K]:=TranslateSDL1KeyToSDL2Keycode(KeyBind[K])
	end;
	
	If(Version = 2) then begin
		Ini.ReadSectionValues('Colours',Str);
		For C:=0 to 7 do begin
			CapitalisedColourName:=Capitalise(ColourName[C]);
			Try
				MapColour[C]:=StrToColour(Str.Values[CapitalisedColourName])
			Except
				Writeln(stderr, 'Unexpected value for colour ',ColourName[C],': "', Str.Values[CapitalisedColourName],'"')
			end
		end
	end;
	
	Ini.Destroy(); Str.Destroy();
	Exit(True)
End;

Function GetIniPath(Const Version: TIniVersion): AnsiString;
Begin
	If Version > INIVER_1_0 then
		Result := ConfPath + ConfFileName
	else
		Result := OldConfPath + ConfFileName
End;

Function LoadIni(Const Version: TIniVersion):Boolean;
Var
	Path: AnsiString;
	Ini: TIniFile;
Begin
	Ini:=TIniFile.Create(GetIniPath(Version));
	If Ini = NIL then Exit(False);

	Result := ParseIni(Ini, Ord(Version))
End;

Function IHasIni(Const Version: TIniVersion):Boolean;
Begin
	Result := FileExists(GetIniPath(Version))
End;

Procedure DefaultSettings();
Begin
	// Key bindings
	KeyBind[KEY_UP]:=SDLK_UP;         KeyBind[KEY_RIGHT]:=SDLK_RIGHT;
	KeyBind[KEY_DOWN]:=SDLK_DOWN;     KeyBind[KEY_LEFT]:=SDLK_LEFT;
	KeyBind[KEY_SHOOTLEFT]:=SDLK_Z;   KeyBind[KEY_SHOOTRIGHT]:=SDLK_X;
	KeyBind[KEY_VOLDOWN]:=SDLK_MINUS; KeyBind[KEY_VOLUP]:=SDLK_EQUALS;
	KeyBind[KEY_PAUSE]:=SDLK_P;
	
	// Window size
	Wnd_W:=WINDOW_W; Wnd_H:=WINDOW_H; Wnd_F:=False;
	
	// Audio volume
	SetVol(VolLevel_MAX,False) 
End;

Procedure SetOldConfPath();
Const
	// Consts used to determine the locations of v1.X config files.
	{$IFDEF LINUX}
		HomeVar = 'HOME';
		ConfDir = '/.suve/colorful/';
	{$ENDIF}
	{$IFDEF WINDOWS}
		HomeVar = 'APPDATA';
		ConfDir = '\suve\colorful';
	{$ENDIF}
Begin
	OldConfPath := GetEnvironmentVariable(HomeVar) + ConfDir
End;

Procedure SetPaths();
Var
	PrefPath: PChar;
Begin
	SetOldConfPath();

	PrefPath := SDL_GetPrefPath(PChar('suve'), PChar('colorful'));
	ConfPath := AnsiString(PrefPath);
	SDL_Free(PrefPath);

	{$IFNDEF PACKAGE}
		(* On most systems, ParamStr(0) returns the full path to the executable.
		 * ExtractFileDir() takes a string and returns everything until the last
		 * directory delimeter. So, we take the executable path, extract the dir,
		 * add the delimeter and voila, we now know where the executable resides. *)
		DataPath := ExtractFileDir(ParamStr(0)) + System.DirectorySeparator;
		{$IFNDEF DEVELOPER} 
			(* Since the executables are placed in bin/platform/, we need to go two
			 * folders up to reach the game's main directory. All the data files 
			 * (gfx, sfx, maps) should be found within subfolders of that location. *)
			DataPath += '..' + System.DirectorySeparator + '..' + System.DirectorySeparator;
		{$ENDIF}
	{$ELSE}
		(* If we are building a package version, data files should be found in
		 * this pre-determined location. *)
		DataPath:='/usr/share/suve/colorful/';
	{$ENDIF}
End;

Procedure CopyFile(OldPath, NewPath: AnsiString);
Const
	BufferSize = 4096;
Var
	Buffer: Array[0 .. (BufferSize - 1)] of Char;
	ReadHandle, WriteHandle: THandle;
	Count: sInt;
Begin
	ReadHandle := FileOpen(OldPath, fmOpenRead);
	If ReadHandle = -1 then Exit();

	// FPC does not have a "create file if it does not exist yet" function,
	// so let's just do this and try to live with the TOCTTOU issue.
	If FileExists(NewPath) then Exit();
	WriteHandle := FileCreate(NewPath, fmOpenWrite, &660);
	If WriteHandle = -1 then Exit();

	While True do begin
		Count := FileRead(ReadHandle, Buffer, BufferSize);
		If Count <= 0 then Break;

		FileWrite(WriteHandle, Buffer, Count)
	end;

	FileClose(WriteHandle);
	FileClose(ReadHandle)
End;

Procedure CopyOldSavegames();
Var
	GM: TGameMode;
	OldPath, NewPath: AnsiString;
Begin
	// Don't bother checking individual files if the old configuration directory doesn't exist.
	If Not DirectoryExists(OldConfPath) then Exit();

	// v1.X had only GM_TUTORIAL and GM_ORIGINAL. Do not check for GM_NEWWORLD.
	For GM := GM_TUTORIAL to GM_ORIGINAL do begin
		WriteStr(OldPath, OldConfPath, GM, '.ini');
		WriteStr(NewPath, ConfPath, GM, '.ini');
		CopyFile(OldPath, NewPath)
	end
End;

end.

