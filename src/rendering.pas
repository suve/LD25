(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2024 suve (a.k.a. Artur Frenszek Iwicki)
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
Unit Rendering;

{$INCLUDE defines.inc}


Interface
Uses
	SDL2;

Const 
	WINDOW_W = 640; WINDOW_H = 640; // Default window size
	RESOL_W = 320; RESOL_H = 320;   // Game resolution (SDL renderer logical size)

Var 
	Window   : PSDL_Window;   // Game window
	Renderer : PSDL_Renderer; // Renderer handle
	Display  : PSDL_Texture;  // The drawing target texture

	(*
	 * Window width, height, and fullscreen flag.
	 * These can be read by using SDL_GetWindowSize() and such,
	 * but we save the .ini after shutting down SDL.
	 *)
	Wnd_W, Wnd_H: uInt;
	Wnd_F : Boolean;

	{$IFDEF LD25_MOBILE}
	SwapTouchControls: Boolean;
	{$ENDIF}

Procedure HandleWindowResizedEvent(Ev: PSDL_Event);

{$IFDEF LD25_MOBILE}
Procedure TranslateMouseEventCoords(Ev: PSDL_Event);
Procedure WindowCoordsToGameCoords(Const WindowX, WindowY: sInt; Out GameX, GameY: sInt);
{$ENDIF}

Function GetWindowInfo(): AnsiString;
Function GetRendererInfo(): AnsiString;

// Set up buffers for drawing frame, send frame to display
Procedure BeginFrame();
Procedure FinishFrame();


Implementation
Uses
	ctypes,
	{$IFDEF LD25_MOBILE} TouchControls, {$ENDIF}
	Shared, Toast;

Var
	WindowTex: PSDL_Texture;

{$IFDEF LD25_MOBILE}
Var
	GameArea: TSDL_Rect;

Const
	BACK_SIZE = 40;
	DPAD_SIZE = 120;
	SHOOT_SIZE = 32;
	SLIDE_SIZE = 40;

Procedure LandscapeMode(Out DPad, ShootBtns, BackBtn, SlideLeft, SlideRight: TSDL_Rect);
Var
	TotalWidth: sInt;
	HorizontalOffset: sInt;
Begin
	TotalWidth := RESOL_W + DPAD_SIZE + SHOOT_SIZE;
	TotalWidth := (TotalWidth * Wnd_H) div RESOL_H;
	HorizontalOffset := (Wnd_W - TotalWidth) div 4;

	DPad.W := (DPAD_SIZE * Wnd_H) div RESOL_H;
	DPad.H := DPad.W;
	DPad.Y := (((RESOL_H - DPAD_SIZE) div 2) * Wnd_H) div RESOL_H;

	ShootBtns.W := (SHOOT_SIZE * Wnd_H) div RESOL_H;
	ShootBtns.H := (ShootBtns.W * 7) div 2;
	ShootBtns.Y := DPad.Y + ((DPad.H - ShootBtns.H) div 2);

	GameArea.W := Wnd_H;
	GameArea.H := Wnd_H;
	GameArea.Y := 0;

	BackBtn.W := (BACK_SIZE * Wnd_H) div RESOL_H;
	BackBtn.H := BackBtn.W;
	BackBtn.Y := 0;

	SlideLeft.W := (ShootBtns.W * SLIDE_SIZE) div SHOOT_SIZE;
	SlideLeft.H := SlideLeft.W;
	SlideLeft.Y := DPad.Y + ((DPad.H - SlideLeft.H) div 2);
	SlideLeft.X := HorizontalOffset;

	SlideRight := SlideLeft;
	SlideRight.X := Wnd_W - SlideRight.W - HorizontalOffset;

	If(Not SwapTouchControls) then begin
		DPad.X := HorizontalOffset;
		GameArea.X := DPad.X + DPad.W + HorizontalOffset;
		ShootBtns.X := Wnd_W - ShootBtns.W - HorizontalOffset;
		BackBtn.X := 0;
	end else begin
		ShootBtns.X := HorizontalOffset;
		GameArea.X := ShootBtns.X + ShootBtns.W + HorizontalOffset;
		DPad.X := Wnd_W - DPad.W - HorizontalOffset;
		BackBtn.X := Wnd_W - BackBtn.W
	end
End;

Procedure PortraitMode(Out DPad, ShootBtns, BackBtn, SlideLeft, SlideRight: TSDL_Rect);
Var
	TotalHeight: sInt;
	HorizontalOffset, VerticalOffset: sInt;
Begin
	TotalHeight := RESOL_H + DPAD_SIZE;
	TotalHeight := (TotalHeight * Wnd_W) div RESOL_W;
	VerticalOffset := (Wnd_H - TotalHeight) div 3;
	HorizontalOffset := (((RESOL_W - DPAD_SIZE - SHOOT_SIZE) div 4) * Wnd_W) div RESOL_W;

	GameArea.X := 0;
	GameArea.Y := VerticalOffset;
	GameArea.W := Wnd_W;
	GameArea.H := Wnd_W;

	DPad.W := (DPAD_SIZE * Wnd_W) div RESOL_W;
	DPad.H := DPad.W;
	DPad.Y := GameArea.Y + GameArea.H + VerticalOffset;

	ShootBtns.W := (SHOOT_SIZE * Wnd_W) div RESOL_W;
	ShootBtns.H := (ShootBtns.W * 7) div 2;
	ShootBtns.Y := DPad.Y + ((DPad.H - ShootBtns.H) div 2);

	BackBtn.W := (BACK_SIZE * Wnd_W) div RESOL_W;
	BackBtn.H := BackBtn.W;
	BackBtn.Y := Wnd_H - BackBtn.H;

	SlideLeft.W := (ShootBtns.W * SLIDE_SIZE) div SHOOT_SIZE;
	SlideLeft.H := SlideLeft.W;
	SlideLeft.Y := DPad.Y + ((DPad.H - SlideLeft.H) div 2);
	SlideLeft.X := HorizontalOffset;

	SlideRight := SlideLeft;
	SlideRight.X := Wnd_W - SlideRight.W - HorizontalOffset;

	If(Not SwapTouchControls) then begin
		DPad.X := HorizontalOffset;
		ShootBtns.X := Wnd_W - ShootBtns.W - HorizontalOffset;
		BackBtn.X := 0
	end else begin
		ShootBtns.X := HorizontalOffset;
		DPad.X := Wnd_W - DPad.W - HorizontalOffset;
		BackBtn.X := Wnd_W - BackBtn.W
	end
End;

Procedure SquareMode(Out DPad, ShootBtns, BackBtn, SlideLeft, SlideRight: TSDL_Rect);
Const
	SQRT_TWO = Sqrt(2);
Var
	SquareSize: uInt;
	VerticalOffset, HorizontalOffset: sInt;
	Overlap: uInt;
Begin
	If(Wnd_W >= Wnd_H) then begin
		SquareSize := Wnd_H;
		HorizontalOffset := (Wnd_W - Wnd_H) div 3;
		VerticalOffset := 0;
	end else begin
		SquareSize := Wnd_W;
		VerticalOffset := (Wnd_H - Wnd_W) div 3;
		HorizontalOffset := 0
	end;

	GameArea.Y := VerticalOffset;
	GameArea.W := (RESOL_W * SquareSize) div (RESOL_W + DPAD_SIZE);
	GameArea.H := (RESOL_H * SquareSize) div (RESOL_H + DPAD_SIZE);

	DPad.W := (DPAD_SIZE * SquareSize) div (RESOL_W + DPAD_SIZE);
	DPad.H := (DPAD_SIZE * SquareSize) div (RESOL_H + DPAD_SIZE);
	DPad.Y := Wnd_H - DPad.H - VerticalOffset;

	ShootBtns.H := (SHOOT_SIZE * SquareSize) div (RESOL_H + DPAD_SIZE);
	ShootBtns.W := (ShootBtns.H * 7) div 2;
	ShootBtns.Y := DPad.Y + ((DPad.H - ShootBtns.H) div 2);

	BackBtn.W := (BACK_SIZE * SquareSize) div (RESOL_W + DPAD_SIZE);
	BackBtn.H := (BACK_SIZE * SquareSize) div (RESOL_H + DPAD_SIZE);
	BackBtn.Y := 0;

	SlideLeft.H := (ShootBtns.H * SLIDE_SIZE) div SHOOT_SIZE;
	SlideLeft.W := SlideLeft.H;
	SlideLeft.Y := DPad.Y + ((DPad.H - SlideLeft.H) div 2);
	SlideLeft.X := HorizontalOffset;

	SlideRight := SlideLeft;
	SlideRight.X := Wnd_W - SlideRight.W - HorizontalOffset;

	(*
	 * The game area can be made slightly bigger by accounting for the fact
	 * that the DPad is an octagon, and making the game area stretch
	 * all the way to touch the sloped side of the DPad, i.e.:
	 *
	 *  __v  Touch the middle of this side
	 * /  \< instead of the corner of the bounding box.
	 * |  |
	 * \__/
	 *
	 * If we assume a regular octagon, then the triangle formed between
	 * the sloped side of the polygon and the bounding box is isosceles,
	 * with angles of 90, 45 and 45 degrees. If the side shared with the
	 * octagon has a length of a, then the other two sides of the triangle
	 * have a length of a / sqrt(2).
	 *
	 * This means the length of a side of the bounding box is:
	 *   b = a + 2 * (a / sqrt(2)) = a + a * sqrt(2) = a * (1 + sqrt(2))
	 * To make the game area touch the middle of the octagon's sloped
	 * side, we need to calculate "a / sqrt(2) / 2":
	 *   a = b / (1 + sqrt(2))
	 *   a / (2 * sqrt(2)) = b / (2 * (sqrt(2) + 2))
	 * This is the value we put in the Overlap variable.
	 *)
	Overlap := Trunc( ((DPad.W + DPad.H) / 2.0) / (2.0 * (SQRT_TWO + 2.0)) );
	If(Not SwapTouchControls) then begin
		DPad.X := HorizontalOffset;
		GameArea.X := DPad.X + DPad.W + HorizontalOffset - Overlap;
		ShootBtns.X := Wnd_W - ShootBtns.W - (Wnd_H - ShootBtns.Y - ShootBtns.H);
		BackBtn.X := 0
	end else begin
		GameArea.X := HorizontalOffset;
		DPad.X := GameArea.X + GameArea.W + HorizontalOffset;
		ShootBtns.X := (Wnd_H - ShootBtns.Y - ShootBtns.H);
		BackBtn.X := Wnd_W - BackBtn.W
	end;
	GameArea.W += Overlap;
	GameArea.H += Overlap;
End;

Procedure PositionTouchControls();
Const
	{$IFDEF LD25_DEBUG}
		ASCII_HT = #9;
		ASCII_LF = #10;

		LOG_FORMAT = 'Re-positioning: window size is %dx%d -> %s mode;' + ASCII_LF +
			ASCII_HT + '- game: %dx%d @ %dx%d;' + ASCII_LF +
			ASCII_HT + '- dpad: %dx%d @ %dx%d;' + ASCII_LF +
			ASCII_HT + '- shbt: %dx%d @ %dx%d;' + ASCII_LF +
			ASCII_HT + '- back: %dx%d @ %dx%d;' + ASCII_LF +
			ASCII_HT + '- slid: %dx%d : %dx%d @ %dx%d' + ASCII_LF;
	{$ENDIF}	

	ASPECT_RATIO_MUL = 1000;

	LANDSCAPE_WIDTH = RESOL_W + DPAD_SIZE + SHOOT_SIZE;
	LANDSCAPE_RATIO = (LANDSCAPE_WIDTH * ASPECT_RATIO_MUL) div RESOL_H;

	PORTRAIT_HEIGHT = RESOL_H + DPAD_SIZE;
	PORTRAIT_RATIO = (RESOL_W * ASPECT_RATIO_MUL) div PORTRAIT_HEIGHT;
Var
	AspectRatio: uInt;
	DPad, ShootBtns, BackBtn, SlideLeft, SlideRight: TSDL_Rect;
	{$IFDEF LD25_DEBUG} Mode: AnsiString; {$ENDIF}
Begin
	AspectRatio := (Wnd_W * ASPECT_RATIO_MUL) div Wnd_H;
	If (AspectRatio >= LANDSCAPE_RATIO) then begin
		{$IFDEF LD25_DEBUG} Mode := 'landscape'; {$ENDIF}
		LandscapeMode(DPad, ShootBtns, BackBtn, SlideLeft, SlideRight)
	end else
	If (AspectRatio <= PORTRAIT_RATIO) then begin
		{$IFDEF LD25_DEBUG} Mode := 'portrait'; {$ENDIF}
		PortraitMode(DPad, ShootBtns, BackBtn, SlideLeft, SlideRight)
	end else begin
		{$IFDEF LD25_DEBUG} Mode := 'square'; {$ENDIF}
		SquareMode(DPad, ShootBtns, BackBtn, SlideLeft, SlideRight)
	end;

	{$IFDEF LD25_DEBUG}
	SDL_LogDebug(
		SDL_LOG_CATEGORY_APPLICATION,
		LOG_FORMAT,
		[
			cint(Wnd_W), cint(Wnd_H),
			PChar(Mode),
			cint(GameArea.X), cint(GameArea.Y), cint(GameArea.W), cint(GameArea.H),
			cint(DPad.X), cint(DPad.Y), cint(DPad.W), cint(DPad.H),
			cint(ShootBtns.X), cint(ShootBtns.Y), cint(ShootBtns.W), cint(ShootBtns.H),
			cint(BackBtn.X), cint(BackBtn.Y), cint(BackBtn.W), cint(BackBtn.H),
			cint(SlideLeft.X), cint(SlideLeft.Y), cint(SlideRight.X), cint(SlideRight.Y), cint(SlideRight.W), cint(SlideRight.H)
		]
	);
	{$ENDIF}

	TouchControls.SetMovementWheelPosition(DPad);
	TouchControls.SetShootButtonsPosition(ShootBtns);
	TouchControls.SetGoBackButtonPosition(BackBtn);
	TouchControls.SetSlideButtonsPosition(SlideLeft, SlideRight)
End;
{$ENDIF}

Procedure HandleWindowResizedEvent(Ev: PSDL_Event);
Var
	ww, wh: cint;
Begin
	If (Ev <> NIL) then begin
		Wnd_W := Ev^.Window.Data1;
		Wnd_H := Ev^.Window.Data2
	end else begin
		SDL_GetWindowSize(Window, @ww, @wh);
		Wnd_W := ww;
		Wnd_H := wh
	end;

	{$IFDEF LD25_MOBILE}
		PositionTouchControls()
	{$ENDIF}
End;

{$IFDEF LD25_MOBILE}
Procedure TranslateMouseEventCoords(Ev: PSDL_Event);
Var
	GameX, GameY: sInt;
Begin
	WindowCoordsToGameCoords(Ev^.Button.X, Ev^.Button.Y, GameX, GameY);
	Ev^.Button.X := GameX;
	Ev^.Button.Y := GameY
End;

Procedure WindowCoordsToGameCoords(Const WindowX, WindowY: sInt; Out GameX, GameY: sInt);
Begin
	GameX := ((WindowX - GameArea.X) * RESOL_W) div GameArea.W;
	GameY := ((WindowY - GameArea.Y) * RESOL_H) div GameArea.H
End;
{$ENDIF}

Function GetWindowInfo(): AnsiString;
Var
	ww, wh: cint;
	Flags: UInt32;

	Procedure CheckFlag(FlagValue: UInt32; FlagName: AnsiString);
	Begin
		If((Flags and FlagValue) = FlagValue) then begin
			Result += ', ' + FlagName
		end
	End;
Begin
	If(Window = NIL) then Exit('none');

	SDL_GetWindowSize(Window, @ww, @wh);
	Flags := SDL_GetWindowFlags(Window);

	WriteStr(Result, ww, 'x', wh);

	(*
	 * Some of the flags are commented-out. This is on purpose,
	 * to make it easy to differentiate between a flag we don't care about
	 * and an unknown flag that was added in a newer version of SDL.
	 *)
	CheckFlag(SDL_WINDOW_FULLSCREEN,         'fullscreen');
	CheckFlag(SDL_WINDOW_FULLSCREEN_DESKTOP, 'fullscreen-desktop');
	CheckFlag(SDL_WINDOW_OPENGL,             'opengl');
	CheckFlag(SDL_WINDOW_VULKAN,             'vulkan');
	// CheckFlag(SDL_WINDOW_SHOWN,              'shown');
	// CheckFlag(SDL_WINDOW_HIDDEN,             'hidden');
	CheckFlag(SDL_WINDOW_BORDERLESS,         'borderless');
	CheckFlag(SDL_WINDOW_RESIZABLE,          'resizable');
	CheckFlag(SDL_WINDOW_MINIMIZED,          'minimized');
	CheckFlag(SDL_WINDOW_MAXIMIZED,          'maximized');
	CheckFlag(SDL_WINDOW_INPUT_GRABBED,      'input-grabbed');
	CheckFlag(SDL_WINDOW_INPUT_FOCUS,        'input-focus');
	CheckFlag(SDL_WINDOW_MOUSE_CAPTURE,      'mouse-grabbed');
	CheckFlag(SDL_WINDOW_MOUSE_FOCUS,        'mouse-focus');
	CheckFlag(SDL_WINDOW_FOREIGN,            'foreign');
	CheckFlag(SDL_WINDOW_ALLOW_HIGHDPI,      'hidpi');
	CheckFlag(SDL_WINDOW_ALWAYS_ON_TOP,      'always-on-top');
	CheckFlag(SDL_WINDOW_SKIP_TASKBAR,       'skip-taskbar');
	// CheckFlag(SDL_WINDOW_UTILITY,            'utility');
	// CheckFlag(SDL_WINDOW_TOOLTIP,            'tooltip');
	// CheckFlag(SDL_WINDOW_POPUP_MENU,         'popup-menu');
End;

Function GetRendererInfo(): AnsiString;
Var
	Info: TSDL_RendererInfo;

	Procedure CheckFlag(FlagValue: UInt32; FlagName: AnsiString);
	Begin
		If((Info.Flags and FlagValue) = FlagValue) then begin
			Result += ', ' + FlagName
		end
	End;
Begin
	If(Renderer = NIL) then Exit('none');
	If(SDL_GetRendererInfo(Renderer, @Info) <> 0) then Exit('unknown');

	WriteStr(Result, '"', Info.Name, '", maxsize: ', Info.max_texture_width, 'x', Info.max_texture_height);
	CheckFlag(SDL_RENDERER_SOFTWARE,      'software');
	CheckFlag(SDL_RENDERER_ACCELERATED,   'accelerated');
	CheckFlag(SDL_RENDERER_PRESENTVSYNC,  'vsync');
	CheckFlag(SDL_RENDERER_TARGETTEXTURE, 'target-texture')
End;

Procedure BeginFrame();
Begin
	WindowTex := SDL_GetRenderTarget(Renderer);
	SDL_SetRenderTarget(Renderer, Display);

	{$IFDEF LD25_MOBILE}
	SDL_RenderSetLogicalSize(Renderer, RESOL_W, RESOL_H);
	{$ENDIF}

	SDL_SetRenderDrawBlendMode(Renderer, SDL_BLENDMODE_BLEND);
	SDL_SetRenderDrawColor(Renderer, 0, 0, 0, 255);
	SDL_RenderClear(Renderer)
End;

Procedure FinishFrame();
Begin
	// This really, really stinks
	Toast.Render();

	SDL_SetRenderTarget(Renderer, WindowTex);
	{$IFDEF LD25_MOBILE}
	SDL_RenderSetLogicalSize(Renderer, Wnd_W, Wnd_H);
	{$ENDIF}

	SDL_SetRenderDrawBlendMode(Renderer, SDL_BLENDMODE_BLEND);
	SDL_SetRenderDrawColor(Renderer, 0, 0, 0, 255);
	SDL_RenderClear(Renderer);

	{$IFDEF LD25_MOBILE}
		SDL_RenderCopy(Renderer, Display, NIL, @GameArea);
		TouchControls.Draw();
	{$ELSE}
		SDL_RenderCopy(Renderer, Display, NIL, NIL);
	{$ENDIF}
	SDL_RenderPresent(Renderer);
End;

End.
