(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2022 suve (a.k.a. Artur Frenszek-Iwicki)
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
{$IFNDEF ANDROID}
	program ld25;
{$ELSE}
	library ld25;
{$ENDIF}

{$INCLUDE defines.inc}

uses
	SysUtils, Math, ctypes,
	SDL2, SDL2_image, SDL2_mixer,
	Assets, Colours, ConfigFiles, FloatingText, Fonts, Game, Images, Objects,
	MathUtils, Menus, Rendering, Rooms, Shared, Slides
;


Var
	MenuChoice:Char;

Procedure DrawTitle();
Const
	VersionText = 'V.' + GAMEVERS
		{$IFDEF LD25_DEBUG} + ' // DEBUG @ ' + {$INCLUDE %DATE%} + ', ' + {$INCLUDE %TIME%}{$ENDIF}
	;
Var
	Dst: TSDL_Rect;
Begin
	Dst.X := 0; Dst.Y := 0;
	Dst.W := TitleGfx^.W; Dst.H := TitleGfx^.H;
	DrawImage(TitleGfx, NIL, @Dst, NIL);
	
	Font^.Scale := 1;
	PrintText(VersionText, Assets.Font, (RESOL_W div 2), 82, ALIGN_CENTRE, ALIGN_MIDDLE, @WhiteColour)
End;

Procedure PrintMenuText(Const Text:AnsiString; Const X, Y:sInt; Const AlignX: THorizontalAlign; Const Colour: PSDL_Colour; Out Rect: TSDL_Rect);
Var
	W, H: sInt;
Begin
	PrintText(Text, Assets.Font, X, Y, AlignX, ALIGN_TOP, Colour);
	
	Fonts.GetTextSize(Text, Assets.Font, W, H);
	Rect.W := W; Rect.H := H;
	
	Rect.Y := Y;
	Case (AlignX) of
		ALIGN_LEFT:   Rect.X := X;
		ALIGN_CENTRE: Rect.X := X - (Rect.W div 2);
		ALIGN_RIGHT:  Rect.X := X - Rect.W;
	end
End;

Function MouseInRect(Const Rect: TSDL_Rect):Boolean;
Begin
	Result := Overlap(Rect.X, Rect.Y, Rect.W, Rect.H, Ev.Button.X, Ev.Button.Y, 1, 1)
End;

Procedure LoadUpdate(Name:AnsiString;Perc:Double);
Const
	STARTX = RESOL_W div 32; SIZEX = RESOL_W - (STARTX*2);
	SIZEY = RESOL_H div 32; STARTY = RESOL_H - (SIZEY*3);
Var
	Rect:TSDL_Rect; Col:TSDL_Colour;
Begin 
	If(TitleGfx = NIL) or (Font = NIL) then Exit();
	
	Rendering.BeginFrame();
	DrawTitle();
	
	Font^.Scale := 2;
	PrintText(UpperCase(Name),Font,(RESOL_W div 2),STARTY-(Font^.CharW*2),ALIGN_CENTRE,ALIGN_MIDDLE,NIL);
	
	With Rect do begin X:=STARTX; Y:=STARTY; W:=SIZEX; H:=SIZEY end;
	DrawColouredRect(@Rect, @WhiteColour);
	
	Col.R := 64+Random(128);
	Col.G := 64+Random(128);
	Col.B := 64+Random(128);
	Col.A := 255;
	Rect.W := Trunc(SIZEX*Perc);
	DrawColouredRect(@Rect, @Col);
	
	Rendering.FinishFrame()
End;

{$IFNDEF ANDROID}
Procedure BindKeys();
Const
	KeyName : Array[TPlayerKey] of AnsiString = (
		'MOVE UP','MOVE RIGHT','MOVE DOWN','MOVE LEFT','SHOOT LEFT','SHOOT RIGHT',
		'PAUSE','VOLUME DOWN','VOLUME UP'
	);
Var
	K:TPlayerKey; NewBind:Array[TPlayerKey] of TSDL_Keycode;
	dt:uInt; Finito,Bound:Boolean;
Begin
	Finito:=False; Bound:=False; K:=Low(TPlayerKey);
	Repeat
		Rendering.BeginFrame();
		DrawTitle();
		
		Font^.Scale := 2;
		PrintText('SET KEY BINDINGS',Font,(RESOL_W div 2),TitleGfx^.H,ALIGN_CENTRE,ALIGN_TOP,NIL);
		
		PrintText(KeyName[K],Font,(RESOL_W div 2),(RESOL_H + TitleGfx^.H) div 2,ALIGN_CENTRE,ALIGN_MIDDLE,NIL);
		
		Rendering.FinishFrame();
		GetDeltaTime(dt);
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit() 
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If ((Ev.Key.Keysym.Sym = SDLK_Escape) or (Ev.Key.Keysym.Sym = SDLK_AC_BACK)) then
					Exit()
				else begin
					NewBind[K]:=Ev.Key.Keysym.Sym; Bound:=True
				end
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				HandleWindowResizedEvent(@Ev)
		end;
		If (Bound) then begin
			If (K<High(TPlayerKey)) then
				Inc(K)
			else
				Finito:=True;
			
			Bound:=False
		end;
	Until Finito;
	For K:=Low(TPlayerKey) to High(TPlayerKey) do KeyBind[K]:=NewBind[K]
End;
{$ELSE} // IFDEF(ANDROID)
Procedure TweakOptions();
Const
	VOLUME_BTN_SIZE = 16;

	VOLUME_BAR_CHUNK = 32;
	VOLUME_BAR_GAP = 4;
	VOLUME_BAR_WIDTH = (VOL_LEVEL_MAX * VOLUME_BAR_CHUNK) + ((VOL_LEVEL_MAX - 2) * VOLUME_BAR_GAP) + VOLUME_BTN_SIZE;

	VOLUME_DOWN_XPOS = (RESOL_W - VOLUME_BAR_WIDTH - VOLUME_BTN_SIZE) div 2;
	VOLUME_UP_XPOS = (RESOL_W + VOLUME_BAR_WIDTH + VOLUME_BTN_SIZE) div 2;
Var
	Volume: TVolLevel;
	VolumeText: AnsiString;
	VolumeChanged: Boolean;
	Finished, SaveChanges: Boolean;

	dt, Idx: uInt;
	YPos: sInt;

	BarChunk: Array[1..VOL_LEVEL_MAX] of TSDL_Rect;
	VolDown, VolUp, VolMute: TSDL_Rect;
Begin
	// Pre-calculate positions for some UI elements.
	// Would be great if we could do this at compile time.
	YPos := TitleGfx^.H + (Font^.CharH + Font^.SpacingY) * 6;
	For Idx := 1 to VOL_LEVEL_MAX do
		With BarChunk[Idx] do begin
			X := ((RESOL_W - VOLUME_BAR_WIDTH) div 2) + ((Idx - 1) * (VOLUME_BAR_CHUNK + VOLUME_BAR_GAP));
			If(Idx > (VOL_LEVEL_MAX div 2)) then X += VOLUME_BTN_SIZE - VOLUME_BAR_GAP;

			Y := YPos;
			W := VOLUME_BAR_CHUNK;
			H := Font^.CharH
		end;
	With VolDown do begin
		X := VOLUME_DOWN_XPOS - (VOLUME_BTN_SIZE div 2);
		Y := YPos;
		W := VOLUME_BTN_SIZE;
		H := Font^.CharH
	end;
	With VolUp do begin
		X := VOLUME_UP_XPOS - (VOLUME_BTN_SIZE div 2);
		Y := YPos;
		W := VOLUME_BTN_SIZE;
		H := Font^.CharH
	end;
	With VolMute do begin
		X := (RESOL_W - VOLUME_BTN_SIZE) div 2;
		Y := YPos;
		W := VOLUME_BTN_SIZE;
		H := Font^.CharH
	end;

	// Get current settings and store in helper vars.
	Volume := GetVol();
	VolumeText := IntToStr(Volume);

	Finished := False;
	SaveChanges := False;
	Repeat
		Rendering.BeginFrame();
		DrawTitle();

		YPos := TitleGfx^.H;
		Font^.Scale := 2;
		PrintText('GAME OPTIONS', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);

		(*
		 * "Sound" has 5 letters, and "volume" has 6. This makes the space between
		 * the words not align with the volume level text, which looks off - despite
		 * both texts being aligned to the centre of the screen!
		 * Hence, an extra space is added at the start of the text.
		 *)
		YPos += (Font^.CharH + Font^.SpacingY) * Font^.Scale * 2;
		PrintText(' SOUND VOLUME', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);

		YPos += (Font^.CharH + Font^.SpacingY) * Font^.Scale;
		Font^.Scale := 1;
		PrintText(VolumeText, Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
		(*
		 * TODO: Grey these out when volume is already at 0 or VOL_LEVEL_MAX.
		 * TODO: Think of some way to make it more obvious that these are touchable.
		 *)
		PrintText('-', Font, VOLUME_DOWN_XPOS, YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
		PrintText('+', Font, VOLUME_UP_XPOS, YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);

		For Idx := 1 to VOL_LEVEL_MAX do
			If(Volume >= Idx) then
				DrawColouredRect(@BarChunk[Idx], @WhiteColour)
			else
				DrawColouredRect(@BarChunk[Idx], @GreyColour);

		Rendering.FinishFrame();
		GetDeltaTime(dt);

		VolumeChanged := False;
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Finished := True
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If ((Ev.Key.Keysym.Sym = SDLK_Escape) or (Ev.Key.Keysym.Sym = SDLK_AC_BACK)) then begin
					Finished := True; SaveChanges := True
				end
			end else
			If (Ev.Type_ = SDL_MouseButtonDown) then begin
				TranslateMouseEventCoords(@Ev);
				If MouseInRect(VolDown) then begin
					If(Volume > 0) then begin
						Volume -= 1; VolumeChanged := True
					end
				end else
				If MouseInRect(VolUp) then begin
					If(Volume < VOL_LEVEL_MAX) then begin
						Volume += 1; VolumeChanged := True
					end
				end else
				If MouseInRect(VolMute) then begin
					Volume := 0; VolumeChanged := True
				end else
				For Idx := 1 to VOL_LEVEL_MAX do
					If MouseInRect(BarChunk[Idx]) then begin
						Volume := TVolLevel(Idx);
						VolumeChanged := True;
						Break
					end
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				HandleWindowResizedEvent(@Ev)
		end;

		If (VolumeChanged) then VolumeText := IntToStr(Volume)
	Until Finished;

	If(SaveChanges) then SetVol(Volume)
End;
{$ENDIF}

(*
 * TODO:
 * The drawing code is copy-pasted from Game.DrawRoom().
 * Think of a way to reduce duplication.
 *)
Procedure DrawColourPreview(Const Colour: PSDL_Colour; Const PosX, PosY: sInt);
Const
	PreviewW = 8;
	PreviewH = 4;
	PreviewMap: Array[0..(PreviewH-1), 0..(PreviewW-1)] of Char = (
		('X', '-', '-', '-', '=', '-', '-', '+'),
		('X', 'X', ' ', ' ', ' ', ' ', ' ', '|'),
		(':', ' ', ' ', ' ', ' ', ' ', ' ', 'D'),
		('X', 'X', ' ', '<', '-', '>', ' ', '|')
	);
Var
	X, Y: sInt;
	Tile: TTile;
	Src, Dst: TSDL_Rect;
Begin
	// All tiles have the same size, no need to set this in the loop 
	Src.W:=TILE_W; Src.H:=TILE_H; 
	Dst.W:=TILE_W; Dst.H:=TILE_H;
	
	Src.X:=0;
	For Y:=0 to (PreviewH-1) do For X:=0 to (PreviewW-1) do begin
		Tile:=TRoom.CharToTile(PreviewMap[Y][X]);
		If (Tile = TILE_NONE) then Continue;
		
		Dst.X := PosX + (X*TILE_W);
		Dst.Y := PosY + (Y*TILE_H);
		Src.Y := Ord(Tile)*TILE_H;
		DrawImage(TileGfx,@Src,@Dst,Colour)
	end
End;

Procedure SetSingleColour(Const idx: sInt);
Const
	RectWidth = 128;
	RectHeight = 64;
Var
	idxName: AnsiString;
	CurrentCol: TSDL_Colour;
	
	Menu: TMenu;
	Choice: Char;
	Changed: Boolean;
	Finished: Boolean;

	dt, pc: uInt;
	YPos: sInt;
Begin
	idxName := UpperCase(ColourName[idx]);
	CurrentCol := MapColour[idx];

	Menu.Create();
	Menu.SetFontScale(2);
	Menu.AddItem('R', 'RED:   #'+HexStr(CurrentCol.R, 2), @WhiteColour);
	Menu.AddItem('G', 'GREEN: #'+HexStr(CurrentCol.G, 2), @WhiteColour);
	Menu.AddItem('B', 'BLUE:  #'+HexStr(CurrentCol.B, 2), @WhiteColour);
	Menu.AddItem('D', 'DEFAULT', @WhiteColour);

	Finished := False;
	While Not Finished do begin
		Rendering.BeginFrame();
		DrawTitle();
		
		Font^.Scale := 2; YPos:=TitleGfx^.H;
		PrintText('COLOUR SETTINGS', Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP,NIL);
		
		YPos += ((Font^.CharH * Font^.Scale) * 3) div 2;
		PrintText(idxName, Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP,NIL);
		
		YPos += ((Font^.CharH * Font^.Scale) * 3) div 2;
		DrawColourPreview(@CurrentCol, (RESOL_W - RectWidth) div 2, YPos);
		
		YPos += RectHeight + (Font^.CharH * Font^.Scale) div 2;
		Menu.SetVerticalOffset(YPos);
		Menu.Draw();
		
		Rendering.FinishFrame();
		GetDeltaTime(dt);

		Changed := False;
		While (SDL_PollEvent(@Ev)>0) do begin
			Choice := Menu.ProcessEvent(@Ev);
			If (Choice = 'R') then begin
				CurrentCol.R := CurrentCol.R + $10;
				Changed := True
			end else
			If (Choice = 'G') then begin
				CurrentCol.G := CurrentCol.G + $10;
				Changed := True
			end else
			If (Choice = 'B') then begin
				CurrentCol.B := CurrentCol.B + $10;
				Changed := True
			end else
			If (Choice = 'D') then begin
				CurrentCol:=DefaultMapColour[idx];
				Changed := True
			end else
			If (Choice = CHOICE_BACK) then begin
				For pc:=0 to 7 do If(CentralPalette[pc] = MapColour[idx]) then CentralPalette[pc] := CurrentCol;
				For pc:=0 to 7 do If(PaletteColour[pc] = MapColour[idx]) then PaletteColour[pc] := CurrentCol;
				MapColour[idx] := CurrentCol;
				Finished := True
			end else
			If (Choice = CHOICE_QUIT) then begin
				Shutdown := True;
				Finished := True
			end
		end;

		If (Changed) then begin
			Menu.EditItem(0, 'RED:   #'+HexStr(CurrentCol.R, 2));
			Menu.EditItem(1, 'GREEN: #'+HexStr(CurrentCol.G, 2));
			Menu.EditItem(2, 'BLUE:  #'+HexStr(CurrentCol.B, 2))
		end
	end;
	Menu.Destroy()
End;

Procedure SetColours();
Var
	Idx, dt: uInt;

	Menu: TMenu;
	Choice: Char;
	Selection: sInt;
	Finished: Boolean;
Begin
	Menu.Create(8);
	Menu.SetFontScale(2);
	For Idx := 0 to 7 do Menu.AddItem(Chr(48 + Idx), UpperCase(ColourName[Idx]), @WhiteColour);
	Menu.SetVerticalOffset(TitleGfx^.H + (Font^.CharH * 3));

	Finished := False;
	Repeat
		Rendering.BeginFrame();
		DrawTitle();

		Font^.Scale := 2;
		PrintText('COLOUR SETTINGS', Font, (RESOL_W div 2), TitleGfx^.H, ALIGN_CENTRE, ALIGN_TOP, NIL);

		Menu.Draw();
		Rendering.FinishFrame();

		GetDeltaTime(dt);
		Selection := -1;
		While (SDL_PollEvent(@Ev)>0) do begin
			Choice := Menu.ProcessEvent(@Ev);
			If (Choice = CHOICE_QUIT) then begin
				Shutdown := True;
				Finished := True
			end else
			If (Choice = CHOICE_BACK) then Finished := True
			else
			If (Choice <> CHOICE_NONE) then Selection := Ord(Choice) - 48
		end;
		If (Selection >= 0) and (Selection <= 7) then SetSingleColour(Selection)
	Until Finished;
	Menu.Destroy()
End;

{$IFDEF LD25_DONATE}
Procedure DonateScreen();
Const
	GitHubText    = {$IFNDEF ANDROID} 'G - ' + {$ENDIF} 'GITHUB SPONSORS';
	LiberapayText = {$IFNDEF ANDROID} 'L - ' + {$ENDIF} 'LIBERAPAY';
	Alignment = {$IFNDEF ANDROID} ALIGN_LEFT {$ELSE} ALIGN_CENTRE {$ENDIF};
Var
	dt: uInt;
	XPos, YPos: sInt;
	GitHubRect, LiberaPayRect: TSDL_Rect;
	BackToMenu: Boolean;
Begin
	{$IFNDEF ANDROID}
		XPos := (Length(GitHubText) * Font^.CharW) + ((Length(GitHubText) - 1) * Font^.SpacingX);
		XPos := (RESOL_W - (XPos * Font^.Scale)) div 2;
	{$ELSE}
		XPos := RESOL_W div 2;
	{$ENDIF}

	BackToMenu := False;
	Repeat
		Rendering.BeginFrame();
		DrawTitle();

		Font^.Scale := 2; YPos:=TitleGfx^.H;
		PrintText('DONATE',Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP,NIL);

		YPos += Font^.CharH * Font^.Scale * 3;
		PrintText('IF YOU LIKE THE GAME', Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP,NIL);
		YPos += (Font^.CharH * Font^.Scale * 3) div 2;
		PrintText('YOU CAN DONATE VIA:', Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP,NIL);

		YPos += Font^.CharH * Font^.Scale * 3;
		PrintMenuText(GitHubText, XPos, YPos, Alignment, @WhiteColour, GitHubRect);

		YPos += Font^.CharH * Font^.Scale * 2;
		PrintMenuText(LiberapayText, XPos, YPos, Alignment, @WhiteColour, LiberaPayRect);

		YPos += Font^.CharH * Font^.Scale * 3;
		PrintText('THANKS!', Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP,NIL);

		Rendering.FinishFrame();
		GetDeltaTime(dt);

		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; BackToMenu := True
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If ((Ev.Key.Keysym.Sym = SDLK_Escape) or (Ev.Key.Keysym.Sym = SDLK_AC_BACK)) then
					BackToMenu := True
				else
				If (Ev.Key.Keysym.Sym = SDLK_G) then begin
					SDL_OpenUrl(PChar('https://github.com/sponsors/suve'));
					BackToMenu := True
				end else
				If (Ev.Key.Keysym.Sym = SDLK_L) then begin
					SDL_OpenUrl(PChar('https://liberapay.com/suve'));
					BackToMenu := True
				end
			end else
			If (Ev.Type_ = SDL_MouseButtonDown) then begin
				{$IFDEF ANDROID} TranslateMouseEventCoords(@Ev); {$ENDIF}
				If(MouseInRect(GitHubRect)) then begin
					SDL_OpenUrl(PChar('https://github.com/sponsors/suve'));
					BackToMenu := True
				end else
				If(MouseInRect(LiberaPayRect)) then begin
					SDL_OpenUrl(PChar('https://liberapay.com/suve'));
					BackToMenu := True
				end
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				HandleWindowResizedEvent(@Ev)
		end;
	until BackToMenu
End;
{$ENDIF}

Function GameworldDialog(Const Load:Boolean):Char;
Const
	WorldName: Array[TGameMode] of AnsiString = (
		'TUTORIAL',
		'CLASSIC'
	);
Var
	Msg: AnsiString;
	OK: Array[TGameMode] of Boolean;
	GM: TGameMode;

	Menu: TMenu;
	Col: PSDL_Colour;
	Choice: Char;
	YPos: uInt;
	dt:uInt;
Begin
	If Load then begin
		Msg:='LOAD GAME';
		For GM:=Low(GM) to High(GM) do Ok[GM]:=SaveExists[GM]
	end else begin
		Msg:='NEW GAME';
		For GM:=Low(GM) to High(GM) do Ok[GM]:=True
	end;

	Menu.Create(Length(WorldName));
	Menu.SetFontScale(2);
	For GM := Low(GM) to High(GM) do begin
		If (Ok[GM]) then
			Col := @WhiteColour
		else
			Col := @GreyColour;
		Menu.AddItem(WorldName[GM][1], WorldName[GM], Col)
	end;

	Result := '?';
	While (Result = '?') do begin
		Rendering.BeginFrame();
		DrawTitle();

		Font^.Scale := 2;
		YPos := TitleGfx^.H;
		PrintText(Msg, Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
		YPos += ((Font^.CharH * Font^.Scale) * 3) div 2;
		PrintText('SELECT GAMEWORLD', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, NIL);
		YPos += (Font^.CharH * Font^.Scale);

		Menu.SetVerticalOffset(YPos);
		Menu.Draw();

		Rendering.FinishFrame();
		GetDeltaTime(dt);
		While (SDL_PollEvent(@Ev)>0) do begin
			Choice := Menu.ProcessEvent(@Ev);
			If (Choice = 'T') then begin
				If (Ok[GM_TUTORIAL]) then Result := 'T'
			end else
			If (Choice = 'C') then begin
				If (Ok[GM_ORIGINAL]) then Result := 'C'
			end else
			If (Choice = CHOICE_QUIT) then begin
				Shutdown := True;
				Result := 'Q'
			end else
			If (Choice = CHOICE_BACK) then Result := 'Q'
		end
	end;
	Menu.Destroy()
End;

Function MainMenu():Char;
Var
	dt: uInt;

	GM: TGameMode;
	IHasSaves: Boolean;
	ContinueColour: PSDL_Colour;
	LoadColour: PSDL_Colour;

	Menu: TMenu;
	Choice: Char;
Begin
	If (GameOn) then
		ContinueColour := @WhiteColour
	else
		ContinueColour := @GreyColour;

	IHasSaves := False;
	For GM:=Low(GM) to High(GM) do If (SaveExists[GM]) then begin
		IHasSaves:=True;
		Break
	end;
	If (IHasSaves) then
		LoadColour := @WhiteColour
	else
		LoadColour := @GreyColour;

	Menu.Create(8);
	Menu.SetFontScale(2);
	Menu.AddItem('I', 'INTRODUCTION', @WhiteColour);
	Menu.AddItem('C', 'CONTINUE', ContinueColour);
	Menu.AddItem('N', 'NEW GAME', @WhiteColour);
	Menu.AddItem('L', 'LOAD GAME', LoadColour);
	{$IFNDEF ANDROID}
		Menu.AddItem('B', 'BIND KEYS', @WhiteColour);
	{$ELSE}
		Menu.AddItem('O', 'CHANGE OPTIONS', @WhiteColour);
	{$ENDIF}
	Menu.AddItem('S', 'SET COLOURS', @WhiteColour);
	{$IFDEF LD25_DONATE}
		Menu.AddItem('D', 'DONATE', @WhiteColour);
	{$ENDIF}
	Menu.AddItem('Q', 'QUIT', @WhiteColour);

	Result := '?';
	While (Result = '?') do begin
		Rendering.BeginFrame();
		DrawTitle();
		Menu.Draw();
		Rendering.FinishFrame();

		GetDeltaTime(dt);
		While (SDL_PollEvent(@Ev)>0) do begin
			Choice := Menu.ProcessEvent(@Ev);
			If (Choice = CHOICE_QUIT) or (Choice = CHOICE_BACK) then begin
				Shutdown := True;
				Result := 'Q'
			end else
			If (Choice = 'C') then begin
				If (GameOn) then Result := 'C'
			end else
			If (Choice = 'L') then begin
				If (IHasSaves) then Result := 'L'
			end else
			If (Choice <> CHOICE_NONE) then Result := Choice
		end
	end;
	Menu.Destroy()
End;

Procedure LoadConfig();
Begin
	(*
	 * Start by setting everything to default values, just in case
	 * the user manually edited the config file and some fields are now missing.
	 *)
	Configfiles.DefaultSettings();

	If (IHasIni(INIVER_2_0)) then begin
		SDL_Log('Loading configuration file...', []);
		If (LoadIni(INIVER_2_0)) then begin
			SDL_Log('Configuration file loaded successfully.', []);
			Exit()
		end else
			SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, 'Failed to load configuration file!', [])
	end else
		SDL_Log('Configuration file not found.', []);

	{$IFNDEF ANDROID}
		If (IHasIni(INIVER_1_0)) then begin
			SDL_Log('Loading legacy v1.x configuration file...', []);
			If (LoadIni(INIVER_1_0)) then begin
				SDL_Log('Legacy configuration file loaded successfully.', []);
				Exit()
			end else
				SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, 'Failed to load legacy configuration file!', [])
		end else
			SDL_Log('Legacy v1.x configuration file not found.', []);
	{$ENDIF}

	SDL_Log('Using default settings.', []);
	Configfiles.DefaultSettings()
End;

Function OpenWindow(): Boolean;
Var
	Title: AnsiString;
Begin
	Title := GAMENAME + ' v.' + GAMEVERS;
	{$IFDEF ANDROID}
		(*
		 * On Android, pass 0x0 as the window size. This makes SDL open a window covering the entire screen.
		 * Set the RESIZABLE flag to allow for rotations, split-screen, et cetera.
		 * Do not set FULLSCREEN, as that disables system navigation buttons.
		 *)
		Window := SDL_CreateWindow(PChar(Title), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 0, 0, SDL_WINDOW_RESIZABLE);
	{$ELSE}
		(*
		 * On desktop platforms, open a window based on the values read beforehand from the config file.
		 *)
		If (Not Wnd_F) then
			Window := SDL_CreateWindow(PChar(Title), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, Wnd_W, Wnd_H, SDL_WINDOW_RESIZABLE)
		else
			Window := SDL_CreateWindow(PChar(Title), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, RESOL_W, RESOL_H, SDL_WINDOW_FULLSCREEN_DESKTOP or SDL_WINDOW_RESIZABLE);
	{$ENDIF}
	If (Window = NIL) then Exit(False);

	(*
	 * Trigger the resize event handler to force recalculating the window size and aspect ratio.
	 *)
	HandleWindowResizedEvent(NIL);

	SDL_SetWindowMinimumSize(Window, RESOL_W, RESOL_H);
	Exit(True)
End;

Procedure FatalError(fmt: AnsiString; args: Array of Const);
Const
	MsgBoxTitle = GAMENAME + ' v.' + GAMEVERS + ': Error';
Var
	ErrorStr: AnsiString;
Begin
	ErrorStr := SysUtils.Format(fmt, args);
	SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, '%s', [PChar(ErrorStr)]);
	SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, PChar(MsgBoxTitle), PChar(ErrorStr), Window);
	Halt(1)
End;

Function InitSDL2(): Boolean;
Begin
	(*
	 * Configure the behaviour of the SDL2 library.
	 * Some of the values we set here are the same as the default ones,
	 * but it is always better to be explicit.
	 *)
	SDL_SetHint(SDL_HINT_APP_NAME, GAMENAME);

	SDL_SetHint(SDL_HINT_VIDEO_ALLOW_SCREENSAVER, '1');
	SDL_SetHint(SDL_HINT_SCREENSAVER_INHIBIT_ACTIVITY_NAME, 'Playing a game');

	SDL_SetHint(SDL_HINT_RENDER_BATCHING, '1');
	SDL_SetHint(SDL_HINT_RENDER_LOGICAL_SIZE_MODE, 'letterbox');
	SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, 'nearest');

	SDL_SetHint(SDL_HINT_NO_SIGNAL_HANDLERS, '0');
	SDL_SetHint(SDL_HINT_QUIT_ON_LAST_WINDOW_CLOSE, '1');
	SDL_SetHint(SDL_HINT_WINDOWS_NO_CLOSE_ON_ALT_F4, '0');

	SDL_SetHint(SDL_HINT_ANDROID_TRAP_BACK_BUTTON, '1');
	SDL_SetHint(SDL_HINT_MOUSE_TOUCH_EVENTS, '0');
	SDL_SetHint(SDL_HINT_TOUCH_MOUSE_EVENTS, '1');

	Result := SDL_Init(SDL_Init_Video or SDL_Init_Timer) = 0
End;

Procedure Startup();
Var
	StartTime: TTimeStamp;
	GM: TGameMode;
	OldMask, NewMask: TFPUExceptionMask;
	Assload: Assets.TLoadingResult;
Begin
	StartTime:=GetTimeStamp(); Randomize();

	// Reset some global vars to known values
	Shutdown:=False;
	GameOn:=False;
	NoSound:=False;

	ConfigFiles.SetPaths();
	{$IFNDEF ANDROID}
	ConfigFiles.CopyOldSavegames();
	{$ENDIF}

	LoadConfig();
	For GM:=Low(GM) to High(GM) do SaveExists[GM]:=IHasGame(GM);

	// Disable Floating Poing Exception checking while initializing the video stack.
	// See: https://github.com/PascalGameDevelopment/SDL2-for-Pascal/issues/56
	OldMask := Math.GetExceptionMask();
	NewMask := OldMask;
	Include(NewMask, exInvalidOp);
	Include(NewMask, exZeroDivide);
	Math.SetExceptionMask(NewMask);

	SDL_Log('Initializing SDL2...', []);
	If (Not InitSDL2()) then
		FatalError('Failed to initialize SDL2! Error details: %s', [SDL_GetError()])
	else
		SDL_Log('SDL2 initialized successfully.', []);

	SDL_Log('Initializing SDL2_image... ', []);
	if(IMG_Init(IMG_INIT_PNG) <> IMG_INIT_PNG) then
		FatalError('Failed to initialize SDL2_image! Error details: %s', [IMG_GetError()])
	else
		SDL_Log('SDL2_image initialized successfully.', []);

	SDL_Log('Initializing SDL2 audio subsystem...', []);
	If (SDL_InitSubSystem(SDL_Init_Audio)<>0) then begin
		SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, 'Failed to initialize SDL2 audio subsystem! Error details: %s', [SDL_GetError()]);
		NoSound:=True
	end else
		SDL_Log('SDL2 audio subsystem initialized successfully.', []);

	If (Not NoSound) then begin
		SDL_Log('Initializing SDL2_mixer...', []);
		If((Mix_Init(MIX_INIT_OGG) and MIX_INIT_OGG) = 0) then begin
			SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, 'Failed to initialize SDL2_mixer! Error details: %s', [Mix_GetError()]);
			NoSound:=True
		end else
		If (Mix_OpenAudio(AUDIO_FREQ, AUDIO_TYPE, AUDIO_CHAN, AUDIO_CSIZ)<>0) then begin
			SDL_LogWarn(SDL_LOG_CATEGORY_APPLICATION, 'Failed to initialize SDL2_mixer! Error details: %s', [Mix_GetError()]);
			NoSound:=True
		end else begin
			Mix_AllocateChannels(SFXCHANNELS);
			SDL_Log('SDL2_mixer initialized successfully.', [])
		end
	end else
		SDL_Log('Failed to initialize SDL2 audio - skipping SDL2_mixer init.', []);

	SDL_Log('Opening window...', []);
	If (Not OpenWindow()) then begin
		FatalError('Failed to open window! Error details: %s', [SDL_GetError()])
	end else begin
		SDL_Log('Window opened successfully. (%s)', [PChar(Rendering.GetWindowInfo())]);
		LoadAndSetWindowIcon()
	end;

	SDL_Log('Creating renderer...', []);
	Renderer := SDL_CreateRenderer(Window, -1, SDL_RENDERER_TARGETTEXTURE);
	if(Renderer = NIL) then begin
		FatalError('Failed to create renderer! Error details: %s', [SDL_GetError()])
	end else begin
		SDL_Log('Renderer created successfully. (%s)', [PChar(Rendering.GetRendererInfo())]);
		SDL_RenderSetLogicalSize(Renderer, RESOL_W, RESOL_H)
	end;

	// Restore the old mask after we disabled FPE checks.
	Math.SetExceptionMask(OldMask);

	SDL_Log('Creating render target texture...', []);
	Display := SDL_CreateTexture(Renderer, SDL_GetWindowPixelFormat(Window), SDL_TEXTUREACCESS_TARGET, RESOL_W, RESOL_H);
	if(Display = NIL) then
		FatalError('Failed to create render target texture! Error details: %s', [SDL_GetError()])
	else
		SDL_Log('Render target texture created successfully.', []);

	SDL_Log('Loading assets...', []);
	RegisterAllAssets();
	Assload := LoadAssets(@LoadUpdate);
	If(Assload.Status <> ALS_OK) then begin
		If(Assload.Status = ALS_FAILED) then
			FatalError('Failed to load file: %s (%s)', [Assload.FileName, Assload.ErrStr])
		else
			FatalError('Failed to load assets: %s', [Assload.ErrStr])
	end else
		SDL_Log('All assets loaded successfully.', []);

	SetLength(Mob,0); SetLength(EBul,0); SetLength(PBul,0); SetLength(Gib,0); Hero:=NIL;
	SDL_Log('All done! Initialization finished in %ld ms.', [clong(TimeStampDiffMillis(StartTime, GetTimeStamp()))])
End;

Procedure NewGame(Const GM:TGameMode);
Begin
	If(GM <> GameMode) then SaveCurrentGame();

	GameMode:=GM;
	DestroyEntities(True); ResetGamestate();
	New(Hero,Create()); ChangeRoom(RespRoom[GM].X,RespRoom[GM].Y);
	GameOn:=True
End;

Function GameloadRequest(Const GM:TGameMode):Boolean;
Begin
	If(GM <> GameMode) then SaveCurrentGame();

	SDL_Log('Loading game...', []);
	Result := LoadGame(GM);
	If(Result) then
		SDL_Log('Game loaded successfully.', [])
	else
		SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, 'Failed to load the game!', [])
End;

Procedure QuitProg();
Var
	StartTime: TTimeStamp;
Begin
	StartTime := GetTimeStamp();
	SDL_HideWindow(Window);

	SaveCurrentGame();

	SDL_Log('Saving configuration file...', []);
	If (SaveIni()) then
		SDL_Log('Configuration file saved successfully.', [])
	else
		SDL_Log('Failed to save configuration file!', []);

	DestroyEntities();

	SDL_Log('Freeing assets...', []);
		Assets.FreeAssets();
	SDL_Log('Assets freed.', []);

	SDL_Log('Closing SDL2_mixer...', []);
		Mix_CloseAudio();
		Mix_Quit();
	SDL_Log('SDL2_mixer closed.', []);

	SDL_Log('Closing SDL2_image...', []);
		IMG_Quit();
	SDL_Log('SDL2_image closed.', []);

	SDL_Log('Closing SDL2...', []);
		SDL_DestroyTexture(Display);
		SDL_DestroyRenderer(Renderer);
		SDL_DestroyWindow(Window);
		SDL_Quit();
	SDL_Log('SDL2 closed.', []);

	SDL_Log('Finalization finished in %ld ms.', [clong(TimeStampDiffMillis(StartTime, GetTimeStamp()))]);
	SDL_Log('Thanks for playing and have a nice day!', [])
End;

(*
 * On Android, we're building the game as a library, not as an executable.
 * Stick the code in an "ld25main" function and export it.
 * Use cdecl for compatibility with C wrapper code.
 *)
{$IFDEF ANDROID}
Function ld25main(argc: cint; argv: Pointer): cint; cdecl;
{$ENDIF}

begin
	SDL_Log(GAMENAME + ' v.' + GAMEVERS + ' by ' + GAMEAUTH, []);
	{$IFDEF LD25_DEBUG}
		SDL_LogSetPriority(SDL_LOG_CATEGORY_APPLICATION, SDL_LOG_PRIORITY_DEBUG);
	{$ENDIF}

	Startup();
	Repeat
		MenuChoice:=MainMenu();
		Case MenuChoice of
			'I': ShowIntro();
			'C': PlayGame();
			'N': begin
				MenuChoice:=GameworldDialog(False);
				Case MenuChoice of
					'T': begin NewGame(GM_TUTORIAL); PlayGame() end;
					'C': begin NewGame(GM_ORIGINAL); PlayGame() end;
				end;
				MenuChoice:='N'
			end;
			'L': begin
				MenuChoice:=GameworldDialog(True);
				Case MenuChoice of
					'T': If(GameloadRequest(GM_TUTORIAL)) then PlayGame();
					'C': If(GameloadRequest(GM_ORIGINAL)) then PlayGame();
				end;
				MenuChoice:='L'
			end;
			'S': SetColours();
			{$IFDEF ANDROID}
				'O': TweakOptions();
			{$ELSE}
				'B': BindKeys();
			{$ENDIF}
			{$IFDEF LD25_DONATE}
				'D': DonateScreen();
			{$ENDIF}
		end;
		If (GameOn) and (GameMode <> GM_TUTORIAL) and (Given >= 8) then begin
			GameOn:=False; ShowOutro()
		end;
	Until (MenuChoice = 'Q') or (Shutdown);
	QuitProg();
{$IFDEF ANDROID}
	Result := 0
end;

exports	ld25main;
{$ENDIF}

end.
