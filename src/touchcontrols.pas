(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2022 suve (a.k.a. Artur Frenszek Iwicki)
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
Unit TouchControls; 

{$INCLUDE defines.inc}

Interface

Uses
	SDL2;

Procedure Draw();
Procedure ProcessEvent(ev: PSDL_Event);

Procedure SetPosition(DPad, ShootBtns: PSDL_Rect);


Implementation

Uses
	Assets, MathUtils, Rendering, Shared;

Const
	BUTTON_SIZE = 16;

Var
	MovementButton: Array[0..7] of TSDL_Rect;
	ShootLeftButton: TSDL_Rect;
	ShootRightButton: TSDL_Rect;

Procedure Draw();
Var
	Idx: uInt;
	Src: TSDL_Rect;
Begin
	Src.X := 0;
	Src.W := BUTTON_SIZE;
	Src.H := BUTTON_SIZE;

	For Idx := 0 to 7 do begin
		Src.Y := (Idx mod 2) * BUTTON_SIZE;
		SDL_RenderCopyEx(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @MovementButton[Idx], (Idx div 2) * 90.0, NIL, SDL_FLIP_NONE)
	end;

	Src.Y := BUTTON_SIZE * 2;
	SDL_RenderCopy(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @ShootLeftButton);
	SDL_RenderCopyEx(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @ShootRightButton, 0, NIL, SDL_FLIP_HORIZONTAL)
End;

Function MouseInRect(ev: PSDL_Event; Rect: TSDL_Rect): Boolean;
Begin
	Result := Overlap(Rect.X, Rect.Y, Rect.W, Rect.H, Ev^.Button.X, Ev^.Button.Y, 1, 1)
End;

Procedure ProcessEvent(ev: PSDL_Event);
Var
	SetTo: Boolean;
	Idx: uInt;
Begin
	If(Ev^.Type_ = SDL_MouseButtonDown) then
		SetTo := True
	else If(Ev^.Type_ = SDL_MouseButtonUp) then
		SetTo := False
	else
		Exit();
	
	For Idx := 0 to 7 do begin
		If Not MouseInRect(ev, MovementButton[Idx]) then Continue;

		If(Idx < 2) or (Idx = 7) then Key[KEY_UP] := SetTo;
		If(Idx > 0) and (Idx < 4) then Key[KEY_RIGHT] := SetTo;
		If(Idx > 2) and (Idx < 6) then Key[KEY_DOWN] := SetTo;
		If(Idx > 4) then Key[KEY_LEFT] := SetTo;
		Exit()
	end;

	If MouseInRect(ev, ShootLeftButton) then
		Key[KEY_SHOOTLEFT] := SetTo
	else If MouseInRect(ev, ShootRightButton) then
		Key[KEY_SHOOTRIGHT] := SetTo
End;

Procedure SetPosition(DPad, ShootBtns: PSDL_Rect);
Var
	Idx: uInt;
	PosX, PosY: uInt;
	BtnW, BtnH: uInt;
Begin
	If (DPad <> NIL) then begin
		BtnW := DPad^.W div 5;
		BtnH := DPad^.H div 5;
		For Idx := 0 to 7 do begin
			(* TODO: This can be reduced to a single equation. *)
			If(Idx <= 2) then
				PosX := Idx + 2
			else If(Idx <= 6) then
				PosX := 6 - Idx
			else
				PosX := 1;

			(* Same for this. *)
			If(Idx <= 4) then
				PosY := Idx
			else
				PosY := 8 - Idx;

			MovementButton[Idx].X := DPad^.X + (PosX * BtnW);
			MovementButton[Idx].Y := DPad^.Y + (PosY * BtnH);
			MovementButton[Idx].W := BtnW;
			MovementButton[Idx].H := BtnH;
		end
	end;
	If (ShootBtns <> NIL) then begin
		BtnW := ShootBtns^.W;
		BtnH := BtnW;

		ShootLeftButton.X := ShootBtns^.X;
		ShootLeftButton.Y := ShootBtns^.Y;
		ShootLeftButton.W := BtnW;
		ShootLeftButton.H := BtnH;

		ShootRightButton.X := ShootBtns^.X;
		ShootRightButton.Y := ShootBtns^.Y + ShootBtns^.H - BtnH;
		ShootRightButton.W := BtnW;
		ShootRightButton.H := BtnH
	end
End;

End.
