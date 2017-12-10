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
program ld25; 

{$INCLUDE defines.inc}

uses
	SysUtils, SDL2, SDL2_image, SDL2_mixer,
	Images, Fonts, Shared, Objects, FloatingText, configfiles, Game
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
		Shared.Font,
		(RESOL_W div 2), 82, 
		ALIGN_CENTRE, ALIGN_MIDDLE,
		@WhiteColour
	)
End;

Procedure PrintMenuText(Const Text:AnsiString; Const X, Y:sInt; Const AlignX: THorizontalAlign; Const Colour: PSDL_Colour; Out Rect: TSDL_Rect);
Var
	W, H: sInt;
Begin
	PrintText(Text, Shared.Font, X, Y, AlignX, ALIGN_TOP, Colour);
	
	Fonts.GetTextSize(Text, Shared.Font, W, H);
	Rect.W := W; Rect.H := H;
	
	Rect.Y := Y;
	Case (AlignX) of
		ALIGN_LEFT:   Rect.X := X;
		ALIGN_CENTRE: Rect.X := X - (Rect.W div 2);
		ALIGN_RIGHT:  Rect.X := X - Rect.W;
	end
End;

Function MouseInRect(Const Rect: TSDL_Rect):Boolean;
Var
	MouseX, MouseY: Double;
Begin
	// The mouse coordinates inside SDL_Event are given in window-size terms.
	// We need to convert them to game-resolution terms first.
	MouseX := Ev.Button.X; // * (RESOL_W / Screen^.W);
	MouseY := Ev.Button.Y; // * (RESOL_H / Screen^.H);
	
	Exit(Overlap(Rect.X, Rect.Y, Rect.W, Rect.H, MouseX, MouseY, 1, 1))
End;

Procedure LoadUpdate(Name:AnsiString;Perc:Double);
Const
	STARTX = RESOL_W div 32; SIZEX = RESOL_W - (STARTX*2);
	SIZEY = RESOL_H div 32; STARTY = RESOL_H - (SIZEY*3);
Var
	Rect:TSDL_Rect; Col:TSDL_Colour;
Begin 
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
Begin
	Q:=0;
	While (Q = 0) do begin
		Shared.BeginFrame();
		DrawImage(Img,NIL,NIL,NIL);
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
	
	IntroRect, ContinueRect, NewGameRect, LoadGameRect, BindRect, QuitRect: TSDL_Rect;
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
			end else
			If (Ev.Type_ = SDL_MouseButtonDown) then begin
				If (MouseInRect(IntroRect)) then Choice:='I' else
				If (MouseInRect(NewGameRect)) then Choice:='N' else
				If (MouseInRect(ContinueRect)) then begin
					If (GameOn) then Choice:='C' end else
				If (MouseInRect(LoadGameRect)) then begin
					If (IHasSaves) then Choice:='L' end else
				If (MouseInRect(BindRect)) then Choice:='B' else
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

Function Startup():Boolean;
Var
	Title, S:AnsiString; Timu:Comp; GM:TGameMode;
Begin
	Timu:=GetMSecs(); Randomize();
	
	SetPaths(); 
	If (IHasIni()) then begin
		Write('Loading configuration file... ');
		If (LoadIni()) then
			Writeln('Success!')
		else begin
			Writeln('Failed! Using default settings.');
			DefaultSettings()
		end;
	end else begin
		ConfigFiles.DefaultSettings();
		Writeln('Configuration file not found. Using default settings.')
	end;

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
	
	Write('Loading basic resources... ');
	If Not Shared.LoadBasics(S) then begin
		Writeln('ERROR'); Writeln(S); Exit(False)
	end else
		Writeln('Success!');

	Write('Loading gameworld resources... ');
	If Not Shared.LoadRes(S,@LoadUpdate) then begin
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
   begin
   Timu:=GetMSecs();
   Write('Freeing resouces... '); Shared.Free(); Writeln('Done.');
   Write('Closing SDL_mixer... '); Mix_CloseAudio(); Writeln('Done.');
   Write('Closing SDL... '); SDL_Quit(); Writeln('Done.');
   If (GameOn) then begin
      Write('Saving current game...');
      If (SaveGame(GameMode)) then Writeln('Done.') end;
   Write('Saving configuration file... ');
   If (SaveIni()) then Writeln('Done.');
   Writeln('Finalization finished in ',((GetMSecs-Timu)/1000):0:2,' second(s).');
   Writeln('Thanks for playing and have a nice day!');
   end;

begin
Writeln(GAMENAME,' by ',GAMEAUTH);
Writeln('v.',GAMEVERS,' (build ',GAMEDATE,')');
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
      end;
   If (GameOn) and (GameMode <> GM_TUTORIAL) and (Given >= 8) then begin
      GameOn:=False; Outro() end;
   Until (MenuChoice = 'Q') or (Shutdown);
QuitProg()
end.

