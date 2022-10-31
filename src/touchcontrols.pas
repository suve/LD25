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

Procedure SetPosition(NewDPadPos, NewShootBtnsPos: PSDL_Rect);


Implementation

Uses
	Math,
	Assets, MathUtils, Rendering, Shared;

Type
	ButtonProps = record
		Touched: Boolean;
		Finger: TSDL_FingerID
	end;

Var
	MovementButton: Array[0..7] of ButtonProps;
	DPadX, DPadY, DPadSize: sInt;

	ShootLeftDst, ShootRightDst: TSDL_Rect;
	ShootLeftButton, ShootRightButton: ButtonProps;

Procedure Draw();
Const
	DPAD_QUARTER_SIZE = 60;
	BUTTON_SIZE = 24;
Var
	Idx: uInt;
	Src, Dst: TSDL_Rect;
Begin
	Src.X := 0;
	Src.Y := 0;
	Src.W := DPAD_QUARTER_SIZE;
	Src.H := DPAD_QUARTER_SIZE;

	Dst.W := DPadSize;
	Dst.H := DPadSize;
	For Idx := 0 to 3 do begin
		Dst.X := DPadX;
		If (Idx = 0) or (Idx = 3) then Dst.X -= DPadSize;
		Dst.Y := DPadY;
		If (Idx < 2) then Dst.Y -= DPadSize;

		SDL_RenderCopyEx(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @Dst, Idx * 90.0, NIL, SDL_FLIP_NONE)
	end;

	Src.X := (DPAD_QUARTER_SIZE - BUTTON_SIZE) div 2;
	Src.Y := DPAD_QUARTER_SIZE;
	Src.W := BUTTON_SIZE;
	Src.H := BUTTON_SIZE;
	SDL_RenderCopy(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @ShootLeftDst);
	SDL_RenderCopyEx(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @ShootRightDst, 0, NIL, SDL_FLIP_HORIZONTAL)
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

Function FingerInRect(Const FingerX, FingerY: sInt; Const Rect: TSDL_Rect): Boolean;
Begin
	Result := Overlap(Rect.X, Rect.Y, Rect.W, Rect.H, FingerX, FingerY, 1, 1)
End;

Function FingerPosToMovementButtonIdx(Const FingerX, FingerY: sInt): sInt;
Var
	DeadZoneSize: sInt;
	DiffX, DiffY: sInt;
	Dist, Angle: Double;
Begin
	DiffX := (FingerX - DPadX);
	DiffY := (FingerY - DPadY);
	DeadZoneSize := DPadSize div 5;
	If (DiffX = 0) then begin
		If (DiffY > +DeadZoneSize) and (DiffY <= +DPadSize) then Exit(4);
		If (DiffY < -DeadZoneSize) and (DiffY >= -DPadSize) then Exit(0);
		Exit(-1)
	end;

	Dist := Math.Hypot(DiffX, DiffY);
	If (Dist < DeadZoneSize) or (Dist > DPadSize) then Exit(-1);

	Angle := Math.RadToDeg(ArcTan2(DiffY / Dist, DiffX / Dist));
	Result := (Trunc(Angle + (360 * 2.5 / 8)) div 45) mod 8
End;

Procedure HandleEvent(ev: PSDL_Event);
Var
	Idx: sInt;
	FingerX, FingerY: sInt;
Begin
	If (Ev^.Type_ = SDL_FingerUp) then begin
		UnfingerButtons(Ev^.TFinger.FingerID);
		Exit()
	end;

	FingerX := Trunc(Ev^.TFinger.X * Wnd_W);
	FingerY := Trunc(Ev^.TFinger.Y * Wnd_H);

	(*
	 * If this is a motion event, perform the "unfinger" logic,
	 * since a finger could have been touching a button
	 * and now moved to a different button (or no button).
	 *)
	If (Ev^.Type_ = SDL_FingerMotion) then UnfingerButtons(Ev^.TFinger.FingerID);

	If FingerInRect(FingerX, FingerY, ShootLeftDst) then begin
		ShootLeftButton.Touched := True;
		ShootLeftButton.Finger := Ev^.TFinger.FingerID;
		Key[KEY_SHOOTLEFT] := True
	end else
	If FingerInRect(FingerX, FingerY, ShootRightDst) then begin
		ShootRightButton.Touched := True;
		ShootRightButton.Finger := Ev^.TFinger.FingerID;
		Key[KEY_SHOOTRIGHT] := True
	end else begin
		Idx := FingerPosToMovementButtonIdx(FingerX, FingerY);
		If (Idx >= 0) then begin
			MovementButton[Idx].Touched := True;
			MovementButton[Idx].Finger := Ev^.TFinger.FingerID;
			PressMovementKeys();
		end
	end
End;

Procedure SetPosition(NewDPadPos, NewShootBtnsPos: PSDL_Rect);
Var
	Idx: uInt;
	BtnW, BtnH: uInt;
Begin
	If (NewDPadPos <> NIL) then begin
		If (NewDPadPos^.W <= NewDPadPos^.H) then
			DPadSize := NewDPadPos^.W div 2
		else
			DPadSize := NewDPadPos^.H div 2;
		DPadX := NewDPadPos^.X + (NewDPadPos^.W) div 2;
		DPadY := NewDPadPos^.Y + (NewDPadPos^.H) div 2;

		For Idx := 0 to 7 do MovementButton[Idx].Touched := False;

		// Mark virtual movement keys as not being pressed
		Key[KEY_UP] := False;
		Key[KEY_RIGHT] := False;
		Key[KEY_DOWN] := False;
		Key[KEY_LEFT] := False;
	end;
	If (NewShootBtnsPos <> NIL) then begin
		BtnW := NewShootBtnsPos^.W;
		BtnH := BtnW;

		ShootLeftDst.X := NewShootBtnsPos^.X;
		ShootLeftDst.Y := NewShootBtnsPos^.Y;
		ShootLeftDst.W := BtnW;
		ShootLeftDst.H := BtnH;
		ShootLeftButton.Touched := False;

		ShootRightDst.X := NewShootBtnsPos^.X;
		ShootRightDst.Y := NewShootBtnsPos^.Y + NewShootBtnsPos^.H - BtnH;
		ShootRightDst.W := BtnW;
		ShootRightDst.H := BtnH;
		ShootRightButton.Touched := False;

		// Mark virtual "shoot" keys as not being pressed
		Key[KEY_SHOOTLEFT] := False;
		Key[KEY_SHOOTRIGHT] := False;
	end
End;

End.
