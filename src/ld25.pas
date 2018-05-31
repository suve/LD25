(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2018 Artur Iwicki
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
program ld25; 

{$INCLUDE defines.inc}

uses
	SysUtils, SDL2, SDL2_image, SDL2_mixer,
	Assets, Colours, ConfigFiles, FloatingText, Fonts, Game, Images, Objects, Rooms, Shared
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
	
	Shared.BeginFrame();
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
	
	Shared.FinishFrame()
End;

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
		Shared.BeginFrame();
		DrawTitle();
		
		Font^.Scale := 2;
		PrintText('SET KEY BINDINGS',Font,(RESOL_W div 2),TitleGfx^.H,ALIGN_CENTRE,ALIGN_TOP,NIL);
		
		PrintText(KeyName[K],Font,(RESOL_W div 2),(RESOL_H + TitleGfx^.H) div 2,ALIGN_CENTRE,ALIGN_MIDDLE,NIL);
		
		Shared.FinishFrame();
		GetDeltaTime(dt);
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit() 
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If (Ev.Key.Keysym.Sym = SDLK_Escape) then
					Exit()
				else begin
					NewBind[K]:=Ev.Key.Keysym.Sym; Bound:=True
				end
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				Shared.ResizeWindow(Ev.Window.data1, Ev.Window.data2, False)
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
		Shared.BeginFrame();
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
		
		
		Shared.FinishFrame();
		GetDeltaTime(dt);
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit()
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If (Ev.Key.Keysym.Sym = SDLK_Escape) then Finished:=True
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
				If (MouseInRect(RedRect)) then CurrentCol.R:=CurrentCol.R + $10
				else
				If (MouseInRect(GreenRect)) then CurrentCol.G:=CurrentCol.G + $10
				else
				If (MouseInRect(BlueRect)) then CurrentCol.B:=CurrentCol.B + $10
				else
				If (MouseInRect(DefaultRect)) then CurrentCol:=DefaultMapColour[idx]
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				Shared.ResizeWindow(Ev.Window.data1, Ev.Window.data2, False)
		end;
	end;
	
	For pc:=0 to 7 do If(CentralPalette[pc] = MapColour[idx]) then CentralPalette[pc] := CurrentCol;
	For pc:=0 to 7 do If(PaletteColour[pc] = MapColour[idx]) then PaletteColour[pc] := CurrentCol;
	MapColour[idx] := CurrentCol
End;

Procedure SetColours();
Var
	ChoiceName: Array[0..7] of AnsiString;
	ChoiceRect: Array[0..7] of TSDL_Rect;
	dt, LongestName, C: uInt;
	XPos, YPos, Sel: sInt;
Begin
	LongestName := 0;
	For C:=0 to 7 do begin
		ChoiceName[C] := IntToStr(C+1) + ' - ' + UpperCase(ColourName[C]);
		If(Length(ChoiceName[C]) > LongestName) then LongestName := Length(ChoiceName[C])
	end;

	XPos := (LongestName * Font^.CharW) + ((LongestName - 1) * Font^.SpacingX);
	XPos := (RESOL_W - (XPos * Font^.Scale)) div 2;
	While True do begin
		Shared.BeginFrame();
		DrawTitle();
		
		Font^.Scale := 2; YPos:=TitleGfx^.H;
		PrintText('COLOUR SETTINGS',Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP,NIL);
		
		For C:=0 to 7 do begin
			YPos += ((Font^.CharH * Font^.Scale) * 3) div 2;
			PrintMenuText(ChoiceName[C], XPos, YPos, ALIGN_LEFT, @WhiteColour, ChoiceRect[C])
		end;
		
		Shared.FinishFrame();
		GetDeltaTime(dt);
		
		Sel := -1;
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit()
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If (Ev.Key.Keysym.Sym = SDLK_Escape) then Exit()
				else
				If (Ev.Key.Keysym.Sym >= SDLK_1) and (Ev.Key.Keysym.Sym <= SDLK_8) then Sel:=Ord(Ev.Key.Keysym.Sym - SDLK_1)
			end else
			If (Ev.Type_ = SDL_MouseButtonDown) then begin
				For C:=0 to 7 do If(MouseInRect(ChoiceRect[C])) then Sel:=C
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				Shared.ResizeWindow(Ev.Window.data1, Ev.Window.data2, False)
		end;
		
		If(Sel >= 0) then SetSingleColour(Sel)
	end
End;

Function GameworldDialog(Const Load:Boolean):Char;
Const
	WorldNames:Array[TGameMode] of AnsiString = (
		'T - TUTORIAL',
		'N - NORMAL  '
	);
Var
	WorldRect:Array[TGameMode] of TSDL_Rect;
	
	Msg:AnsiString;
	OK:Array[TGameMode] of Boolean; GM:TGameMode;
	Choice:Char; YPos:uInt; Col:PSDL_Colour; dt:uInt;
Begin
	If Load then begin Msg:='LOAD GAME';
		For GM:=Low(GM) to High(GM) do Ok[GM]:=SaveExists[GM]
	end else begin Msg:='NEW GAME';
		For GM:=Low(GM) to High(GM) do Ok[GM]:=True
	end;
   
	Choice:=#$20;
	While (Choice = #$20) do begin
		Shared.BeginFrame();
		DrawTitle();
		
		Font^.Scale := 2;
		PrintText([Msg,'','SELECT GAMEWORLD'],Font,(RESOL_W div 2),TitleGfx^.H,ALIGN_CENTRE,ALIGN_TOP,NIL);
		
		YPos:=((RESOL_H * 3) div 5);
		For GM:=Low(GM) to High(GM) do begin
			If (OK[GM]) then Col:=@WhiteColour else Col:=@GreyColour;
			PrintMenuText(WorldNames[GM], (RESOL_W div 2), YPos, ALIGN_CENTRE, Col, WorldRect[GM]);
			YPos += (Font^.SpacingY + Font^.CharH) * 2 * Font^.Scale
		end;
		
		Shared.FinishFrame();
		GetDeltaTime(dt);
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit('Q') end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If (Ev.Key.Keysym.Sym = SDLK_Escape) then Choice:='Q' else
				If (Ev.Key.Keysym.Sym = SDLK_T) then begin
					If (OK[GM_TUTORIAL]) then Choice:='T' 
				end else
				If (Ev.Key.Keysym.sym = SDLK_N) then begin
					If (Ok[GM_ORIGINAL]) then Choice:='N'
				end else
			end else
			If(Ev.Type_ = SDL_MouseButtonDown) then begin
				If (MouseInRect(WorldRect[GM_TUTORIAL])) then begin
					If (OK[GM_TUTORIAL]) then Choice:='T' 
				end else
				If (MouseInRect(WorldRect[GM_ORIGINAL])) then begin
					If (Ok[GM_ORIGINAL]) then Choice:='N'
				end else
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				Shared.ResizeWindow(Ev.Window.data1, Ev.Window.data2, False)
		end;
	end;
	Exit(Choice)
End;

Function ShowSlide(Const Img:PImage):Boolean;
Var
	Q:sInt; dt:uInt;
	Dst: TSDL_Rect;
Begin
	Q:=0;
	While (Q = 0) do begin
		Shared.BeginFrame();
		Dst.X := (RESOL_W - Img^.W) div 2;
		Dst.Y := 0;
		Dst.W := Img^.W;
		Dst.H := Img^.H;
		DrawImage(Img,NIL,@Dst,NIL);
		Shared.FinishFrame();
		
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
				Shared.ResizeWindow(Ev.Window.data1, Ev.Window.data2, False)
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

Function Menu():Char;
Var
	Choice:Char;
	dt, XPos, YPos:uInt; Col:PSDL_Colour; 
	IHasSaves:Boolean; GM:TGameMode;
	
	IntroRect, ContinueRect, NewGameRect, LoadGameRect, BindRect, ColourRect, QuitRect: TSDL_Rect;
Begin
	Font^.Scale := 2;
	XPos:=GetTextWidth('I - INTRODUCTION', Font);
	XPos:=(RESOL_W - XPos) div 2;

	IHasSaves:=False;
	For GM:=Low(GM) to High(GM) do If (SaveExists[GM]) then IHasSaves:=True;

	Choice:=#$20;
	While (Choice = #32) do begin
		Shared.BeginFrame();
		DrawTitle();
		
		Font^.Scale := 2; YPos:=TitleGfx^.H;
		PrintMenuText('I - INTRODUCTION', XPos, YPos, ALIGN_LEFT, @WhiteColour, IntroRect);
		
		YPos += Font^.CharH * 2 * Font^.Scale;
		If (GameOn) then Col:=@WhiteColour else Col:=@GreyColour;
		PrintMenuText('C - CONTINUE', XPos, YPos, ALIGN_LEFT, Col, ContinueRect);
		
		YPos += Font^.CharH * 2 * Font^.Scale;
		PrintMenuText('N - NEW GAME', XPos, YPos, ALIGN_LEFT, @WhiteColour, NewGameRect);
		
		YPos += Font^.CharH * 2 * Font^.Scale;
		If (IHasSaves) then Col:=@WhiteColour else Col:=@GreyColour;
		PrintMenuText('L - LOAD GAME', XPos, YPos, ALIGN_LEFT, Col, LoadGameRect);
		
		YPos += Font^.CharH * 2 * Font^.Scale;
		PrintMenuText('S - SET COLOURS', XPos, YPos, ALIGN_LEFT, @WhiteColour, ColourRect);
		
		YPos += Font^.CharH * 2 * Font^.Scale;
		PrintMenuText('B - BIND KEYS', XPos, YPos, ALIGN_LEFT, @WhiteColour, BindRect);
		
		YPos += Font^.CharH * 2 * Font^.Scale;
		PrintMenuText('Q - QUIT', XPos, YPos, ALIGN_LEFT, @WhiteColour, QuitRect);
		
		Shared.FinishFrame();
		GetDeltaTime(dt);
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit('Q') end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If (Ev.Key.Keysym.Sym = SDLK_ESCAPE) then Choice:='Q' else
				If (Ev.Key.Keysym.Sym = SDLK_Q) then Choice:='Q' else
				If (Ev.Key.Keysym.Sym = SDLK_I) then Choice:='I' else
				If (Ev.Key.Keysym.Sym = SDLK_N) then Choice:='N' else
				If (Ev.Key.Keysym.Sym = SDLK_C) then begin
					If (GameOn) then Choice:='C' end else
				If (Ev.Key.Keysym.Sym = SDLK_L) then begin
					If (IHasSaves) then Choice:='L' end else
				If (Ev.Key.Keysym.Sym = SDLK_B) then Choice:='B' else
				If (Ev.Key.Keysym.Sym = SDLK_S) then Choice:='S' else
			end else
			If (Ev.Type_ = SDL_MouseButtonDown) then begin
				If (MouseInRect(IntroRect)) then Choice:='I' else
				If (MouseInRect(NewGameRect)) then Choice:='N' else
				If (MouseInRect(ContinueRect)) then begin
					If (GameOn) then Choice:='C' end else
				If (MouseInRect(LoadGameRect)) then begin
					If (IHasSaves) then Choice:='L' end else
				If (MouseInRect(BindRect)) then Choice:='B' else
				If (MouseInRect(ColourRect)) then Choice:='S' else
				If (MouseInRect(QuitRect)) then Choice:='Q' else
			end else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then begin
				Shared.ResizeWindow(Ev.Window.data1, Ev.Window.data2, False)
			end
		end
	end;
	Exit(Choice)
End;

Procedure Outro();
Var
	C:uInt; YPos:uInt;
Begin
	For C:=Low(SlideOut) to High(SlideOut) do
		If Not ShowSlide(SlideOut[C]) then Exit();

	While True do begin
		Shared.BeginFrame();
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
		
		Shared.FinishFrame();
		GetDeltaTime(C);
		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit()
			end else
			If (Ev.Type_ = SDL_KeyDown) then Exit() else
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then begin
				Shared.ResizeWindow(Ev.Window.data1, Ev.Window.data2, False)
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
	
	If (IHasIni(INIVER_1_0)) then begin
		Write('Loading 1.0 configuration file... ');
		If (LoadIni(INIVER_1_0)) then begin
			Writeln('Success!');
			Exit()
		end else
			Writeln('Failed!');
	end else
		Writeln('Old configuration file not found.');
	
	Writeln('Using default settings.');
	Configfiles.DefaultSettings()
End;

Function Startup():Boolean;
Var
	Title, S:AnsiString; Timu:Comp; GM:TGameMode;
Begin
	Timu:=GetMSecs(); Randomize();
	
	SetPaths(); 
	LoadConfig();
	For GM:=Low(GM) to High(GM) do SaveExists[GM]:=IHasGame(GM);
	
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
	Title := GAMENAME + ' v.' + GAMEVERS;
	If (Not Wnd_F) then
		Shared.Window := SDL_CreateWindow(PChar(Title), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, Wnd_W, Wnd_H, SDL_WINDOW_RESIZABLE)
	else
		Shared.Window := SDL_CreateWindow(PChar(Title), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, RESOL_W, RESOL_H, SDL_WINDOW_FULLSCREEN_DESKTOP or SDL_WINDOW_RESIZABLE);
	If (Shared.Window = NIL) then begin
		Writeln('Failed!');
		Halt(1)
	end else begin
		Writeln('Success!');
		LoadAndSetWindowIcon();
	end;

	Write('Creating SDL2 renderer... ');
	Shared.Renderer := SDL_CreateRenderer(Shared.Window, -1, SDL_RENDERER_TARGETTEXTURE);
	if(Shared.Renderer = NIL) then begin
		Writeln('Failed!');
		Halt(1)
	end else begin
		Writeln('Success!');
		SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, 'nearest');
		SDL_RenderSetLogicalSize(Shared.Renderer, RESOL_W, RESOL_H)
	end;
	
	Write('Creating render target texture... ');
	Shared.Display := SDL_CreateTexture(Shared.Renderer, SDL_GetWindowPixelFormat(Shared.Window), SDL_TEXTUREACCESS_TARGET, RESOL_W, RESOL_H);
	if(Shared.Display = NIL) then begin
		Writeln('Failed!');
		Halt(1)
	end else
		Writeln('Success!');

	Write('Loading assets... ');
	RegisterAllAssets();
	If Not LoadAssets(S, @LoadUpdate) then begin
		Writeln('ERROR'); Writeln(S); Exit(False);
	end else
		Writeln('Success!');
   
	SetLength(Mob,0); SetLength(EBul,0); SetLength(PBul,0); SetLength(Gib,0); Hero:=NIL;
	Writeln('All done! Initialization finished in ',((GetMSecs()-Timu)/1000):0:2,' second(s).');
	Exit(True)
End;

Procedure NewGame_Turotial();
   begin
   GameMode:=GM_Tutorial; GameOn:=True;
   DestroyEntities(True); ResetGamestate();
   New(Hero,Create()); ChangeRoom(RespRoom[GM_Tutorial].X,RespRoom[GM_TUTORIAL].Y);
   end;

Procedure NewGame_Original();
   begin
   GameMode:=GM_ORIGINAL; GameOn:=True;
   DestroyEntities(True); ResetGamestate();
   New(Hero,Create()); ChangeRoom(RespRoom[GM_Original].X,RespRoom[GM_Original].Y);
   end;

Procedure QuitProg();
Var Timu:Comp;
Begin
	Timu:=GetMSecs();
	SDL_HideWindow(Shared.Window);
	
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
		SDL_DestroyTexture(Shared.Display);
		SDL_DestroyRenderer(Shared.Renderer);
		SDL_DestroyWindow(Shared.Window);
		SDL_Quit();
	Writeln('Done.');
	
	Writeln('Finalization finished in ',((GetMSecs-Timu)/1000):0:2,' second(s).');
	Writeln('Thanks for playing and have a nice day!')
End;

begin
Writeln(GAMENAME,' v.',GAMEVERS,' by ',GAMEAUTH);
{$IFNDEF PACKAGE}
	Writeln('build ',GAMEDATE);
{$ENDIF}
Writeln(StringOfChar('-',36));
If (Not Startup()) Then Halt(255);
Repeat
   MenuChoice:=Menu();
   Case MenuChoice of
      'I': Intro();
      'C': PlayGame();
      'N': begin
           MenuChoice:=GameworldDialog(False);
           If (MenuChoice<>'Q') and (GameOn) then begin
              Write('Saving current game... ');
              If (SaveGame(GameMode)) then Writeln('Done.') end;
           Case MenuChoice of
              'T': begin NewGame_Turotial(); PlayGame() end;
              'N': begin NewGame_Original(); PlayGame() end;
              end;
           MenuChoice:='N'
           end;
      'L': begin
           MenuChoice:=GameworldDialog(True);
           If (MenuChoice<>'Q') and (GameOn) and
              ((MenuChoice='T') xor (GameMode=GM_TUTORIAL)) then begin
              Write('Saving current game... ');
              If (SaveGame(GameMode)) then Writeln('Done.') end;
           Case MenuChoice of
              'T': begin Write('Loading game... '); If LoadGame(GM_TUTORIAL) then begin
                         Writeln('Done.'); PlayGame() end end;
              'N': begin Write('Loading game... '); If LoadGame(GM_ORIGINAL) then begin
                         Writeln('Done.'); PlayGame() end end;
              end;
           MenuChoice:='L'
           end;
      'B': BindKeys();
      'S': SetColours();
      end;
   If (GameOn) and (GameMode <> GM_TUTORIAL) and (Given >= 8) then begin
      GameOn:=False; Outro() end;
   Until (MenuChoice = 'Q') or (Shutdown);
QuitProg()
end.
