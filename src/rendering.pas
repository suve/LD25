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

Procedure HandleWindowResizedEvent(Ev: PSDL_Event);

{$IFNDEF ANDROID}
// Unused at the moment. Revise whether this is actually needed.
Procedure ResizeWindow(W,H:uInt;Full:Boolean=FALSE);
{$ENDIF}

// Set up buffers for drawing frame, send frame to display
Procedure BeginFrame();
Procedure FinishFrame();


Implementation
Uses
	ctypes,
	{$IFDEF ANDROID} TouchControls, {$ENDIF}
	Shared;

Var
	WindowTex: PSDL_Texture;

	{$IFDEF ANDROID}
	GameArea: TSDL_Rect;
	{$ENDIF}

Procedure HandleWindowResizedEvent(Ev: PSDL_Event);
{$IFDEF ANDROID}
Const
	BUTTON_SIZE = 16;
	DPAD_SIZE = 5 * BUTTON_SIZE;
{$ENDIF}
Var
	ww, wh: cint;

	{$IFDEF ANDROID}
	TotalHeight, VerticalOffset: uInt;
	TotalWidth, HorizontalOffset: uInt;
	DPad, ShootBtns: TSDL_Rect;
	{$ENDIF}
Begin
	If (Ev <> NIL) then begin
		Wnd_W := Ev^.Window.Data1;
		Wnd_H := Ev^.Window.Data2
	end else begin
		SDL_GetWindowSize(Window, @ww, @wh);
		Wnd_W := ww;
		Wnd_H := wh
	end;

	(*
	 * FIXME: This code is quite naive and will produce rather bogus setups
	 *        on devices with an aspect ratio close to 1:1 (like 5:4 tablets).
	 *)
	{$IFDEF ANDROID}
	If (Wnd_W >= Wnd_H) then begin // "Landscape" mode
		TotalWidth := RESOL_W + DPAD_SIZE + BUTTON_SIZE;
		TotalWidth := (TotalWidth * Wnd_H) div RESOL_H;
		HorizontalOffset := (Wnd_W - TotalWidth) div 4;

		DPad.X := HorizontalOffset;
		DPad.Y := (((RESOL_H - DPAD_SIZE) div 2) * Wnd_H) div RESOL_H;
		DPad.W := (DPAD_SIZE * Wnd_H) div RESOL_H;
		DPad.H := DPad.W;

		GameArea.X := DPad.X + DPad.W + HorizontalOffset;
		GameArea.Y := 0;
		GameArea.W := Wnd_H;
		GameArea.H := Wnd_H;

		ShootBtns.X := GameArea.X + GameArea.W + HorizontalOffset;
		ShootBtns.Y := DPad.Y;
		ShootBtns.W := (BUTTON_SIZE * Wnd_H) div RESOL_H;
		ShootBtns.H := DPad.H
	end else begin // "Portrait" mode
		TotalHeight := RESOL_H + DPAD_SIZE;
		TotalHeight := (TotalHeight * Wnd_W) div RESOL_W;
		VerticalOffset := (Wnd_H - TotalHeight) div 3;

		GameArea.X := 0;
		GameArea.Y := VerticalOffset;
		GameArea.W := Wnd_W;
		GameArea.H := Wnd_W;

		DPad.X := (BUTTON_SIZE * Wnd_W) div RESOL_W;
		DPad.Y := GameArea.Y + GameArea.H + VerticalOffset;
		DPad.W := (DPAD_SIZE * Wnd_W) div RESOL_W;
		DPad.H := DPad.W;

		ShootBtns.X := ((RESOL_W - 2 * BUTTON_SIZE) * Wnd_W) div RESOL_W;
		ShootBtns.Y := DPad.Y;
		ShootBtns.W := (BUTTON_SIZE * Wnd_W) div RESOL_W;
		ShootBtns.H := DPad.H
	end;

	TouchControls.SetPosition(@DPad, @ShootBtns);
	{$ENDIF}
End;

{$IFNDEF ANDROID}
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

Procedure BeginFrame();
Begin
	WindowTex := SDL_GetRenderTarget(Renderer);
	SDL_SetRenderTarget(Renderer, Display);

	SDL_SetRenderDrawBlendMode(Renderer, SDL_BLENDMODE_BLEND);
	SDL_SetRenderDrawColor(Renderer, 0, 0, 0, 255);
	SDL_RenderClear(Renderer)
End;

Procedure FinishFrame();
Begin
	SDL_SetRenderTarget(Renderer, WindowTex);
	
	SDL_SetRenderDrawBlendMode(Renderer, SDL_BLENDMODE_BLEND);
	SDL_SetRenderDrawColor(Renderer, 0, 0, 0, 255);
	SDL_RenderClear(Renderer);

	{$IFDEF ANDROID}
		SDL_RenderSetLogicalSize(Renderer, Wnd_W, Wnd_H);
		SDL_RenderCopy(Renderer, Display, NIL, @GameArea);

		// TODO: Draw these only when in game
		If (GameOn) then TouchControls.Draw();

		SDL_RenderSetLogicalSize(Renderer, RESOL_W, RESOL_H);
	{$ELSE}
		SDL_RenderCopy(Renderer, Display, NIL, NIL);
	{$ENDIF}
	SDL_RenderPresent(Renderer);
End;

End.
