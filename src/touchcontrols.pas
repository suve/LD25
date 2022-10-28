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
Procedure HandleEvent(ev: PSDL_Event);

Procedure SetPosition(DPad, ShootBtns: PSDL_Rect);


Implementation

Uses
	Assets, MathUtils, Rendering, Shared;

Const
	BUTTON_SIZE = 16;

Type
	ButtonProps = record
		Pos: TSDL_Rect;
		Finger: TSDL_FingerID;
		Touched: Boolean
	end;

Var
	MovementButton: Array[0..7] of ButtonProps;
	ShootLeftButton: ButtonProps;
	ShootRightButton: ButtonProps;

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
		SDL_RenderCopyEx(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @MovementButton[Idx].Pos, (Idx div 2) * 90.0, NIL, SDL_FLIP_NONE)
	end;

	Src.Y := BUTTON_SIZE * 2;
	SDL_RenderCopy(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @ShootLeftButton.Pos);
	SDL_RenderCopyEx(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @ShootRightButton.Pos, 0, NIL, SDL_FLIP_HORIZONTAL)
End;

Function FingerInRect(Const FingerX, FingerY: sInt; Const Rect: TSDL_Rect): Boolean;
Begin
	Result := Overlap(Rect.X, Rect.Y, Rect.W, Rect.H, FingerX, FingerY, 1, 1)
End;

Procedure PressMovementKeys();
Begin
	Key[KEY_UP] := MovementButton[0].Touched or MovementButton[1].Touched or MovementButton[7].Touched;
	Key[KEY_RIGHT] := MovementButton[1].Touched or MovementButton[2].Touched or MovementButton[3].Touched;
	Key[KEY_DOWN] := MovementButton[3].Touched or MovementButton[4].Touched or MovementButton[5].Touched;
	Key[KEY_LEFT] := MovementButton[5].Touched or MovementButton[6].Touched or MovementButton[7].Touched
End;

Procedure UnfingerButtons(Finger: TSDL_FingerID);
Var
	Idx: uInt;
Begin
	If (ShootLeftButton.Touched) and (ShootLeftButton.Finger = Finger) then begin
		ShootLeftButton.Touched := False;
		Key[KEY_SHOOTLEFT] := False;
		Exit()
	end;
	If (ShootRightButton.Touched) and (ShootRightButton.Finger = Finger) then begin
		ShootRightButton.Touched := False;
		Key[KEY_SHOOTRIGHT] := False;
		Exit()
	end;
	For Idx := 0 to 7 do begin
		If (MovementButton[Idx].Touched) and (MovementButton[Idx].Finger = Finger) then begin
			MovementButton[Idx].Touched := False;
			PressMovementKeys();
			Exit()
		end
	end;
End;

Procedure HandleEvent(ev: PSDL_Event);
Var
	Idx: uInt;
	FingerX, FingerY: sInt;
Begin
	If (Ev^.Type_ = SDL_FingerUp) then begin
		UnfingerButtons(Ev^.TFinger.FingerID);
		Exit()
	end;

	FingerX := Trunc(Ev^.TFinger.X * Wnd_W);
	FingerY := Trunc(Ev^.TFinger.Y * Wnd_H);

	If FingerInRect(FingerX, FingerY, ShootLeftButton.Pos) then begin
		ShootLeftButton.Touched := True;
		ShootLeftButton.Finger := Ev^.TFinger.FingerID;
		Key[KEY_SHOOTLEFT] := True;
		Exit()
	end else
	If FingerInRect(FingerX, FingerY, ShootRightButton.Pos) then begin
		ShootRightButton.Touched := True;
		ShootRightButton.Finger := Ev^.TFinger.FingerID;
		Key[KEY_SHOOTRIGHT] := True;
		Exit()
	end else
	For Idx := 0 to 7 do begin
		If Not FingerInRect(FingerX, FingerY, MovementButton[Idx].Pos) then Continue;

		MovementButton[Idx].Touched := True;
		MovementButton[Idx].Finger := Ev^.TFinger.FingerID;
		PressMovementKeys();
		Exit()
	end;

	(*
	 * Touch event does not fall inside a button.
	 * If this is a motion event, perform the "unfinger" logic,
	 * since a finger could have been touching a button
	 * and now moved outside of it.
	 *)
	If (Ev^.Type_ = SDL_FingerMotion) then UnfingerButtons(Ev^.TFinger.FingerID)
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

			MovementButton[Idx].Pos.X := DPad^.X + (PosX * BtnW);
			MovementButton[Idx].Pos.Y := DPad^.Y + (PosY * BtnH);
			MovementButton[Idx].Pos.W := BtnW;
			MovementButton[Idx].Pos.H := BtnH;
			MovementButton[Idx].Touched := False;

			// Mark virtual movement keys as not being pressed
			Key[KEY_UP] := False;
			Key[KEY_RIGHT] := False;
			Key[KEY_DOWN] := False;
			Key[KEY_LEFT] := False;
		end
	end;
	If (ShootBtns <> NIL) then begin
		BtnW := ShootBtns^.W;
		BtnH := BtnW;

		ShootLeftButton.Pos.X := ShootBtns^.X;
		ShootLeftButton.Pos.Y := ShootBtns^.Y;
		ShootLeftButton.Pos.W := BtnW;
		ShootLeftButton.Pos.H := BtnH;
		ShootLeftButton.Touched := False;

		ShootRightButton.Pos.X := ShootBtns^.X;
		ShootRightButton.Pos.Y := ShootBtns^.Y + ShootBtns^.H - BtnH;
		ShootRightButton.Pos.W := BtnW;
		ShootRightButton.Pos.H := BtnH;
		ShootRightButton.Touched := False;

		// Mark virtual "shoot" keys as not being pressed
		Key[KEY_SHOOTLEFT] := False;
		Key[KEY_SHOOTRIGHT] := False;
	end
End;

End.
