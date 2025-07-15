(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2024 suve (a.k.a. Artur Frenszek-Iwicki)
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
	ConfPath: AnsiString; // Configuration (.ini, savegame) paths - v2.X

	{$IFDEF LD25_COMPAT_V1}
		OldConfPath: AnsiString; // Configuration (.ini, savegame) paths - legacy v1.X location
	{$ENDIF}

	{$IFNDEF ANDROID}
		DataPath : AnsiString; // Location of assets. On Android, SDL auto-locates assets for us
	{$ENDIF}

Procedure SetPaths();

{$IFDEF LD25_COMPAT_V1}
Procedure CopyOldSavegames();
{$ENDIF}

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
	{$IFDEF LD25_COMPAT_V1} SDL1Keys, {$ENDIF}
	BuildConfig, Colours, Controllers, Rendering, Stats;

Const
	ConfFileName = 'settings.ini';
	Ordinals: Array[0..7] of AnsiString = (
		'first', 'second', 'third', 'fourth', 'fifth', 'sixth', 'seventh', 'eighth'
	);
	ControllerMovementModeNames: Array[TControllerMovementMode] of AnsiString = (
		'invalid', 'left-stick', 'right-stick', 'dpad'
	);

	DEFAULT_DEADZONE = 0.25;

// Check if ConfPath exists. If not, try to create it.
Function CheckConfPath():Boolean;
Begin
	If (Not DirectoryExists(ConfPath)) then begin
		If (Not ForceDirectories(ConfPath)) then begin
			SDL_Log('Could''t create the configuration directory! (%s)', [PChar(ConfPath)]);
			Exit(False) 
		end
	end;
	Exit(True)
End;

Function SaveGame(Const GM:TGameMode):Boolean;
Var
	F: Text;
	Idx: uInt;
	Path: AnsiString;
	Value: uInt;
	FloatValue: Double;
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
		SDL_Log('Could not write savegame file! (%s)', [PChar(Path)]);
		Exit(False)
	end;

	Writeln(F,'[Meta]');
	Writeln(F,'Version=',GAMEVERS);
	Writeln(F,'Gameworld=',GameMode);
	Writeln(F);

	Writeln(F,'[Colours]');
	For Idx:=0 to 7 do begin
		Write(F,ColourName[Idx],'=');
		If (ColState[Idx] = STATE_GIVEN) then
			Writeln(F,'given')
		else
			Writeln(F,'not')
	end;
	Writeln(F);

	Writeln(F, '[History]');
	For Idx:=1 to Given do
		Writeln(F, Ordinals[Idx-1], '=', ColourIndexToName(ColOrder[Idx-1]));
	Writeln(F);

	Writeln(F, '[Stats]');
	If Stats.TotalTime.Get(@Value) then Writeln(F, 'TotalTime=', Value);
	If Stats.HitsTaken.Get(@Value) then Writeln(F, 'HitsTaken=', Value);
	If Stats.TimesDied.Get(@Value) then Writeln(F, 'TimesDied=', Value);
	If Stats.KillsMade.Get(@Value) then Writeln(F, 'KillsMade=', Value);
	If Stats.ShotsFired.Get(@Value) then Writeln(F, 'ShotsFired=', Value);
	If Stats.ShotsHit.Get(@Value) then Writeln(F, 'ShotsHit=', Value);
	If Stats.DistanceTravelled.Get(@FloatValue) then Writeln(F, 'DistanceTravelled=', FloatValue:0:3);
	Writeln(F);

	Writeln(F,'[Switches]');
	For Idx:=Low(Switch) to High(Switch) do
		Writeln(F,Shared.IntToStr(Idx,2),'=',BoolToStr(Switch[Idx],'True','False'));

	Close(F); SaveExists[GM]:=True;
	Exit(True)
End;

Procedure ReadStatsEntry(Ref: POptionalUInt; StrValue: AnsiString);
Var
	NumValue: uInt;
Begin
	Try
		NumValue := SysUtils.
			{$IFDEF CPU64} StrToQWord {$ELSE} StrToDWord {$ENDIF}
			(StrValue);
		Ref^.SetTo(NumValue)
	Except
		On EConvertError do Ref^.Unset()
	End
End;

Procedure ReadStatsEntryFloat(Ref: POptionalFloat; StrValue: AnsiString);
Var
	NumValue: Double;
Begin
	Try
		NumValue := SysUtils.StrToFloat(StrValue);
		Ref^.SetTo(NumValue)
	Except
		On EConvertError do Ref^.Unset()
	End
End;

Function LoadGame(Const GM:TGameMode):Boolean;
Var
	Ini: TIniFile;
	Str: TStringList;
	Path: AnsiString;
	C: uInt;
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

	Ini.ReadSectionValues('History', Str);
	For C:=0 to 7 do ColOrder[C] := ColourNameToIndex(Str.Values[Ordinals[C]]);
	SanitizeColourOrder();

	Stats.UnsetSaveStats();
	Ini.ReadSectionValues('Stats', Str);
	ReadStatsEntry(@Stats.TotalTime, Str.Values['TotalTime']);
	ReadStatsEntry(@Stats.HitsTaken, Str.Values['HitsTaken']);
	ReadStatsEntry(@Stats.TimesDied, Str.Values['TimesDied']);
	ReadStatsEntry(@Stats.KillsMade, Str.Values['KillsMade']);
	ReadStatsEntry(@Stats.ShotsFired, Str.Values['ShotsFired']);
	ReadStatsEntry(@Stats.ShotsHit, Str.Values['ShotsHit']);
	ReadStatsEntryFloat(@Stats.DistanceTravelled, Str.Values['DistanceTravelled']);

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
	Value: uInt;
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

	Writeln(F, '[Gamepad]');
	Writeln(F, 'DeadZone=', Controllers.DeadZone.Percentage:0:4);
	Writeln(F, 'Rumble=', BoolToStr(Controllers.RumbleEnabled, 'True', 'False'));
	Writeln(F, 'Movement=', ControllerMovementModeNames[PadMovementMode]);
	Writeln(F, 'ShootLeft=', PadShootLeft.Serialize());
	Writeln(F, 'ShootRight=', PadShootRight.Serialize());
	Writeln(F);

	{$IFDEF LD25_MOBILE}
		Writeln(F, '[TouchControls]');
		Writeln(F, 'Swapped=', BoolToStr(SwapTouchControls, 'True', 'False'));
		Writeln(F);
	{$ENDIF}

	Writeln(F, '[Colours]');
	For C:=0 to 7 do Writeln(F, Capitalise(ColourName[C]),'=',ColourToStr(MapColour[C]));
	Writeln(F);

	Writeln(F, '[Stats]');
	If Stats.BestTime.Get(@Value) then Writeln(F, 'BestTimeClassic=', Value);

	Close(F); Exit(True);
End;

Function ParseIni(Const Ini:TIniFile;Const GuessedVersion: sInt):Boolean;
Var
	Str:TStringList; 
	Version, C: sInt;
	KeyBindName, CapitalisedColourName:AnsiString;
	K:TPlayerKey;
	MoveMode: TControllerMovementMode;
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

		{$IFDEF LD25_COMPAT_V1}
			If(Version = 1) then KeyBind[K]:=TranslateSDL1KeyToSDL2Keycode(KeyBind[K])
		{$ENDIF}
	end;
	
	If(Version = 2) then begin
		(*
		 * FIXME: The game should differentiate between v2.1 and v2.2 config files
		 *        so it can skip the gamepad section when loading older configs.
		 *
		 *        Alternatively, the parsing code here could be modified to enable
		 *        differentiating between entries that are missing, and entries
		 *        that have an empty-string value; then, missing entries could be
		 *        set to a default value.
		 *)
		Ini.ReadSectionValues('Gamepad', Str);
		Controllers.DeadZone.Percentage:=StrToFloatDef(Str.Values['DeadZone'], DEFAULT_DEADZONE);
		Controllers.RumbleEnabled:=StrToBoolDef(Str.Values['Rumble'],True);
		PadShootLeft.Deserialize(Str.Values['ShootLeft']);
		PadShootRight.Deserialize(Str.Values['ShootRight']);

		If(Str.Values['Movement'] <> '') then begin
			PadMovementMode := CMM_INVALID;
			For MoveMode := CMM_LEFT_STICK to CMM_DPAD do
				If(Str.Values['Movement'] = ControllerMovementModeNames[MoveMode]) then begin
					PadMovementMode := MoveMode;
					Break
				end
		end;

		{$IFDEF LD25_MOBILE}
			Ini.ReadSectionValues('TouchControls', Str);
			SwapTouchControls:=StrToBoolDef(Str.Values['Swapped'], False);
		{$ENDIF}

		Ini.ReadSectionValues('Colours',Str);
		For C:=0 to 7 do begin
			CapitalisedColourName:=Capitalise(ColourName[C]);
			Try
				MapColour[C]:=StrToColour(Str.Values[CapitalisedColourName])
			Except
				Writeln(stderr, 'Unexpected value for colour ',ColourName[C],': "', Str.Values[CapitalisedColourName],'"')
			end
		end;

		Ini.ReadSectionValues('Stats', Str);
		ReadStatsEntry(@Stats.BestTime, Str.Values['BestTimeClassic']);
	end;
	
	Ini.Destroy(); Str.Destroy();
	Exit(True)
End;

Function GetIniPath(Const Version: TIniVersion): AnsiString;
Begin
	If Version > INIVER_1_0 then
		Result := ConfPath + ConfFileName
	else
		{$IFDEF LD25_COMPAT_V1}
			Result := OldConfPath + ConfFileName
		{$ELSE}
			Result := '/dev/null'
		{$ENDIF}
End;

Function LoadIni(Const Version: TIniVersion):Boolean;
Var
	Ini: TIniFile;
Begin
	Ini:=TIniFile.Create(GetIniPath(Version));
	If Ini = NIL then Exit(False);

	Result := ParseIni(Ini, Ord(Version))
End;

Function IHasIni(Const Version: TIniVersion):Boolean;
Begin
	{$IFDEF LD25_COMPAT_V1}
		Result := FileExists(GetIniPath(Version))
	{$ELSE}
		If Version > INIVER_1_0 then
			Result := FileExists(GetIniPath(Version))
		else
			Result := False
	{$ENDIF}
End;

Procedure DefaultSettings();
Begin
	// Key bindings
	KeyBind[KEY_UP]:=SDLK_UP;         KeyBind[KEY_RIGHT]:=SDLK_RIGHT;
	KeyBind[KEY_DOWN]:=SDLK_DOWN;     KeyBind[KEY_LEFT]:=SDLK_LEFT;
	KeyBind[KEY_SHOOTLEFT]:=SDLK_Z;   KeyBind[KEY_SHOOTRIGHT]:=SDLK_X;
	KeyBind[KEY_VOLDOWN]:=SDLK_MINUS; KeyBind[KEY_VOLUP]:=SDLK_EQUALS;
	KeyBind[KEY_PAUSE]:=SDLK_P;

	// Gamepad bindings
	Controllers.DeadZone.Percentage := DEFAULT_DEADZONE;
	Controllers.RumbleEnabled := True;
	PadMovementMode := CMM_LEFT_STICK;
	PadShootLeft.SetButton(SDL_CONTROLLER_BUTTON_A);
	PadShootRight.SetButton(SDL_CONTROLLER_BUTTON_B);

	// Window size
	Wnd_W:=WINDOW_W; Wnd_H:=WINDOW_H; Wnd_F:=False;

	// Audio volume
	SetVol(VOL_LEVEL_MAX,False);

	// Colour values
	ResetMapColoursToDefault();

	{$IFDEF LD25_MOBILE}
	SwapTouchControls := False;
	{$ENDIF}

	Stats.UnsetGlobalStats()
End;

{$IFDEF LD25_COMPAT_V1}
Procedure SetOldConfPath();
Const
	// Consts used to determine the locations of v1.X config files.
	{$IFDEF LINUX}
		HomeVar = 'HOME';
		ConfDir = '/.suve/colorful/';
	{$ENDIF}
	{$IFDEF WINDOWS}
		HomeVar = 'APPDATA';
		ConfDir = '\suve\colorful\';
	{$ENDIF}
Begin
	OldConfPath := GetEnvironmentVariable(HomeVar) + ConfDir
End;
{$ENDIF}

Procedure SetPaths();
Var
	{$IFNDEF ANDROID} BasePath: PChar; {$ENDIF}
	PrefPath: PChar;
Begin
	{$IFDEF LD25_COMPAT_V1}
		SetOldConfPath();
	{$ENDIF}

	PrefPath := SDL_GetPrefPath(PChar('suve'), PChar('colorful'));
	ConfPath := AnsiString(PrefPath);
	SDL_Free(PrefPath);

	{$IFNDEF ANDROID}
		{$IFDEF LD25_ASSETS_SYSTEMWIDE}
			(*
			 * If we are building in "systemwide" mode, data files should be found
			 * in this pre-determined location.
			 *)
			DataPath := BuildConfig.Prefix + '/share/suve/colorful/';
		{$ELSE}
			(*
			 * If we're not building in "systemwide" mode, grab the path to the executable.
			 * For "bundle" mode, go two directories up. Otherwise, do nothing.
			 *)
			BasePath := SDL_GetBasePath();
			DataPath := AnsiString(BasePath);
			{$IFDEF LD25_ASSETS_BUNDLE}
				DataPath += '..' + System.DirectorySeparator + '..' + System.DirectorySeparator;
			{$ENDIF}

			SDL_Free(BasePath);
		{$ENDIF}
	{$ENDIF}
End;

{$IFDEF LD25_COMPAT_V1}
Function CopyFile(OldPath, NewPath: AnsiString): Boolean;
Const
	BufferSize = 4096;
	ErroneousHandle = THandle(-1);
Var
	Buffer: Array[0 .. (BufferSize - 1)] of Char;
	ReadHandle, WriteHandle: THandle;
	ReadCount, WriteCount: sInt;

	function DoIt(): Boolean;
	begin
		ReadHandle := FileOpen(OldPath, fmOpenRead);
		If ReadHandle = ErroneousHandle then Exit(False);

		(*
		 * FPC does not have a "create file if it does not exist yet" function,
		 * so let's just do this and try to live with the TOCTTOU issue.
		 *)
		If FileExists(NewPath) then Exit(False);

		WriteHandle := FileCreate(NewPath, fmOpenWrite, &660);
		If WriteHandle = ErroneousHandle then Exit(False);

		While True do begin
			ReadCount := FileRead(ReadHandle, Buffer, BufferSize);
			If ReadCount > 0 then begin
				WriteCount := FileWrite(WriteHandle, Buffer, ReadCount);
				If WriteCount < ReadCount then Exit(False)
			end else
			If ReadCount < 0 then
				Exit(False)
			else
				Break
		end;

		Result := True
	end;

Begin
	ReadHandle := ErroneousHandle;
	WriteHandle := ErroneousHandle;

	Result := DoIt();

	If WriteHandle <> ErroneousHandle then FileClose(WriteHandle);
	if ReadHandle <> ErroneousHandle then FileClose(ReadHandle)
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
{$ENDIF}

end.

