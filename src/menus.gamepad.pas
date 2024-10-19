(*
 * colorful - simple 2D sideview shooter
 * Copyright (C) 2024 suve (a.k.a. Artur Frenszek-Iwicki)
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
Unit Menus.Gamepad;

{$INCLUDE defines.inc}

Interface

Procedure ConfigureGamepad();


Implementation

Uses
	SDL2, ctypes,
	Assets, Colours, Controllers, Fonts, Menus, Rendering, Shared, Timekeeping
	{$IFDEF LD25_MOBILE}, TouchControls {$ENDIF};

Type
	THighlightMask = (
		MASK_NONE = -1,
		MASK_THUMBSTICK_HORIZONTAL,
		MASK_THUMBSTICK_VERTICAL,
		MASK_THUMBSTICK_BUTTON,
		MASK_DPAD_HORIZONTAL,
		MASK_DPAD_VERTICAL,
		MASK_SHOULDER,
		MASK_TRIGGER,
		MASK_BUTTON_ABXY,
		MASK_BUTTON_START,
		MASK_BUTTON_GUIDE
	);

Const
	// Specifies the position of each mask inside gfx/gamepad-buttons.png
	HighlightMaskSrc: Array[THighlightMask] of TSDL_Rect = (
		(X:  0; Y:  0; W:  0; H:  0),
		(X:  0; Y:  0; W:  8; H: 15),
		(X:  8; Y:  0; W: 15; H:  8),
		(X: 14; Y: 13; W:  9; H:  9),
		(X: 15; Y:  8; W:  8; H:  5),
		(X: 16; Y: 21; W:  5; H:  8),
		(X:  0; Y: 22; W: 15; H:  4),
		(X:  0; Y: 16; W: 13; H:  6),
		(X:  8; Y:  8; W:  7; H:  7),
		(X:  0; Y: 26; W:  6; H:  3),
		(X:  6; Y: 26; W:  4; H:  3)
	);

Type
	THighlightID = (
		HL_NONE = -1, // Either invalid, or valid without an image
		HL_LEFT_STICK_LEFT,
		HL_LEFT_STICK_RIGHT,
		HL_LEFT_STICK_UP,
		HL_LEFT_STICK_DOWN,
		HL_LEFT_STICK_BUTTON,
		HL_RIGHT_STICK_LEFT,
		HL_RIGHT_STICK_RIGHT,
		HL_RIGHT_STICK_UP,
		HL_RIGHT_STICK_DOWN,
		HL_RIGHT_STICK_BUTTON,
		HL_DPAD_UP,
		HL_DPAD_DOWN,
		HL_DPAD_LEFT,
		HL_DPAD_RIGHT,
		HL_BUTTON_NORTH,
		HL_BUTTON_WEST,
		HL_BUTTON_EAST,
		HL_BUTTON_SOUTH,
		HL_LEFT_SHOULDER,
		HL_LEFT_TRIGGER,
		HL_RIGHT_SHOULDER,
		HL_RIGHT_TRIGGER,
		HL_BUTTON_SELECT,
		HL_BUTTON_START,
		HL_BUTTON_GUIDE
	);

	THighlightProps = record
		// Position of the highlight inside gfx/gamepad.png
		X, Y: cint;

		// MaskID, serves as index into the HighlightMaskSrc array
		Mask: THighlightMask;

		// Whether the gfx needs to be flipped
		Flip: TSDL_RenderFlip;
	end;

Const
	GamepadHighlight: Array[THighlightID] of THighlightProps = (
		// HL_NONE
		(X: 0; Y: 0; Mask: MASK_NONE; Flip: 0),
		// HL_LEFT_STICK_LEFT
		(X: 22; Y: 26; Mask: MASK_THUMBSTICK_HORIZONTAL; Flip: SDL_FLIP_HORIZONTAL),
		// HL_LEFT_STICK_RIGHT
		(X: 29; Y: 26; Mask: MASK_THUMBSTICK_HORIZONTAL; Flip: 0),
		// HL_LEFT_STICK_UP,
		(X: 22; Y: 26; Mask: MASK_THUMBSTICK_VERTICAL; Flip: SDL_FLIP_VERTICAL),
		// HL_LEFT_STICK_DOWN
		(X: 22; Y: 33; Mask: MASK_THUMBSTICK_VERTICAL; Flip: 0),
		// HL_LEFT_STICK_BUTTON
		(X: 25; Y: 29; Mask: MASK_THUMBSTICK_BUTTON; Flip: 0),
		// HL_RIGHT_STICK_LEFT
		(X: 43; Y: 26; Mask: MASK_THUMBSTICK_HORIZONTAL; Flip: SDL_FLIP_HORIZONTAL),
		// HL_RIGHT_STICK_RIGHT
		(X: 50; Y: 26; Mask: MASK_THUMBSTICK_HORIZONTAL; Flip: 0),
		// HL_RIGHT_STICK_UP,
		(X: 43; Y: 26; Mask: MASK_THUMBSTICK_VERTICAL; Flip: SDL_FLIP_VERTICAL),
		// HL_RIGHT_STICK_DOWN
		(X: 43; Y: 33; Mask: MASK_THUMBSTICK_VERTICAL; Flip: 0),
		// HL_RIGHT_STICK_BUTTON
		(X: 46; Y: 29; Mask: MASK_THUMBSTICK_BUTTON; Flip: 0),
		// HL_DPAD_UP
		(X: 14; Y: 14; Mask: MASK_DPAD_VERTICAL; Flip: 0),
		// HL_DPAD_DOWN
		(X: 14; Y: 21; Mask: MASK_DPAD_VERTICAL; Flip: SDL_FLIP_VERTICAL),
		// HL_DPAD_LEFT
		(X:  9; Y: 19; Mask: MASK_DPAD_HORIZONTAL; Flip: 0),
		// HL_DPAD_RIGHT
		(X: 16; Y: 19; Mask: MASK_DPAD_HORIZONTAL; Flip: SDL_FLIP_HORIZONTAL),
		// HL_BUTTON_NORTH
		(X: 60; Y: 12; Mask: MASK_BUTTON_ABXY; Flip: 0),
		// HL_BUTTON_WEST
		(X: 54; Y: 18; Mask: MASK_BUTTON_ABXY; Flip: 0),
		// HL_BUTTON_EAST
		(X: 66; Y: 18; Mask: MASK_BUTTON_ABXY; Flip: 0),
		// HL_BUTTON_SOUTH
		(X: 60; Y: 24; Mask: MASK_BUTTON_ABXY; Flip: 0),
		// HL_LEFT_SHOULDER
		(X:  9; Y:  7; Mask: MASK_SHOULDER; Flip: 0),
		// HL_LEFT_TRIGGER
		(X: 11; Y:  0; Mask: MASK_TRIGGER; Flip: 0),
		// HL_RIGHT_SHOULDER
		(X: 56; Y:  7; Mask: MASK_SHOULDER; Flip: SDL_FLIP_HORIZONTAL),
		// HL_RIGHT_TRIGGER
		(X: 56; Y:  0; Mask: MASK_TRIGGER; Flip: SDL_FLIP_HORIZONTAL),
		// HL_BUTTON_SELECT
		(X: 32; Y: 20; Mask: MASK_BUTTON_START; Flip: 0),
		// HL_BUTTON_START
		(X: 42; Y: 20; Mask: MASK_BUTTON_START; Flip: 0),
		// HL_BUTTON_GUIDE
		(X: 38; Y: 26; Mask: MASK_BUTTON_GUIDE; Flip: 0)
	);

Function GetHighlightIdForBinding(Const Binding: PControllerBinding): THighlightID;
Begin
	Case Binding^.IsValid() of
		CBV_AXIS: Case Binding^.Axis of
			SDL_CONTROLLER_AXIS_LEFTX:
				If(Binding^.Negative) then
					Result := HL_LEFT_STICK_LEFT
				else
					Result := HL_LEFT_STICK_RIGHT;

			SDL_CONTROLLER_AXIS_LEFTY:
				If(Binding^.Negative) then
					Result := HL_LEFT_STICK_UP
				else
					Result := HL_LEFT_STICK_DOWN;

			SDL_CONTROLLER_AXIS_RIGHTX:
				If(Binding^.Negative) then
					Result := HL_RIGHT_STICK_LEFT
				else
					Result := HL_RIGHT_STICK_RIGHT;

			SDL_CONTROLLER_AXIS_RIGHTY:
				If(Binding^.Negative) then
					Result := HL_RIGHT_STICK_UP
				else
					Result := HL_RIGHT_STICK_DOWN;

			SDL_CONTROLLER_AXIS_TRIGGERLEFT:
				Result := HL_LEFT_TRIGGER;

			SDL_CONTROLLER_AXIS_TRIGGERRIGHT:
				Result := HL_RIGHT_TRIGGER;

			otherwise
				Result := HL_NONE
		end;

		CBV_BUTTON: Case Binding^.Button of
			SDL_CONTROLLER_BUTTON_DPAD_UP:
				Result := HL_DPAD_UP;

			SDL_CONTROLLER_BUTTON_DPAD_RIGHT:
				Result := HL_DPAD_RIGHT;

			SDL_CONTROLLER_BUTTON_DPAD_DOWN:
				Result := HL_DPAD_DOWN;

			SDL_CONTROLLER_BUTTON_DPAD_LEFT:
				Result := HL_DPAD_LEFT;

			SDL_CONTROLLER_BUTTON_A:
				Result := HL_BUTTON_SOUTH;

			SDL_CONTROLLER_BUTTON_B:
				Result := HL_BUTTON_EAST;

			SDL_CONTROLLER_BUTTON_X:
				Result := HL_BUTTON_WEST;

			SDL_CONTROLLER_BUTTON_Y:
				Result := HL_BUTTON_NORTH;

			SDL_CONTROLLER_BUTTON_LEFTSTICK:
				Result := HL_LEFT_STICK_BUTTON;

			SDL_CONTROLLER_BUTTON_RIGHTSTICK:
				Result := HL_RIGHT_STICK_BUTTON;

			SDL_CONTROLLER_BUTTON_LEFTSHOULDER:
				Result := HL_LEFT_SHOULDER;

			SDL_CONTROLLER_BUTTON_RIGHTSHOULDER:
				Result := HL_RIGHT_SHOULDER;

			SDL_CONTROLLER_BUTTON_BACK:
				Result := HL_BUTTON_SELECT;

			SDL_CONTROLLER_BUTTON_START:
				Result := HL_BUTTON_START;

			SDL_CONTROLLER_BUTTON_GUIDE:
				Result := HL_BUTTON_GUIDE;

			otherwise
				Result := HL_NONE
		end;

		CBV_INVALID:
			Result := HL_NONE
	end
End;

Procedure RenderHighlight(
	Const ID: THighlightID;
	Const PadRect: PSDL_Rect;
	Const Colour: PSDL_Colour
);
Var
	Src: PSDL_Rect;
	Flip: TSDL_RenderFlip;
	Dst: TSDL_Rect;
Begin
	If(ID = HL_NONE) then Exit;

	Src := @HighlightMaskSrc[GamepadHighlight[ID].Mask];
	Flip := GamepadHighlight[ID].Flip;

	// These should be re-scaled from source gfx size to destination rect size,
	// but both are the same size, so whatever
	Dst.X := PadRect^.X + GamepadHighlight[ID].X;
	Dst.Y := PadRect^.Y + GamepadHighlight[ID].Y;
	Dst.W := Src^.W;
	Dst.H := Src^.H;

	SDL_SetTextureColorMod(GamepadButtonsGfx^.Tex, Colour^.R, Colour^.G, Colour^.B);
	SDL_RenderCopyEx(Renderer, GamepadButtonsGfx^.Tex, Src, @Dst, 0.0, NIL, Flip)
End;

Procedure ConfigureGamepad();
Const
	DEAD_ZONE_MIN = 0;
	DEAD_ZONE_MAX = 75;
	DEAD_ZONE_STEP = 5;

	MAX_NAMES = 4;
Var
	ControllerCount: sInt;
	ControllerNames: Array[0..(MAX_NAMES - 1)] of AnsiString;

	AssignToBind: PControllerBinding;
	AssignTextColour: PSDL_Colour;
	DeadZoneStr, LeftStr, RightStr: AnsiString;
	LeftHighlight, RightHighlight: THighlightID;

	Procedure ChangeDeadZone();
	Var
		Percentage: uInt;
	Begin
		Percentage := Trunc(DeadZone.Percentage * 100);
		Percentage := Percentage - (Percentage mod DEAD_ZONE_STEP);
		Percentage := Percentage + DEAD_ZONE_STEP;
		If(Percentage > DEAD_ZONE_MAX) then Percentage := DEAD_ZONE_MIN;

		Controllers.DeadZone.Percentage := Percentage / 100;
		WriteStr(DeadZoneStr, Percentage, '%')
	End;

	Procedure ToggleRumble();
	Begin
		Controllers.RumbleEnabled := Not Controllers.RumbleEnabled;
		Controllers.RumbleLastUsed($3FFF, $AAAA, 480)
	End;

	Procedure OnAssign();
	Begin
		LeftStr := PadShootLeft.ToPrettyString();
		LeftHighlight := GetHighlightIdForBinding(@PadShootLeft);

		RightStr := PadShootRight.ToPrettyString();
		RightHighlight := GetHighlightIdForBinding(@PadShootRight);

		AssignToBind := NIL
	End;

	Procedure MaybeAssignAxis(Ev: PSDL_Event);
	Begin
		If(AssignToBind = NIL) then Exit;

		// Left thumbstick is hard-coded for movement
		If(Ev^.cAxis.Axis = SDL_CONTROLLER_AXIS_LEFTX) or (Ev^.cAxis.Axis = SDL_CONTROLLER_AXIS_LEFTY) then Exit;

		// Respect the dead zone setting when assigning
		If(Ev^.cAxis.Value > -Controllers.DeadZone.Value) and (Ev^.cAxis.Value < +Controllers.DeadZone.Value) then Exit;

		AssignToBind^.SetAxis(Ev^.cAxis.Axis, Ev^.cAxis.Value);
		OnAssign()
	End;

	Procedure MaybeAssignButton(Ev: PSDL_Event);
	Begin
		If(AssignToBind = NIL) then Exit;

		AssignToBind^.SetButton(Ev^.cButton.Button);
		OnAssign()
	End;

	Procedure UpdateControllerList();
	Var
		NameIdx: sInt;
	Begin
		GetControllerNames(ControllerCount, ControllerNames);

		If(ControllerCount > 0) then begin
			For NameIdx := 0 to (ControllerCount - 1) do
				ControllerNames[NameIdx] := UpCase(ControllerNames[NameIdx]);
			AssignTextColour := @MenuActiveColour
		end else begin
			AssignTextColour := @MenuInactiveColour;
			AssignToBind := NIL
		end
	End;

Const
	BLINK_PERIOD = 575;

	PAD_WIDTH = RESOL_W div 4;
	HORIZ_OFFSET = (RESOL_W * 7) div 40;

	PAD_X = (RESOL_W div 2) - HORIZ_OFFSET - (PAD_WIDTH div 2);
	SETTINGS_X = (RESOL_W div 2) + HORIZ_OFFSET;

	RumbleStr: Array[Boolean] of AnsiString = ('DISABLED', 'ENABLED');
Var
	Idx, YPos: uInt;
	DeadRect, RumbleRect, LeftRect, RightRect: TSDL_Rect;
	PadRect: TSDL_Rect;
Begin
	OnAssign();
	WriteStr(DeadZoneStr, Trunc(DeadZone.Percentage * 100), '%');
	UpdateControllerList();

	DeadRect.X := (RESOL_W div 4);
	DeadRect.W := (RESOL_W div 2);
	DeadRect.H := (Font^.CharH * 2) + ((3 * (Font^.CharH + Font^.SpacingY)) div 2);
	RumbleRect := DeadRect;
	LeftRect := DeadRect;
	RightRect := DeadRect;

	PadRect.X := PAD_X;
	PadRect.W := PAD_WIDTH;
	PadRect.H := (GamepadGfx^.H * GamepadGfx^.W) div PAD_WIDTH;

	SDL_SetTextureAlphaMod(GamepadButtonsGfx^.Tex, 127);
	SDL_SetTextureBlendMode(GamepadButtonsGfx^.Tex, SDL_BLENDMODE_BLEND);

	While True do begin
		Rendering.BeginFrame();
		DrawTitle();

		YPos := TitleGfx^.H;
		Font^.Scale := 2;
		PrintText('GAMEPAD SETTINGS',Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP, @WhiteColour);

		Font^.Scale := 1;
		YPos += (5 * (Font^.CharH + Font^.SpacingY)) div 2;
		DeadRect.Y := YPos;
		PrintText('D - DEAD ZONE', Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @MenuActiveColour);
		YPos += (3 * (Font^.CharH + Font^.SpacingY)) div 2;
		PrintText(DeadZoneStr, Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

		YPos += (4 * (Font^.CharH + Font^.SpacingY)) div 2;
		RumbleRect.Y := YPos;
		PrintText('V - VIBRATION', Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @MenuActiveColour);
		YPos += (3 * (Font^.CharH + Font^.SpacingY)) div 2;
		PrintText(RumbleStr[Controllers.RumbleEnabled], Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

		YPos += (4 * (Font^.CharH + Font^.SpacingY)) div 2;
		LeftRect.Y := YPos;
		PrintText('L - SHOOT LEFT', Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, AssignTextColour);
		YPos += (3 * (Font^.CharH + Font^.SpacingY)) div 2;
		If(AssignToBind = @PadShootLeft) then begin
			If(((GetTicks() div BLINK_PERIOD) mod 2) = 0) then
				PrintText('???', Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);
		end else
			PrintText(LeftStr, Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

		YPos += (4 * (Font^.CharH + Font^.SpacingY)) div 2;
		RightRect.Y := YPos;
		PrintText('R - SHOOT RIGHT', Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, AssignTextColour);
		YPos += (3 * (Font^.CharH + Font^.SpacingY)) div 2;
		If(AssignToBind = @PadShootRight) then begin
			If(((GetTicks() div BLINK_PERIOD) mod 2) = 0) then
				PrintText('???', Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);
		end else
			PrintText(RightStr, Font, SETTINGS_X, YPos, ALIGN_CENTRE, ALIGN_TOP, @WhiteColour);

		Font^.Scale := 2;
		YPos += (5 * (Font^.CharH + Font^.SpacingY)) div 2;
		PrintText('ACTIVE CONTROLLERS',Font,(RESOL_W div 2),YPos,ALIGN_CENTRE,ALIGN_TOP, @WhiteColour);

		Font^.Scale := 1;
		YPos += (5 * (Font^.CharH + Font^.SpacingY)) div 2;
		If(ControllerCount > 0) then begin
			For Idx := 0 to (ControllerCount - 1) do begin
				PrintText(ControllerNames[Idx], Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @GreyColour);
				YPos += (3 * (Font^.CharH + Font^.SpacingY)) div 2
			end
		end else begin
			PrintText('(NONE)', Font, (RESOL_W div 2), YPos, ALIGN_CENTRE, ALIGN_TOP, @GreyColour)
		end;

		PadRect.Y := ((DeadRect.Y + RightRect.Y + RightRect.H) div 2) - (PadRect.H div 2);
		SDL_RenderCopy(Renderer, GamepadGfx^.Tex, NIL, @PadRect);
		RenderHighlight(LeftHighlight, @PadRect, @LimeColour);
		RenderHighlight(RightHighlight, @PadRect, @LimeColour);

		Rendering.FinishFrame();

		AdvanceTime();
		UpdateMenuColours();

		While (SDL_PollEvent(@Ev)>0) do begin
			If (Ev.Type_ = SDL_QuitEv) then begin
				Shutdown:=True; Exit()
			end else
			If (Ev.Type_ = SDL_KeyDown) then begin
				If ((Ev.Key.Keysym.Sym = SDLK_Escape) or (Ev.Key.Keysym.Sym = SDLK_AC_BACK)) then begin
					If(AssignToBind <> NIL) then
						AssignToBind := NIL
					else
						Exit()
				end else
				If (Ev.Key.Keysym.Sym = SDLK_D) then begin
					ChangeDeadZone()
				end else
				If (Ev.Key.Keysym.Sym = SDLK_V) then begin
					ToggleRumble()
				end else
				If (Ev.Key.Keysym.Sym = SDLK_L) then begin
					If(ControllerCount > 0) then AssignToBind := @PadShootLeft
				end else
				If (Ev.Key.Keysym.Sym = SDLK_R) then begin
					If(ControllerCount > 0) then AssignToBind := @PadShootRight
				end else
			end else
			If (Ev.Type_ = SDL_MouseButtonDown) then begin
				{$IFDEF LD25_MOBILE} TranslateMouseEventCoords(@Ev); {$ENDIF}
				If(MouseInRect(DeadRect)) then begin
					ChangeDeadZone()
				end else
				If(MouseInRect(RumbleRect)) then begin
					ToggleRumble()
				end else
				If(MouseInRect(LeftRect)) then begin
					If(ControllerCount > 0) then AssignToBind := @PadShootLeft
				end else
				If(MouseInRect(RightRect)) then begin
					If(ControllerCount > 0) then AssignToBind := @PadShootRight
				end else
			end else
			If (Ev.Type_ = SDL_ControllerAxisMotion) then begin
				Controllers.SetLastUsedID(Ev.cAxis.Which);
				MaybeAssignAxis(@Ev)
			end else
			If (Ev.Type_ = SDL_ControllerButtonUp) then begin
				Controllers.SetLastUsedID(Ev.cButton.Which);
				MaybeAssignButton(@Ev)
			end else
			If (Ev.Type_ = SDL_ControllerDeviceAdded) or (Ev.Type_ = SDL_ControllerDeviceRemoved) then begin
				Controllers.HandleDeviceEvent(@Ev);
				UpdateControllerList();
			end else
			If (Ev.Type_ = SDL_JoyBatteryUpdated) then begin
				Controllers.HandleBatteryEvent(@Ev)
			end else
			{$IFDEF LD25_MOBILE}
			If (Ev.Type_ = SDL_FingerUp) or (Ev.Type_ = SDL_FingerDown) or (Ev.Type_ = SDL_FingerMotion) then begin
				TouchControls.HandleEvent(@Ev)
			end else
			{$ENDIF}
			If (Ev.Type_ = SDL_WindowEvent) and (Ev.Window.Event = SDL_WINDOWEVENT_RESIZED) then
				HandleWindowResizedEvent(@Ev)
		end;
	end;
End;

End.
