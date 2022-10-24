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

// Resize window, duh
Procedure ResizeWindow(W,H:uInt;Full:Boolean=FALSE);

// Set up buffers for drawing frame, send frame to display
Procedure BeginFrame();
Procedure FinishFrame();


Implementation

Var
	WindowTex: PSDL_Texture;

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

	SDL_RenderCopy(Renderer, Display, NIL, NIL);
	SDL_RenderPresent(Renderer);
End;

End.
