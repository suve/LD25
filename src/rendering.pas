(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2012-2023 suve (a.k.a. Artur Frenszek Iwicki)
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
{$ELSE}
// Unused at the moment. Revise whether this is actually needed.
Procedure ResizeWindow(W,H:uInt;Full:Boolean=FALSE);
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
	Shared;

Var
	WindowTex: PSDL_Texture;

{$IFDEF LD25_MOBILE}
Var
	GameArea: TSDL_Rect;

Procedure PositionTouchControls();
Const
	BUTTON_SIZE = 32;
	DPAD_SIZE = 120;
Var
	TotalHeight, VerticalOffset: uInt;
	TotalWidth, HorizontalOffset: uInt;
	DPad, ShootBtns: TSDL_Rect;
Begin
	(*
	 * FIXME: This code is quite naive and will produce rather bogus setups
	 *        on devices with an aspect ratio close to 1:1 (like 5:4 tablets).
	 *)
	If (Wnd_W >= Wnd_H) then begin // "Landscape" mode
		TotalWidth := RESOL_W + DPAD_SIZE + BUTTON_SIZE;
		TotalWidth := (TotalWidth * Wnd_H) div RESOL_H;
		HorizontalOffset := (Wnd_W - TotalWidth) div 4;

		DPad.W := (DPAD_SIZE * Wnd_H) div RESOL_H;
		DPad.H := DPad.W;
		DPad.Y := (((RESOL_H - DPAD_SIZE) div 2) * Wnd_H) div RESOL_H;

		ShootBtns.W := (BUTTON_SIZE * Wnd_H) div RESOL_H;
		ShootBtns.H := (ShootBtns.W * 7) div 2;
		ShootBtns.Y := DPad.Y + ((DPad.H - ShootBtns.H) div 2);

		GameArea.W := Wnd_H;
		GameArea.H := Wnd_H;
		GameArea.Y := 0;

		If(Not SwapTouchControls) then begin
			DPad.X := HorizontalOffset;
			GameArea.X := DPad.X + DPad.W + HorizontalOffset;
			ShootBtns.X := Wnd_W - ShootBtns.W - HorizontalOffset
		end else begin
			ShootBtns.X := HorizontalOffset;
			GameArea.X := ShootBtns.X + ShootBtns.W + HorizontalOffset;
			DPad.X := Wnd_W - DPad.W - HorizontalOffset
		end
	end else begin // "Portrait" mode
		TotalHeight := RESOL_H + DPAD_SIZE;
		TotalHeight := (TotalHeight * Wnd_W) div RESOL_W;
		VerticalOffset := (Wnd_H - TotalHeight) div 3;
		HorizontalOffset := (((RESOL_W - DPAD_SIZE - BUTTON_SIZE) div 4) * Wnd_W) div RESOL_W;

		GameArea.X := 0;
		GameArea.Y := VerticalOffset;
		GameArea.W := Wnd_W;
		GameArea.H := Wnd_W;

		DPad.W := (DPAD_SIZE * Wnd_W) div RESOL_W;
		DPad.H := DPad.W;
		DPad.Y := GameArea.Y + GameArea.H + VerticalOffset;

		ShootBtns.W := (BUTTON_SIZE * Wnd_W) div RESOL_W;
		ShootBtns.H := (ShootBtns.W * 7) div 2;
		ShootBtns.Y := DPad.Y + ((DPad.H - ShootBtns.H) div 2);

		If(Not SwapTouchControls) then begin
			DPad.X := HorizontalOffset;
			ShootBtns.X := Wnd_W - ShootBtns.W - HorizontalOffset
		end else begin
			ShootBtns.X := HorizontalOffset;
			DPad.X := Wnd_W - DPad.W - HorizontalOffset
		end
	end;

	TouchControls.SetPosition(@DPad, @ShootBtns)
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
{$ELSE}
Procedure ResizeWindow(W,H:uInt;Full:Boolean=FALSE);
Begin
	If (Full) then begin
		SDL_SetWindowSize(Window, RESOL_W, RESOL_H);
		SDL_SetWindowFullscreen(Window, SDL_WINDOW_FULLSCREEN_DESKTOP);
		Wnd_F := True
	end else begin
		SDL_SetWindowFullscreen(Window, 0);
		SDL_SetWindowSize(Window, W, H);

		(*
		 * Centre window on the screen, but _ONLY_ when coming back from fullscreen mode.
		 * Without this check, when resizing the window, the game would keep jumping
		 * back-and-forth as the WM would fight the game over setting the window position.
         *)
		If(Wnd_F) then SDL_SetWindowPosition(Window, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED);

		Wnd_W := W; Wnd_H := H;
		Wnd_F := False
	end
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
