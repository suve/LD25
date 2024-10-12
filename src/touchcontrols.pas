(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2022-2024 suve (a.k.a. Artur Frenszek Iwicki)
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

Type
	TouchControlVisibility = (
		// Completely hidden
		TCV_NONE,
	 	// Show only the "back" button
		TCV_ONLY_BACK,
		// Back, next slide
		TCV_SLIDE_RIGHT,
		// Back, next slide, previous slide
		TCV_SLIDE_BOTH, 
		// Back + in-game controls (movement wheel, shoot left/right)
		TCV_GAME
	);

Procedure Draw();
Procedure HandleEvent(ev: PSDL_Event);

Procedure SetMovementWheelPosition(NewPos: TSDL_Rect);
Procedure SetShootButtonsPosition(NewPos: TSDL_Rect);
Procedure SetGoBackButtonPosition(NewPos: TSDL_Rect);
Procedure SetSlideButtonsPosition(LeftPos, RightPos: TSDL_Rect);

Procedure SetVisibility(NewValue: TouchControlVisibility);


Implementation

Uses
	Math,
	Assets, MathUtils, Rendering, Shared;

Type
	UnfingerResult = (
		UF_NONE,
		UF_MOVEMENT,
		UF_SHOOT,
		UF_SLIDE_LEFT,
		UF_SLIDE_RIGHT,
		UF_BACK
	);

	PButtonProps = ^TButtonProps;
	TButtonProps = record
		Position: TSDL_Rect;
		Touched: Boolean;
		Finger: TSDL_FingerID
	end;

	MovementWheelProps = record
		X, Y: sInt;
		DeadZoneSize, TouchSize, TouchExtraSize: uInt;
	end;

	BackButtonProps = record
		X, Y, Size: uInt;
		Flip: uInt;
	end;

Var
	Visibility: TouchControlVisibility;

	// Note: the "position" field in these records is used purely for rendering.
	MovementButton: Array[0..7] of TButtonProps;
	ShootLeftButton, ShootRightButton: TButtonProps;
	SlideLeftButton, SlideRightButton: TButtonProps;
	GoBackButton: TButtonProps;

	MovementWheel: MovementWheelProps;
	ShootLeftTouchArea, ShootLeftExtraTouchArea: TSDL_Rect;
	ShootRightTouchArea, ShootRightExtraTouchArea: TSDL_Rect;
	SlideLeftTouchArea, SlideRightTouchArea: TSDL_Rect;
	GoBackTriangle: BackButtonProps;

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

Function BackButtonIsVisible(): Boolean; Inline;
Begin
	Result := Visibility > TCV_NONE
End;

Function SlideLeftButtonIsVisible(): Boolean; Inline;
Begin
	Result := Visibility = TCV_SLIDE_BOTH
end;

Function SlideRightButtonIsVisible(): Boolean; Inline;
Begin
	Result := (Visibility = TCV_SLIDE_RIGHT) or (Visibility = TCV_SLIDE_BOTH)
end;

Function GameButtonsAreVisible(): Boolean; Inline;
Begin
	Result := Visibility = TCV_GAME
End;

{$IFDEF LD25_DEBUG}
Procedure UseYellowOutline(); Inline;
Begin
	SDL_SetRenderDrawColor(Renderer, 127, 127, 63, 255)
End;

Procedure UseRedOutline(); Inline;
Begin
	SDL_SetRenderDrawColor(Renderer, 255, 0, 0, 255)
End;

Procedure UseGreenOutline(); Inline;
Begin
	SDL_SetRenderDrawColor(Renderer, 0, 255, 0, 255)
End;

(*
 * I'm rather unhappy with the fact that this function accepts two boolean
 * parameters (4 possible inputs) when it produces 3 possible outputs.
 * Seeing how it's debug code, I'm willing to let it slide.
 *)
Procedure SetOutlineColour(Visible, Touched: Boolean); Inline;
Begin
	If Visible then begin
		If Touched then
			UseGreenOutline()
		else
			UseRedOutline()
	end else
		UseYellowOutline()
end;

Procedure DebugGameButtonsVisible();
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

	// Draw un-touched movement buttons in red, and touched buttons in green.
	// This is done in two separate steps so the green pixels overwrite red ones.
	UseRedOutline();
	For Idx := 0 to 7 do
		If Not MovementButton[Idx].Touched then
			SDL_RenderDrawLines(Renderer, WheelOutline[Idx], OUTLINE_POINTS);

	UseGreenOutline();
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

	SetOutlineColour(True, ShootLeftButton.Touched);
	SDL_RenderDrawRect(Renderer, LeftRect);

	SetOutlineColour(True, ShootRightButton.Touched);
	SDL_RenderDrawRect(Renderer, RightRect)
End;

Procedure DebugGameButtonsHidden();
Var
	Idx: uInt;
	WheelOutline: MovementButtonOutlinePtr;
	LeftRect, RightRect: PSDL_Rect;
Begin
	UseYellowOutline();
	For Idx := 0 to 7 do
		SDL_RenderDrawLines(Renderer, MovBtnOutline[Idx], OUTLINE_POINTS);

	SDL_RenderDrawRect(Renderer, @ShootLeftTouchArea);
	SDL_RenderDrawRect(Renderer, @ShootRightTouchArea)
End;

Procedure DebugSlideButtons();
Begin
	SetOutlineColour(SlideRightButtonIsVisible(), SlideRightButton.Touched);
	SDL_RenderDrawRect(Renderer, @SlideRightTouchArea);

	SetOutlineColour(SlideLeftButtonIsVisible(), SlideLeftButton.Touched);
	SDL_RenderDrawRect(Renderer, @SlideLeftTouchArea);
End;

Procedure DebugGoBackTriangle();
Var
	Idx: uInt;
	TriVerts: Array[0..3] of TSDL_Point;
Begin
	SetOutlineColour(BackButtonIsVisible(), GoBackButton.Touched);

	For Idx := 0 to 3 do begin
		TriVerts[Idx].X := GoBackTriangle.X;
		TriVerts[Idx].Y := GoBackTriangle.Y
	end;
	If ((GoBackTriangle.Flip and SDL_FLIP_HORIZONTAL) = 0) then
		TriVerts[1].X += GoBackTriangle.Size
	else
		TriVerts[1].X -= GoBackTriangle.Size;
	If ((GoBackTriangle.Flip and SDL_FLIP_VERTICAL) = 0) then
		TriVerts[2].Y += GoBackTriangle.Size
	else
		TriVerts[2].Y -= GoBackTriangle.Size;
	SDL_RenderDrawLines(Renderer, @TriVerts[0], 4)
End;
{$ENDIF}

Const
	GFX_BACK_BUTTON_SIZE = 40;
	GFX_MOVEMENT_BUTTON_SIZE = 60;
	GFX_SHOOT_BUTTON_SIZE = 32;
	GFX_SLIDE_BUTTON_SIZE = 40;
	GFX_TOUCHED_OFFSET = 60;

Procedure DrawGameButtons(); Inline;
Var
	Idx: uInt;
	Src: TSDL_Rect;
Begin
	// Movement wheel
	Src.W := GFX_MOVEMENT_BUTTON_SIZE;
	Src.H := GFX_MOVEMENT_BUTTON_SIZE;
	For Idx := 0 to 7 do begin
		Src.X := BoolToInt(MovementButton[Idx].Touched) * GFX_TOUCHED_OFFSET;
		Src.Y := (Idx mod 2) * GFX_MOVEMENT_BUTTON_SIZE;
		SDL_RenderCopyEx(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @MovementButton[Idx].Position, (Idx div 2) * 90.0, NIL, SDL_FLIP_NONE)
	end;

	// "Shoot" buttons
	Src.Y := GFX_MOVEMENT_BUTTON_SIZE * 2;
	Src.W := GFX_SHOOT_BUTTON_SIZE;
	Src.H := GFX_SHOOT_BUTTON_SIZE;

	Src.X := BoolToInt(ShootLeftButton.Touched) * GFX_TOUCHED_OFFSET;
	SDL_RenderCopy(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @ShootLeftButton.Position);

	Src.X := BoolToInt(ShootRightButton.Touched) * GFX_TOUCHED_OFFSET;
	SDL_RenderCopyEx(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @ShootRightButton.Position, 0, NIL, SDL_FLIP_HORIZONTAL)
End;

Procedure DrawBackButton(); Inline;
Var
	Src: TSDL_Rect;
Begin
	Src.X := BoolToInt(GoBackButton.Touched) * GFX_TOUCHED_OFFSET;
	Src.Y := (GFX_MOVEMENT_BUTTON_SIZE * 2) + GFX_SHOOT_BUTTON_SIZE;
	Src.W := GFX_BACK_BUTTON_SIZE;
	Src.H := GFX_BACK_BUTTON_SIZE;
	SDL_RenderCopyEx(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @GoBackButton.Position, 0, NIL, GoBackTriangle.Flip)
End;

Procedure DrawSlideButton(Which: PButtonProps; Flip: Integer); Inline;
Var
	Src: TSDL_Rect;
Begin
	Src.X := BoolToInt(Which^.Touched) * GFX_TOUCHED_OFFSET;
	Src.Y := (GFX_MOVEMENT_BUTTON_SIZE * 2) + GFX_SHOOT_BUTTON_SIZE + GFX_BACK_BUTTON_SIZE;
	Src.W := GFX_SLIDE_BUTTON_SIZE;
	Src.H := GFX_SLIDE_BUTTON_SIZE;
	SDL_RenderCopyEx(Renderer, Assets.TouchControlsGfx^.Tex, @Src, @Which^.Position, 0, NIL, Flip)
End;

Procedure Draw();
Begin
	// This could be replaced with XxxIsVisible() functions,
	// but I am keeping it like this as a micro-optimisation.
	If Visibility >= TCV_ONLY_BACK then begin
		If Visibility = TCV_GAME then
			DrawGameButtons()
		else
		If Visibility >= TCV_SLIDE_RIGHT then begin
			If(Visibility = TCV_SLIDE_BOTH) then DrawSlideButton(@SlideLeftButton, 0);
			DrawSlideButton(@SlideRightButton, SDL_FLIP_HORIZONTAL)
		end;
		DrawBackButton()
	end;

	{$IFDEF LD25_DEBUG}
		If GameButtonsAreVisible() then
			DebugGameButtonsVisible()
		else
			DebugGameButtonsHidden();
		DebugSlideButtons();
		DebugGoBackTriangle()
	{$ENDIF}
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

	If (SlideLeftButton.Touched) and (SlideLeftButton.Finger = Finger) then begin
		SlideLeftButton.Touched := False;
		Exit(UF_SLIDE_LEFT)
	end;
	If (SlideRightButton.Touched) and (SlideRightButton.Finger = Finger) then begin
		SlideRightButton.Touched := False;
		Exit(UF_SLIDE_RIGHT)
	end;

	If (GoBackButton.Touched) and (GoBackButton.Finger = Finger) then begin
		GoBackButton.Touched := False;
		Exit(UF_BACK)
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

Function FingerInGoBackTriangle(Const FingerX, FingerY: sInt): Boolean;
Var
	DiffX, DiffY: sInt;
Begin
	If ((GoBackTriangle.Flip and SDL_FLIP_HORIZONTAL) = 0) then
		DiffX := FingerX - GoBackTriangle.X
	else
		DiffX := GoBackTriangle.X - FingerX;
	If (DiffX < 0) then Exit(False);

	If ((GoBackTriangle.Flip and SDL_FLIP_VERTICAL) = 0) then
		DiffY := FingerY - GoBackTriangle.Y
	else
		DiffY := GoBackTriangle.Y - FingerY;
	If (DiffY < 0) then Exit(False);

	Result := (DiffX + DiffY) <= GoBackTriangle.Size
End;

Procedure FakeKeypress(TrigScan: TSDL_Scancode; TrigKey: TSDL_KeyCode);
Const
	PROTOTYPE: TSDL_Event = (
		Key: (
			Type_: SDL_KEYDOWN;
			Timestamp: 0;
			WindowID: 0;
			State: 0;
			Repeat_: SDL_PRESSED;
			padding2: 0;
			padding3: 0;
			Keysym: (
				Scancode: SDL_SCANCODE_UNKNOWN;
				Sym: SDLK_UNKNOWN;
				Mod_: KMOD_NONE;
				Unicode: 0;
			)
		)
	);
Var
	Event: TSDL_Event;
Begin
	Event := PROTOTYPE;

	Event.Key.Keysym.Scancode := TrigScan;
	Event.Key.Keysym.Sym := TrigKey;

	Event.Key.Timestamp := SDL_GetTicks();
	Event.Key.WindowID := SDL_GetWindowID(Window);

	SDL_PushEvent(@Event)
End;

Procedure HandleEvent_InGame(
	ev: PSDL_Event;
	FingerX, FingerY: sInt;
	UFResult: UnfingerResult;
	ShootLeftRect, ShootRightRect: PSDL_Rect;
	MovementWheelSize: sInt
); Inline;
Var
	Idx: sInt;
Begin
	(*
	 * Lock the finger to the shoot buttons.
	 * Note that both "shoot" buttons share the same single lock;
	 * the player is allowed to move their finger from one button
	 * to the other and back.
	 *)
	If (UFResult = UF_NONE) or (UFResult = UF_SHOOT) then begin
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

	// Same here - lock the finger to the movement wheel.
	If (UFResult = UF_NONE) or (UFResult = UF_MOVEMENT) then begin
		Idx := FingerPosToMovementButtonIdx(FingerX, FingerY, MovementWheelSize);
		If (Idx >= 0) then begin
			MovementButton[Idx].Touched := True;
			MovementButton[Idx].Finger := Ev^.TFinger.FingerID;
			PressMovementKeys();
			Exit()
		end
	end;
End;

Procedure HandleEvent_Slides(
	ev: PSDL_Event;
	FingerX, FingerY: sInt;
	UFResult: UnfingerResult
); Inline;
Begin
	If Not SlideRightButtonIsVisible() then Exit();
	If (UFResult = UF_NONE) or (UFResult = UF_SLIDE_RIGHT) then begin
		If FingerInRect(FingerX, FingerY, @SlideRightTouchArea) then begin
			SlideRightButton.Touched := True;
			SlideRightButton.Finger := Ev^.TFinger.FingerID;
			Exit()
		end
	end;

	If Not SlideLeftButtonIsVisible() then Exit();
	If (UFResult = UF_NONE) or (UFResult = UF_SLIDE_LEFT) then begin
		If FingerInRect(FingerX, FingerY, @SlideLeftTouchArea) then begin
			SlideLeftButton.Touched := True;
			SlideLeftButton.Finger := Ev^.TFinger.FingerID;
			Exit()
		end
	end
End;


Procedure HandleEvent(ev: PSDL_Event);
Var
	FingerX, FingerY: sInt;
	UFResult: UnfingerResult;

	MovementWheelSize: sInt;
	ShootLeftRect, ShootRightRect: PSDL_Rect;
Begin
	// If no touch controls are visible, we can just disregard any events.
	If (Visibility = TCV_NONE) then Exit();

	If (Ev^.Type_ = SDL_FingerUp) then begin
		(*
		 * Contrary to in-game controls, the "go back" and slide buttons
		 * are activated when released, not when pressed.
		 *)
		UFResult := UnfingerButtons(Ev^.TFinger.FingerID);
		Case UFResult of
			UF_BACK: FakeKeypress(SDL_SCANCODE_AC_BACK, SDLK_AC_BACK);
			UF_SLIDE_LEFT: FakeKeypress(SDL_SCANCODE_LEFT, SDLK_LEFT);
			UF_SLIDE_RIGHT: FakeKeypress(SDL_SCANCODE_RIGHT, SDLK_RIGHT);
		end;

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
	 * Perform checks for the "go back" button ONLY if this finger was already
	 * touching said button before (or it didn't touch anything at all). This
	 * will "lock" the finger to the "go back" button, preventing it from
	 * activating the movement wheel or one of the "shoot" buttons until
	 * the player lifts the finger up and stops touching the screen.
	 *)
	If (UFResult = UF_NONE) or (UFResult = UF_BACK) then begin
		If FingerInGoBackTriangle(FingerX, FingerY) then begin
			GoBackButton.Touched := True;
			GoBackButton.Finger := Ev^.TFinger.FingerID;
			Exit()
		end
	end;

	If (Visibility = TCV_GAME) then
		HandleEvent_InGame(ev, FingerX, FingerY, UFResult, ShootLeftRect, ShootRightRect, MovementWheelSize)
	else
		HandleEvent_Slides(ev, FingerX, FingerY, UFResult)
end;

Function EnlargeRect(Const Source: TSDL_Rect; Const EnlargeX, EnlargeY: uInt): TSDL_Rect;
Begin
	Result.X := Source.X - EnlargeX;
	Result.Y := Source.Y - EnlargeY;
	Result.W := Source.W + (2 * EnlargeX);
	Result.H := Source.H + (2 * EnlargeY)
End;

Procedure SetMovementWheelPosition(NewPos: TSDL_Rect);
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
	WheelRenderSize: uInt;

	{$IFDEF LD25_DEBUG}
	pt: uInt;
	Angle: Double;
	{$ENDIF}
Begin
	WheelRenderSize := MinOfTwo(NewPos.W div 2, NewPos.H div 2);

	MovementWheel.TouchSize := Trunc(WheelRenderSize * HEXAGON_TO_CIRCLE_RATIO);
	MovementWheel.TouchExtraSize := (MovementWheel.TouchSize * 5) div 4; // +25%
	MovementWheel.DeadZoneSize := MovementWheel.TouchSize div 5; // 20%

	MovementWheel.X := NewPos.X + (NewPos.W) div 2;
	MovementWheel.Y := NewPos.Y + (NewPos.H) div 2;

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
End;

Procedure SetShootButtonsPosition(NewPos: TSDL_Rect);
Var
	BtnW, BtnH: uInt;
	BtnExtraSize: uInt;
Begin
	If(NewPos.H > NewPos.W) then begin
		BtnW := NewPos.W;
		BtnH := BtnW;
		BtnExtraSize := (NewPos.H - (BtnH * 2)) div 2;
	end else begin
		BtnH := NewPos.H;
		BtnW := BtnH;
		BtnExtraSize := (NewPos.W - (BtnW * 2)) div 2;
	end;

	With ShootLeftButton do begin
		Position.X := NewPos.X;
		Position.Y := NewPos.Y;
		Position.W := BtnW;
		Position.H := BtnH;
		Touched := False
	end;

	With ShootRightButton do begin
		If(NewPos.H > NewPos.W) then begin
			Position.X := NewPos.X;
			Position.Y := NewPos.Y + NewPos.H - BtnH
		end else begin
			Position.X := NewPos.X + NewPos.W - BtnW;
			Position.Y := NewPos.Y
		end;
		Position.W := BtnW;
		Position.H := BtnH;
		Touched := False
	end;

	ShootLeftTouchArea := EnlargeRect(ShootLeftButton.Position, (BtnW div 4), (BtnH div 4));
	ShootRightTouchArea := EnlargeRect(ShootRightButton.Position, (BtnW div 4), (BtnH div 4));

	ShootLeftExtraTouchArea := EnlargeRect(ShootLeftButton.Position, BtnExtraSize, BtnExtraSize);
	ShootRightExtraTouchArea := EnlargeRect(ShootRightButton.Position, BtnExtraSize, BtnExtraSize);

	// Mark virtual "shoot" keys as not being pressed
	Key[KEY_SHOOTLEFT] := False;
	Key[KEY_SHOOTRIGHT] := False;
End;

Procedure SetGoBackButtonPosition(NewPos: TSDL_Rect);
Begin
	GoBackTriangle.X := NewPos.X;
	GoBackTriangle.Y := NewPos.Y;
	GoBackTriangle.Size := MaxOfTwo(NewPos.W, NewPos.H);

	GoBackTriangle.Flip := 0;
	If (GoBackTriangle.X > 0) then begin
		GoBackTriangle.X += NewPos.W - 1;
		GoBackTriangle.Flip := GoBackTriangle.Flip or SDL_FLIP_HORIZONTAL
	end;
	If (GoBackTriangle.Y > 0) then begin
		GoBackTriangle.Y += NewPos.H - 1;
		GoBackTriangle.Flip := GoBackTriangle.Flip or SDL_FLIP_VERTICAL
	end;

	GoBackButton.Position := NewPos;
	GoBackButton.Touched := False
End;

Procedure SetSlideButtonsPosition(LeftPos, RightPos: TSDL_Rect);
Var
	ExtraWidth, ExtraHeight: uInt;
Begin
	SlideLeftButton.Position := LeftPos;
	SlideRightButton.Position := RightPos;

	ExtraWidth := MaxOfTwo(LeftPos.W, RightPos.W) div 4;
	ExtraHeight := MaxOfTwo(LeftPos.H, RightPos.H) div 4;
	SlideLeftTouchArea := EnlargeRect(SlideLeftButton.Position, ExtraWidth, ExtraHeight);
	SlideRightTouchArea := EnlargeRect(SlideRightButton.Position, ExtraWidth, ExtraHeight);

	SlideLeftButton.Touched := False;
	SlideRightButton.Touched := False
End;

Procedure SetVisibility(NewValue: TouchControlVisibility);
Var
	Idx: uInt;
Begin
	Visibility := NewValue;

	If Not BackButtonIsVisible() then GoBackButton.Touched := False;
	If Not SlideLeftButtonIsVisible() then SlideLeftButton.Touched := False;
	If Not SlideRightButtonIsVisible() then SlideRightButton.Touched := False;

	If Not GameButtonsAreVisible() then begin
		ShootLeftButton.Touched := False;
		ShootRightButton.Touched := False;
		For Idx := 0 to 7 do MovementButton[Idx].Touched := False
	end
End;

End.
