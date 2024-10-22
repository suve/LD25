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
{$IFNDEF ANDROID}
	program ld25;
{$ELSE}
	library ld25;
{$ENDIF}

{$INCLUDE defines.inc}

uses
	SysUtils, Math, ctypes,
	SDL2, SDL2_image, SDL2_mixer,
	Assets, Colours, ConfigFiles, Controllers, FloatingText, Fonts,
	Game, Images, Objects, MathUtils,
	Menus, Menus.Colours, Menus.Gamepad, Menus.Gameworld, Menus.Main,
	{$IFDEF LD25_DONATE} Menus.Donate, {$ENDIF}
	Rendering, Shared, Slides, Stats, Timekeeping, Toast,
	{$IFDEF LD25_MOBILE}
		Menus.Options, TouchControls
	{$ELSE}
		Menus.Keybinds
	{$ENDIF}
;


Var
	MenuChoice:Char;

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
	DrawRectFilled(@Rect, @WhiteColour);
	
	Col.R := 64+Random(128);
	Col.G := 64+Random(128);
	Col.B := 64+Random(128);
	Col.A := 255;
	Rect.W := Trunc(SIZEX*Perc);
	DrawRectFilled(@Rect, @Col);
	
	Rendering.FinishFrame()
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

	{$IFDEF LD25_COMPAT_V1}
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

	Result := SDL_Init(SDL_INIT_VIDEO or SDL_INIT_EVENTS or SDL_INIT_TIMER) = 0
End;

Procedure Startup();
Var
	StartTime: TTimeStamp;
	GM: TGameMode;
	OldMask, NewMask: TFPUExceptionMask;
	Assload: Assets.TLoadingResult;

	ControllerCount: sInt;
	ControllerInfo: Array[0..4] of TControllerInfo;
Begin
	StartTime:=GetTimeStamp(); Randomize();

	// Reset some global vars to known values
	Shutdown:=False;
	GameOn:=False;
	NoSound:=False;

	ConfigFiles.SetPaths();
	{$IFDEF LD25_COMPAT_V1}
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

	(*
	 * Do not show controller toasts while loading.
	 * On desktop, this will save us from a segfault due to missing font.
	 * On Android, this will prevent us from showing the "found device" toast
	 * twice. (First during init and then after init is finished.)
	 *)
	Toast.SetVisibility(False);
	InitControllers();

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

	{$IF DEFINED(LD25_MOBILE)}
		// Make sure the game does not try to render touch controls while assets
		// are still being loaded (touch-controls.png is quite far down the list)
		TouchControls.SetVisibility(TCV_NONE);
	{$ENDIF}

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

	// Init buffers with some default sizes
	PlayerBullets.Create(16);
	EnemyBullets.Create(16);
	Gibs.Create(GIBS_PIECES_TOTAL * 4);
	Mobs.Create(8);
	Hero:=NIL;

	(*
	 * Toast duration is not tied to the "real" number of ticks as reported by SDL,
	 * but rather to the cached value found in the Timekeeping unit.
	 * Advancing the timer here ensures that the toast is shown for the full
	 * intended duration, not affected by the startup time.
	 *)
	Timekeeping.AdvanceTime();

	// This is not the best way to do this, as the user could potentially have
	// more controllers than the length of the array, but - eh, good enough.
	EnumerateControllers(ControllerCount, ControllerInfo);
	Toast.SetVisibility(True);
	If(ControllerCount > 0) then
		If(ControllerCount > 1) then
			Toast.Show(TH_CONTROLLER_FOUND_MULTIPLE, IntToStr(ControllerCount) + ' devices')
		else
			Toast.Show(TH_CONTROLLER_FOUND, ControllerInfo[0].Name);

	SDL_Log('All done! Initialization finished in %ld ms.', [clong(TimeStampDiffMillis(StartTime, GetTimeStamp()))])
End;

Procedure NewGame(Const GM:TGameMode);
Begin
	If(GM <> GameMode) then SaveCurrentGame();

	GameMode:=GM;
	DestroyEntities(True); ResetGamestate();
	New(Hero,Create()); ChangeRoom(RespRoom[GM].X,RespRoom[GM].Y);
	Stats.ZeroSaveStats();
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
				MenuChoice:=GameworldDialog(GWSR_NEW_GAME);
				Case MenuChoice of
					'T': begin NewGame(GM_TUTORIAL); PlayGame() end;
					'C': begin NewGame(GM_ORIGINAL); PlayGame() end;
				end;
				MenuChoice:='N'
			end;
			'L': begin
				MenuChoice:=GameworldDialog(GWSR_LOAD_GAME);
				Case MenuChoice of
					'T': If(GameloadRequest(GM_TUTORIAL)) then PlayGame();
					'C': If(GameloadRequest(GM_ORIGINAL)) then PlayGame();
				end;
				MenuChoice:='L'
			end;
			'S': SetColours();
			'P': ConfigureGamepad();
			{$IFDEF LD25_MOBILE}
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
