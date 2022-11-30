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
Procedure SetVisibility(NewVisible: Boolean);


Implementation

Uses
	Math,
	Assets, MathUtils, Rendering, Shared;

Type
	UnfingerResult = (
		UF_NONE,
		UF_MOVEMENT,
		UF_SHOOT
	);

	ButtonProps = record
		Position: TSDL_Rect;
		Touched: Boolean;
		Finger: TSDL_FingerID
	end;

	MovementWheelProps = record
		X, Y: sInt;
		DeadZoneSize, TouchSize, TouchExtraSize: uInt;
	end;

Var
	Visible: Boolean;

	// Note: the "position" field in these records is used purely for rendering.
	MovementButton: Array[0..7] of ButtonProps;
	ShootLeftButton, ShootRightButton: ButtonProps;

	MovementWheel: MovementWheelProps;
	ShootLeftTouchArea, ShootLeftExtraTouchArea: TSDL_Rect;
	ShootRightTouchArea, ShootRightExtraTouchArea: TSDL_Rect;

{$IFDEF LD25_DEBUG}
Const
	OUTLINE_STEPS = 5;
	OUTLINE_POINTS = (OUTLINE_STEPS * 2) + 1;

Type
	MovementButtonOutlineData = Array[0..(OUTLINE_POINTS-1)] of TSDL_Point;
	MovementButtonOutlinePtr = ^MovementButtonOutlineData;

Var
	MovBtnOutline, MovBtnExtraOutline: Array[0..7] of MovementButtonOutlineData;
{$ENDIF}

Function BoolToInt(Value: Boolean): uInt; Inline;
Begin
	If (Value) then
		Result := 1
	else
		Result := 0
End;

{$IFDEF LD25_DEBUG}
Procedure DrawDebug(); Inline;
Var
	Idx: uInt;
	WheelOutline: MovementButtonOutlinePtr;
	LeftRect, RightRect: PSDL_Rect;
Begin
	WheelOutline := MovBtnOutline;
	For Idx := 0 to 7 do begin
		If MovementButton[Idx].Touched then begin
			WheelOutline := MovBtnExtraOutline;
			Break
		end
	end;

	// Draw un-touched movement buttons in red.
	SDL_SetRenderDrawColor(Renderer, 255, 0, 0, 255);
	For Idx := 0 to 7 do
		If Not MovementButton[Idx].Touched then
			SDL_RenderDrawLines(Renderer, WheelOutline[Idx], OUTLINE_POINTS);

	// Draw currently touched buttons in green.
	// This is done in two separate steps so the green pixels overwrite red ones.
	SDL_SetRenderDrawColor(Renderer, 0, 255, 0, 255);
	For Idx := 0 to 7 do
		If MovementButton[Idx].Touched then
			SDL_RenderDrawLines(Renderer, WheelOutline[Idx], OUTLINE_POINTS);

	If (ShootLeftButton.Touched) or (ShootRightButton.Touched) then begin
		LeftRect := @ShootLeftExtraTouchArea;
		RightRect := @ShootRightExtraTouchArea
	end else begin
		LeftRect := @ShootLeftTouchArea;
		RightRect := @ShootRightTouchArea
	end;

	If ShootLeftButton.Touched then
		SDL_SetRenderDrawColor(Renderer, 0, 255, 0, 255)
	else
		SDL_SetRenderDrawColor(Renderer, 255, 0, 0, 255);
	SDL_RenderDrawRect(Renderer, LeftRect);

	If ShootRightButton.Touched then
		SDL_SetRenderDrawColor(Renderer, 0, 255, 0, 255)
	else
		SDL_SetRenderDrawColor(Renderer, 255, 0, 0, 255);
	SDL_RenderDrawRect(Renderer, RightRect);
End;
{$ENDIF}

Procedure DrawGfx(); Inline;
Const
	MOVEMENT_BUTTON_SIZE = 60;
	SHOOT_BUTTON_SIZE = 32;
Var
	Idx: uInt;
	Src: TSDL_Rect;
Begin
	Src.W := MOVEMENT_BUTTON_SIZE;
	Src.H := MOVEMENT_BUTTON_SIZE;
	For Idx := 0 to 7 do begin
		Src.X := BoolToInt(MovementButton[Idx].Touched) * MOVEMENT_BUTTON_SIZE;
		Src.Y := (Idx mod 2) * MOVEMENT_BUTTON_SIZE;
		SDL_RenderCopyEx(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @MovementButton[Idx].Position, (Idx div 2) * 90.0, NIL, SDL_FLIP_NONE)
	end;

	Src.Y := MOVEMENT_BUTTON_SIZE * 2;
	Src.W := SHOOT_BUTTON_SIZE;
	Src.H := SHOOT_BUTTON_SIZE;

	Src.X := BoolToInt(ShootLeftButton.Touched) * MOVEMENT_BUTTON_SIZE;
	SDL_RenderCopy(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @ShootLeftButton.Position);

	Src.X := BoolToInt(ShootRightButton.Touched) * MOVEMENT_BUTTON_SIZE;
	SDL_RenderCopyEx(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @ShootRightButton.Position, 0, NIL, SDL_FLIP_HORIZONTAL)
End;

Procedure Draw();
Begin
	If Visible then DrawGfx();
	{$IFDEF LD25_DEBUG} DrawDebug(); {$ENDIF}
End;

Procedure PressMovementKeys();
Begin
	Key[KEY_UP] := MovementButton[0].Touched or MovementButton[1].Touched or MovementButton[7].Touched;
	Key[KEY_RIGHT] := MovementButton[1].Touched or MovementButton[2].Touched or MovementButton[3].Touched;
	Key[KEY_DOWN] := MovementButton[3].Touched or MovementButton[4].Touched or MovementButton[5].Touched;
	Key[KEY_LEFT] := MovementButton[5].Touched or MovementButton[6].Touched or MovementButton[7].Touched
End;

Function UnfingerButtons(Finger: TSDL_FingerID): UnfingerResult;
Var
	Idx: uInt;
Begin
	If (ShootLeftButton.Touched) and (ShootLeftButton.Finger = Finger) then begin
		ShootLeftButton.Touched := False;
		Key[KEY_SHOOTLEFT] := False;
		Exit(UF_SHOOT)
	end;
	If (ShootRightButton.Touched) and (ShootRightButton.Finger = Finger) then begin
		ShootRightButton.Touched := False;
		Key[KEY_SHOOTRIGHT] := False;
		Exit(UF_SHOOT)
	end;
	For Idx := 0 to 7 do begin
		If (MovementButton[Idx].Touched) and (MovementButton[Idx].Finger = Finger) then begin
			MovementButton[Idx].Touched := False;
			PressMovementKeys();
			Exit(UF_MOVEMENT)
		end
	end;
	Result := UF_NONE
End;

Function FingerInRect(Const FingerX, FingerY: sInt; Const Rect: PSDL_Rect): Boolean;
Begin
	Result := Overlap(Rect^.X, Rect^.Y, Rect^.W, Rect^.H, FingerX, FingerY, 1, 1)
End;

Function FingerPosToMovementButtonIdx(Const FingerX, FingerY: sInt; MaxDist: Double): sInt;
Var
	DiffX, DiffY: sInt;
	Dist, Angle: Double;
Begin
	DiffX := (FingerX - MovementWheel.X);
	DiffY := (FingerY - MovementWheel.Y);
	If (DiffX = 0) then begin
		If (DiffY > +MovementWheel.DeadZoneSize) and (DiffY <= +MaxDist) then Exit(4);
		If (DiffY < -MovementWheel.DeadZoneSize) and (DiffY >= -MaxDist) then Exit(0);
		Exit(-1)
	end;

	Dist := Math.Hypot(DiffX, DiffY);
	If (Dist < MovementWheel.DeadZoneSize) or (Dist > MaxDist) then Exit(-1);

	Angle := Math.RadToDeg(ArcTan2(DiffY / Dist, DiffX / Dist));
	Result := (Trunc(Angle + (360 * 10.5 / 8)) div 45) mod 8
End;

Procedure HandleEvent(ev: PSDL_Event);
Var
	Idx: sInt;
	FingerX, FingerY: sInt;
	UFResult: UnfingerResult;

	MovementWheelSize: sInt;
	ShootLeftRect, ShootRightRect: PSDL_Rect;
Begin
	If (Ev^.Type_ = SDL_FingerUp) then begin
		UnfingerButtons(Ev^.TFinger.FingerID);
		Exit()
	end;

	FingerX := Trunc(Ev^.TFinger.X * Wnd_W);
	FingerY := Trunc(Ev^.TFinger.Y * Wnd_H);

	MovementWheelSize := MovementWheel.TouchSize;
	ShootLeftRect := @ShootLeftTouchArea;
	ShootRightRect := @ShootRightTouchArea;

	If (Ev^.Type_ = SDL_FingerMotion) then begin
		(*
		 * Perform the "unfinger" logic, since a finger could have been
		 * touching a button and now moved to a different button (or none).
		 *)
		UFResult := UnfingerButtons(Ev^.TFinger.FingerID);

		(*
		 * Touch controls aren't very comfortable to use, so let's be
		 * extra generous to the player in regards of fingers slipping about.
		 * - If this finger was touching a "shoot" button,
		 *   use touch areas larger than the displayed buttons.
		 * - If this finger was touching the movement wheel,
		 *   use a larger wheel than what's actually shown on the screen.
		 *)
		If (UFResult = UF_SHOOT) then begin
			ShootLeftRect := @ShootLeftExtraTouchArea;
			ShootRightRect := @ShootRightExtraTouchArea
		end else
		If (UFResult = UF_MOVEMENT) then begin
			MovementWheelSize := MovementWheel.TouchExtraSize
		end
	end else begin
		UFResult := UF_NONE
	end;

	(*
	 * If this finger was touching the movement wheel, do not perform
	 * any checks for the "shoot" buttons, effectively "locking" it
	 * to the movement wheel until it stops touching the screen.
	 *)
	If (UFResult <> UF_MOVEMENT) then begin
		If FingerInRect(FingerX, FingerY, ShootLeftRect) then begin
			ShootLeftButton.Touched := True;
			ShootLeftButton.Finger := Ev^.TFinger.FingerID;
			Key[KEY_SHOOTLEFT] := True;
			Exit()
		end;
		If FingerInRect(FingerX, FingerY, ShootRightRect) then begin
			ShootRightButton.Touched := True;
			ShootRightButton.Finger := Ev^.TFinger.FingerID;
			Key[KEY_SHOOTRIGHT] := True;
			Exit()
		end
	end;

	(*
	 * And vice versa - do not allow the player to move the finger
	 * from the "shoot" buttons to the movement wheel.
	 *)
	If (UFResult <> UF_SHOOT) then begin
		Idx := FingerPosToMovementButtonIdx(FingerX, FingerY, MovementWheelSize);
		If (Idx >= 0) then begin
			MovementButton[Idx].Touched := True;
			MovementButton[Idx].Finger := Ev^.TFinger.FingerID;
			PressMovementKeys();
			Exit()
		end
	end
End;

{$IFDEF LD25_DEBUG}
Function ProjectPoint(OriginX, OriginY: sInt; Distance: uInt; Angle: Double): TSDL_Point;
Begin
	Result.X := Trunc(OriginX + 0.5 + (Cos(Angle) * Distance));
	Result.Y := Trunc(OriginY + 0.5 + (Sin(Angle) * Distance))
End;
{$ENDIF}

Function EnlargeRect(Const Source: TSDL_Rect; Const EnlargeX, EnlargeY: uInt): TSDL_Rect;
Begin
	Result.X := Source.X - EnlargeX;
	Result.Y := Source.Y - EnlargeY;
	Result.W := Source.W + (2 * EnlargeX);
	Result.H := Source.H + (2 * EnlargeY)
End;

Procedure SetPosition(NewDPadPos, NewShootBtnsPos: PSDL_Rect);
Const
	(*
	 * The movement wheel has a dual nature: it is rendered as an octagon,
	 * but treated as a circle for touch event purposes.
	 *
	 * When using the bounding box's width/height as the circle radius,
	 * the circle touches the octagon only at the center of each piece;
	 * the octagon's vertices are actually outside the circle!
	 *
	 * Multiplying the radius by this factor makes it so it's the vertices
	 * that touch the circle, instead. This, in turn, means that the touch
	 * area is actually slightly larger than what's visible.
	 *)
	HEXAGON_TO_CIRCLE_RATIO = 1.0 / Sin(Pi * 3 / 8);
Var
	Idx: uInt;
	BtnW, BtnH: uInt;
	WheelRenderSize: uInt;
	BtnExtraSize: uInt;

	{$IFDEF LD25_DEBUG}
	pt: uInt;
	Angle: Double;
	{$ENDIF}
Begin
	If (NewDPadPos <> NIL) then begin
		If (NewDPadPos^.W <= NewDPadPos^.H) then
			WheelRenderSize := NewDPadPos^.W div 2
		else
			WheelRenderSize := NewDPadPos^.H div 2;

		MovementWheel.TouchSize := Trunc(WheelRenderSize * HEXAGON_TO_CIRCLE_RATIO);
		MovementWheel.TouchExtraSize := (MovementWheel.TouchSize * 5) div 4; // +25%
		MovementWheel.DeadZoneSize := MovementWheel.TouchSize div 5; // 20%

		MovementWheel.X := NewDPadPos^.X + (NewDPadPos^.W) div 2;
		MovementWheel.Y := NewDPadPos^.Y + (NewDPadPos^.H) div 2;

		For Idx := 0 to 7 do begin
			With MovementButton[Idx] do begin
				Position.X := MovementWheel.X;
				If (Idx = 0) or (Idx = 4) then
					Position.X -= (WheelRenderSize div 2)
				else If (Idx > 4) then
					Position.X -= WheelRenderSize;

				Position.Y := MovementWheel.Y;
				If (Idx = 2) or (Idx = 6) then
					Position.Y -= (WheelRenderSize div 2)
				else If (Idx < 2) or (Idx = 7) then
					Position.Y -= WheelRenderSize;

				Position.W := WheelRenderSize;
				Position.H := WheelRenderSize;
				MovementButton[Idx].Touched := False
			end;

			{$IFDEF LD25_DEBUG}
			For pt := 0 to (OUTLINE_STEPS-1) do begin
				Angle := 0 - (Pi / 2) - (Pi / 8) + (Pi * Idx / 4) + (Pi / 4 * pt / (OUTLINE_STEPS-1));
				MovBtnOutline[Idx][1+pt] := ProjectPoint(MovementWheel.X, MovementWheel.Y, MovementWheel.TouchSize, Angle);
				MovBtnExtraOutline[Idx][1+pt] := ProjectPoint(MovementWheel.X, MovementWheel.Y, MovementWheel.TouchExtraSize, Angle);

				MovBtnOutline[Idx][OUTLINE_POINTS-1-pt] := ProjectPoint(MovementWheel.X, MovementWheel.Y, MovementWheel.DeadZoneSize, Angle);
				MovBtnExtraOutline[Idx][OUTLINE_POINTS-1-pt] := MovBtnOutline[Idx][OUTLINE_POINTS-1-pt];
			end;
			MovBtnOutline[Idx][0] := MovBtnOutline[Idx][OUTLINE_POINTS-1];
			MovBtnExtraOutline[Idx][0] := MovBtnExtraOutline[Idx][OUTLINE_POINTS-1];
			{$ENDIF}
		end;

		// Mark virtual movement keys as not being pressed
		Key[KEY_UP] := False;
		Key[KEY_RIGHT] := False;
		Key[KEY_DOWN] := False;
		Key[KEY_LEFT] := False;
	end;
	If (NewShootBtnsPos <> NIL) then begin
		BtnW := NewShootBtnsPos^.W;
		BtnH := BtnW;

		With ShootLeftButton do begin
			Position.X := NewShootBtnsPos^.X;
			Position.Y := NewShootBtnsPos^.Y;
			Position.W := BtnW;
			Position.H := BtnH;
			Touched := False
		end;

		With ShootRightButton do begin
			Position.X := NewShootBtnsPos^.X;
			Position.Y := NewShootBtnsPos^.Y + NewShootBtnsPos^.H - BtnH;
			Position.W := BtnW;
			Position.H := BtnH;
			Touched := False
		end;

		BtnExtraSize := BtnW div 4;
		ShootLeftTouchArea := EnlargeRect(ShootLeftButton.Position, BtnExtraSize, BtnExtraSize);
		ShootRightTouchArea := EnlargeRect(ShootRightButton.Position, BtnExtraSize, BtnExtraSize);

		BtnExtraSize := (NewShootBtnsPos^.H - (BtnH * 2)) div 2;
		ShootLeftExtraTouchArea := EnlargeRect(ShootLeftButton.Position, BtnExtraSize, BtnExtraSize);
		ShootRightExtraTouchArea := EnlargeRect(ShootRightButton.Position, BtnExtraSize, BtnExtraSize);

		// Mark virtual "shoot" keys as not being pressed
		Key[KEY_SHOOTLEFT] := False;
		Key[KEY_SHOOTRIGHT] := False;
	end
End;

Procedure SetVisibility(NewVisible: Boolean);
Var
	Idx: uInt;
Begin
	Visible := NewVisible;
	If Not Visible then begin
		ShootLeftButton.Touched := False;
		ShootRightButton.Touched := False;
		For Idx := 0 to 7 do MovementButton[Idx].Touched := False
	end
End;

End.
