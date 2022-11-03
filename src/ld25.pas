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
	SysUtils, Math,
	SDL2, SDL2_image, SDL2_mixer,
	Assets, Colours, ConfigFiles, FloatingText, Fonts, Game, Images, Objects,
	MathUtils, Menus, Rendering, Rooms, Shared
;


Var
	MenuChoice:Char;

Procedure DrawTitle();
Var
	Dst: TSDL_Rect;
Begin
	Dst.X := 0; Dst.Y := 0;
	Dst.W := TitleGfx^.W; Dst.H := TitleGfx^.H;
	DrawImage(TitleGfx, NIL, @Dst, NIL);
	
	Font^.Scale := 1;
	PrintText(
		UpperCase('V.'+GAMEVERS+' (build '+GAMEDATE+')') {$IFDEF DEVELOPER}+' DEVELOPER'{$ENDIF},
		Assets.Font,
		(RESOL_W div 2), 82, 
		ALIGN_CENTRE, ALIGN_MIDDLE,
		@WhiteColour
	)
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
	RedRect, BlueRect, GreenRect, DefaultRect: TSDL_Rect;
	
	Finished: Boolean;
	dt, pc: uInt;
	YPos: sInt;
Begin
	idxName := UpperCase(ColourName[idx]);
	CurrentCol := MapColour[idx];
	
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
		PrintMenuText('R - RED:   #'+HexStr(CurrentCol.R, 2), (RESOL_W div 2), YPos, ALIGN_CENTRE, @WhiteColour, RedRect);
		YPos += ((Font^.CharH * Font^.Scale) * 3) div 2;
		PrintMenuText('G - GREEN: #'+HexStr(CurrentCol.G, 2), (RESOL_W div 2), YPos, ALIGN_CENTRE, @WhiteColour, GreenRect);
		YPos += ((Font^.CharH * Font^.Scale) * 3) div 2;
		PrintMenuText('B - BLUE:  #'+HexStr(CurrentCol.B, 2), (RESOL_W div 2), YPos, ALIGN_CENTRE, @WhiteColour, BlueRect);
		YPos += ((Font^.CharH * Font^.Scale) * 3) div 2;
		PrintMenuText('D - DEFAULT', (RESOL_W div 2), YPos, ALIGN_CENTRE, @WhiteColour, DefaultRect);
		
		
		Rendering.FinishFrame();
		GetDeltaTime(dt);
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit()
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If ((Ev.Key.Keysym.Sym = SDLK_Escape) or (ev.Key.Keysym.Sym = SDLK_AC_BACK)) then Finished:=True
				else
				If (Ev.Key.Keysym.Sym = SDLK_R) then CurrentCol.R:=CurrentCol.R + $10
				else
				If (Ev.Key.Keysym.Sym = SDLK_G) then CurrentCol.G:=CurrentCol.G + $10
				else
				If (Ev.Key.Keysym.Sym = SDLK_B) then CurrentCol.B:=CurrentCol.B + $10
				else
				If (Ev.Key.Keysym.Sym = SDLK_D) then CurrentCol:=DefaultMapColour[idx]
			end else
			If (Ev.Type_ = SDL_MouseButtonDown) then begin
				{$IFDEF ANDROID} TranslateMouseEventCoords(@Ev); {$ENDIF}
				If (MouseInRect(RedRect)) then CurrentCol.R:=CurrentCol.R + $10
				else
				If (MouseInRect(GreenRect)) then CurrentCol.G:=CurrentCol.G + $10
				else
				If (MouseInRect(BlueRect)) then CurrentCol.B:=CurrentCol.B + $10
				else
				If (MouseInRect(DefaultRect)) then CurrentCol:=DefaultMapColour[idx]
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				HandleWindowResizedEvent(@Ev)
		end;
	end;
	
	For pc:=0 to 7 do If(CentralPalette[pc] = MapColour[idx]) then CentralPalette[pc] := CurrentCol;
	For pc:=0 to 7 do If(PaletteColour[pc] = MapColour[idx]) then PaletteColour[pc] := CurrentCol;
	MapColour[idx] := CurrentCol
End;

Procedure SetColours();
Var
	Idx, dt: uInt;

	Menu: TMenu;
	Choice: Char;
	Selection: sInt;
	Finished: Boolean;
Begin
	Menu.Create();
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

Procedure DonateScreen();
Const
	GitHubText = 'G - GITHUB SPONSORS';
Var
	dt: uInt;
	XPos, YPos: sInt;
	GitHubRect, LiberaPayRect: TSDL_Rect;
	BackToMenu: Boolean;
Begin
	XPos := (Length(GitHubText) * Font^.CharW) + ((Length(GitHubText) - 1) * Font^.SpacingX);
	XPos := (RESOL_W - (XPos * Font^.Scale)) div 2;

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
		PrintMenuText(GitHubText, XPos, YPos, ALIGN_LEFT, @WhiteColour, GitHubRect);

		YPos += Font^.CharH * Font^.Scale * 2;
		PrintMenuText('L - LIBERAPAY', XPos, YPos, ALIGN_LEFT, @WhiteColour, LiberaPayRect);

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

Function GameworldDialog(Const Load:Boolean):Char;
Const
	WorldName: Array[TGameMode] of AnsiString = (
		'TUTORIAL',
		'CLASSIC',
		'NEW WORLD'
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

	Menu.Create();
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
			If (Choice = 'N') then begin
				If (Ok[GM_NEWWORLD]) then Result := 'N'
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

Function ShowSlide(Const Img:PImage):Boolean;
Var
	Q:sInt; dt:uInt;
	Dst: TSDL_Rect;
Begin
	Q:=0;
	While (Q = 0) do begin
		Rendering.BeginFrame();
		Dst.X := (RESOL_W - Img^.W) div 2;
		Dst.Y := 0;
		Dst.W := Img^.W;
		Dst.H := Img^.H;
		DrawImage(Img,NIL,@Dst,NIL);
		Rendering.FinishFrame();
		
		GetDeltaTime(dt);
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit(False)
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If (Ev.Key.Keysym.Sym = SDLK_ESCAPE) then
					Q:=-1 
				else
					Q:=1
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				HandleWindowResizedEvent(@Ev)
		end
	end;
	Exit(Q >= 0)
End;

Function Intro():Boolean;
Var C:uInt;
Begin
	For C:=Low(SlideIn) to High(SlideIn) do
		If (Not ShowSlide(SlideIn[C])) then Exit(False);
	
	If (Not ShowSlide(TitleGfx)) then Exit(False);
	Exit(True)
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

	For GM:=Low(GM) to High(GM) do If (SaveExists[GM]) then begin
		IHasSaves:=True;
		Break
	end;
	If (IHasSaves) then
		LoadColour := @WhiteColour
	else
		LoadColour := @GreyColour;

	Menu.Create();
	Menu.SetFontScale(2);
	Menu.AddItem('I', 'INTRODUCTION', @WhiteColour);
	Menu.AddItem('C', 'CONTINUE', ContinueColour);
	Menu.AddItem('N', 'NEW GAME', @WhiteColour);
	Menu.AddItem('L', 'LOAD GAME', LoadColour);
	Menu.AddItem('S', 'SET COLOURS', @WhiteColour);
	{$IFNDEF ANDROID}
	Menu.AddItem('B', 'BIND KEYS', @WhiteColour);
	{$ENDIF}
	Menu.AddItem('D', 'DONATE', @WhiteColour);
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
			If (Choice <> CHOICE_NONE) then Result := Choice
		end
	end;
	Menu.Destroy()
End;

Procedure Outro();
Var
	C:uInt; YPos:uInt;
Begin
	For C:=Low(SlideOut) to High(SlideOut) do
		If Not ShowSlide(SlideOut[C]) then Exit();

	While True do begin
		Rendering.BeginFrame();
		DrawTitle();
		
		Font^.Scale := 2;
		PrintText(
			[UpperCase(GAMENAME),'BY SUPER VEGETA','','A LUDUM DARE 25 GAME','','THANKS TO:','','DANIEL REMAR'],
			Font,
			(RESOL_W div 2), TitleGfx^.H, 
			ALIGN_CENTRE, ALIGN_TOP, NIL
		);
		
		YPos:=TitleGfx^.H + (Font^.SpacingY + Font^.CharH) * 8 * Font^.Scale;
		Font^.Scale := 1;
		PrintText('FOR HERO CORE, WHICH THIS GAME WAS BASED UPON',Font,(RESOL_W div 2),YPos,ALIGN_CENTRE, ALIGN_TOP, NIL);
		
		Font^.Scale := 2;
		YPos += (Font^.SpacingY + Font^.CharH) * (Font^.Scale + 1);
		PrintText('DEXTERO',Font,(RESOL_W div 2),YPos,ALIGN_CENTRE, ALIGN_TOP, NIL);
		
		YPos += (Font^.SpacingY + Font^.CharH) * Font^.Scale;
		Font^.Scale := 1;
		PrintText(
			['FOR INTRODUCING ME TO LUDUM DARE','AND CHEERING ME UP DURING THE COMPO'],
			Font,
			(RESOL_W div 2), YPos,
			ALIGN_CENTRE, ALIGN_TOP, NIL
		);
		
		Rendering.FinishFrame();
		GetDeltaTime(C);
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit()
			end else
			If (Ev.Type_ = SDL_KeyDown) then Exit() else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then begin
				HandleWindowResizedEvent(@Ev)
			end
		end
	end
End;

Procedure LoadConfig();
Begin
	If (IHasIni(INIVER_2_0)) then begin
		Write('Loading 2.0 configuration file... ');
		If (LoadIni(INIVER_2_0)) then begin
			Writeln('Success!');
			Exit()
		end else
			Writeln('Failed!');
	end else
		Writeln('Configuration file not found.');
	
	{$IFNDEF ANDROID}
		If (IHasIni(INIVER_1_0)) then begin
			Write('Loading 1.0 configuration file... ');
			If (LoadIni(INIVER_1_0)) then begin
				Writeln('Success!');
				Exit()
			end else
				Writeln('Failed!');
		end else
			Writeln('Old configuration file not found.');
	{$ENDIF}

	Writeln('Using default settings.');
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

Function Startup():Boolean;
Var
	ErrStr: AnsiString;
	Timu: Comp;
	GM: TGameMode;
	OldMask, NewMask: TFPUExceptionMask;
Begin
	Timu:=GetMSecs(); Randomize();

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

	Write('Initializing SDL2 video... ');
	If (SDL_Init(SDL_Init_Video or SDL_Init_Timer)<>0) then begin
		Writeln('Failed!');
		Halt(1)
	end else
		Writeln('Success!');

	Write('Initializing SDL2_image... ');
	if(IMG_Init(IMG_INIT_PNG) <> IMG_INIT_PNG) then begin
		Writeln('Failed!');
		Halt(1)
	end else
		Writeln('Success!');

	Write('Initializing SDL2 audio... ');
	If (SDL_InitSubSystem(SDL_Init_Audio)<>0) then begin
		Writeln('Failed!');
		NoSound:=True
	end else
		Writeln('Success!');

	If (Not NoSound) then begin
		Write('Initializing SDL2_mixer... ');
		If(Mix_Init(0) <> 0) then begin
			Writeln('Failed!');
			NoSound:=True
		end else
		If (Mix_OpenAudio(AUDIO_FREQ, AUDIO_TYPE, AUDIO_CHAN, AUDIO_CSIZ)<>0) then begin
			Writeln('Failed!');
			NoSound:=True 
		end else begin
			Mix_AllocateChannels(SFXCHANNELS);
			Writeln('Success!');
		end
	end else
		Writeln('SDL audio init failed - skipping SDL_mixer init.');

	Write('Opening window... ');
	If (Not OpenWindow()) then begin
		Writeln('Failed!');
		Halt(1)
	end else begin
		Writeln('Success!');
		LoadAndSetWindowIcon();
	end;

	Write('Creating SDL2 renderer... ');
	Renderer := SDL_CreateRenderer(Window, -1, SDL_RENDERER_TARGETTEXTURE);
	if(Renderer = NIL) then begin
		Writeln('Failed!');
		Halt(1)
	end else begin
		Writeln('Success!');
		SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, 'nearest');
		SDL_RenderSetLogicalSize(Renderer, RESOL_W, RESOL_H)
	end;

	// Restore the old mask after we disabled FPE checks.
	Math.SetExceptionMask(OldMask);

	Write('Creating render target texture... ');
	Display := SDL_CreateTexture(Renderer, SDL_GetWindowPixelFormat(Window), SDL_TEXTUREACCESS_TARGET, RESOL_W, RESOL_H);
	if(Display = NIL) then begin
		Writeln('Failed!');
		Halt(1)
	end else
		Writeln('Success!');

	Write('Loading assets... ');
	RegisterAllAssets();
	If Not LoadAssets(ErrStr, @LoadUpdate) then begin
		Writeln('ERROR'); Writeln(ErrStr); Exit(False);
	end else
		Writeln('Success!');
   
	SetLength(Mob,0); SetLength(EBul,0); SetLength(PBul,0); SetLength(Gib,0); Hero:=NIL;
	Writeln('All done! Initialization finished in ',((GetMSecs()-Timu)/1000):0:2,' second(s).');
	Exit(True)
End;

Procedure NewGame(Const GM:TGameMode);
Begin
	GameMode:=GM;
	DestroyEntities(True); ResetGamestate();
	New(Hero,Create()); ChangeRoom(RespRoom[GM].X,RespRoom[GM].Y);
	GameOn:=True
End;

Function GameloadRequest(Const GM:TGameMode):Boolean;
Begin
	If((GameOn) and (GM <> GameMode)) then begin
		Write('Saving current game... ');
		If (SaveGame(GameMode)) then
			Writeln('Done.')
		else
			Writeln('Failed!')
	end;
	
	Write('Loading game... ');
	Result := LoadGame(GM);
	If(Result) then
		Writeln('Done.')
	else
		Writeln('Failed!')
End;

Procedure QuitProg();
Var Timu:Comp;
Begin
	Timu:=GetMSecs();
	SDL_HideWindow(Window);
	
	If (GameOn) then begin
		Write('Saving current game... ');
		If (SaveGame(GameMode)) then
			Writeln('Success.')
		else
			Writeln('Failed!');
		
		DestroyEntities();
	end;
	
	Write('Saving configuration file... ');
	If (SaveIni()) then
		Writeln('Success.')
	else
		Writeln('Failed!');
	
	Write('Freeing assets... ');
		Assets.FreeAssets();
	Writeln('Done.');
	
	Write('Closing SDL2_Mixer... ');
		Mix_CloseAudio();
		Mix_Quit();
	Writeln('Done.');
	
	Write('Closing SDL2_Image... ');
		IMG_Quit();
	Writeln('Done.');
	
	Write('Closing SDL2... ');
		SDL_DestroyTexture(Display);
		SDL_DestroyRenderer(Renderer);
		SDL_DestroyWindow(Window);
		SDL_Quit();
	Writeln('Done.');
	
	Writeln('Finalization finished in ',((GetMSecs-Timu)/1000):0:2,' second(s).');
	Writeln('Thanks for playing and have a nice day!')
End;

(*
 * On Android, we're building the game as a library, not as an executable.
 * Stick the code in a "ld25main" function and export it.
 * Use cdecl for compatibility with C wrapper code.
 *)
{$IFDEF ANDROID}
Procedure ld25main(); cdecl;
{$ENDIF}

begin
	Writeln(GAMENAME,' v.',GAMEVERS,' by ',GAMEAUTH);
{$IFNDEF PACKAGE}
	Writeln('build ',GAMEDATE);
{$ENDIF}
	Writeln(StringOfChar('-',36));
	If (Not Startup()) Then Halt(255);
	Repeat
		MenuChoice:=MainMenu();
		Case MenuChoice of
			'I': Intro();
			'C': PlayGame();
			'N': begin
				MenuChoice:=GameworldDialog(False);
				If (MenuChoice<>'Q') and (GameOn) then begin
					Write('Saving current game... ');
					If (SaveGame(GameMode)) then Writeln('Done.') end;
					Case MenuChoice of
					'T': begin NewGame(GM_TUTORIAL); PlayGame() end;
					'C': begin NewGame(GM_ORIGINAL); PlayGame() end;
					'N': begin NewGame(GM_NEWWORLD); PlayGame() end;
				end;
				MenuChoice:='N'
			end;
			'L': begin
				MenuChoice:=GameworldDialog(True);
				Case MenuChoice of
					'T': If(GameloadRequest(GM_TUTORIAL)) then PlayGame();
					'C': If(GameloadRequest(GM_ORIGINAL)) then PlayGame();
					'N': If(GameloadRequest(GM_NEWWORLD)) then PlayGame();
				end;
				MenuChoice:='L'
			end;
			'S': SetColours();
			'D': DonateScreen();
			{$IFNDEF ANDROID} 'B': BindKeys(); {$ENDIF}
		end;
		If (GameOn) and (GameMode <> GM_TUTORIAL) and (Given >= 8) then begin
			GameOn:=False; Outro()
		end;
	Until (MenuChoice = 'Q') or (Shutdown);
	QuitProg()
{$IFDEF ANDROID}
end;

exports	ld25main;
{$ENDIF}

end.
